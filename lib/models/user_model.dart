class User {
  final String? id;
  final String? localId;
  final String name;
  final String email;
  final String? avatar;
  final String syncStatus;

  User({
    this.id,
    this.localId,
    required this.name,
    required this.email,
    this.avatar,
    this.syncStatus = 'SYNCED',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] != null ? json['id'].toString() : null,
      localId: json['local_id'] != null ? json['local_id'].toString() : null,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      avatar: json['avatar'],
      syncStatus: json['sync_status'] ?? 'SYNCED',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null && id!.isNotEmpty) 'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
    };
  }

  Map<String, dynamic> toLocalMap() {
    return {
      if (localId != null) 'local_id': localId,
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'sync_status': syncStatus,
    };
  }
}
