import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class OfflineSyncManager {
  static final OfflineSyncManager instance = OfflineSyncManager._init();
  static Database? _database;
  final ApiService _apiService = ApiService();

  OfflineSyncManager._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('contacts.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        local_id INTEGER PRIMARY KEY AUTOINCREMENT,
        id TEXT,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        avatar TEXT,
        sync_status TEXT NOT NULL
      )
    ''');
  }

  Future<bool> isOnline() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    return !connectivityResult.contains(ConnectivityResult.none);
  }

  Future<List<User>> getContacts() async {
    final db = await instance.database;

    if (await isOnline()) {
      await uploadPendingChangesToCloud();

      List<User> cloudUsers = await _apiService.getUsers();

      if (cloudUsers.isNotEmpty) {
        await db.delete('users', where: "sync_status = 'SYNCED'");

        for (var user in cloudUsers) {
          await db.insert('users', {
            'id': user.id,
            'name': user.name,
            'email': user.email,
            'avatar': user.avatar,
            'sync_status': 'SYNCED'
          });
        }
      }
    }

    final result = await db.query('users', where: "sync_status != 'PENDING_DELETE'");
    return result.map((json) => User.fromJson(json)).toList();
  }


  Future<void> saveContact(User user) async {
    final db = await instance.database;

    if (await isOnline()) {
      bool success = await _apiService.createUser(user);
      if (success) {
        await db.insert('users', {
          'id': user.id,
          'name': user.name,
          'email': user.email,
          'avatar': user.avatar,
          'sync_status': 'SYNCED'
        });
        return;
      }
    }

    await db.insert('users', {
      'id': user.id,
      'name': user.name,
      'email': user.email,
      'avatar': user.avatar,
      'sync_status': 'PENDING_INSERT'
    });
  }


  Future<void> updateContact(User user) async {
    final db = await instance.database;

    String status = (user.id == null || user.id!.isEmpty) ? 'PENDING_INSERT' : 'PENDING_UPDATE';

    if (await isOnline() && status == 'PENDING_UPDATE') {
      bool success = await _apiService.updateUser(user);
      if (success) {
        status = 'SYNCED';
      }
    }

    await db.update(
      'users',
      {
        'id': user.id,
        'name': user.name,
        'email': user.email,
        'avatar': user.avatar,
        'sync_status': status
      },
      where: 'local_id = ?',
      whereArgs: [user.localId],
    );
  }


  Future<void> deleteContact(User user) async {
    final db = await instance.database;

    // Agar contact offline bana tha aur abhi tak cloud par gya hi nahi, to direct phone se uda dein
    if (user.id == null || user.id!.isEmpty) {
      await db.delete('users', where: 'local_id = ?', whereArgs: [user.localId]);
      return;
    }

    if (await isOnline()) {
      bool success = await _apiService.deleteUser(user.id!);
      if (success) {
        await db.delete('users', where: 'local_id = ?', whereArgs: [user.localId]);
        return;
      }
    }

    await db.update(
      'users',
      {'sync_status': 'PENDING_DELETE'},
      where: 'local_id = ?',
      whereArgs: [user.localId],
    );
  }


  Future<void> uploadPendingChangesToCloud() async {
    if (!(await isOnline())) return; // Unstable connection guard clause
    final db = await instance.database;

    final List<Map<String, dynamic>> pendingRows = await db.query(
        'users',
        where: "sync_status != 'SYNCED'"
    );

    for (var row in pendingRows) {
      User user = User.fromJson(row);
      String status = row['sync_status'];

      if (status == 'PENDING_INSERT') {
        bool success = await _apiService.createUser(user);
        if (success) {
          await db.update('users', {'sync_status': 'SYNCED'}, where: 'local_id = ?', whereArgs: [user.localId]);
        }
      }
      else if (status == 'PENDING_UPDATE') {
        bool success = await _apiService.updateUser(user);
        if (success) {
          await db.update('users', {'sync_status': 'SYNCED'}, where: 'local_id = ?', whereArgs: [user.localId]);
        }
      }
      else if (status == 'PENDING_DELETE') {
        bool success = await _apiService.deleteUser(user.id!);
        if (success) {
          await db.delete('users', where: 'local_id = ?', whereArgs: [user.localId]);
        }
      }
    }
  }
}
