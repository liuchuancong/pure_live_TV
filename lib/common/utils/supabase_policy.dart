class SupabasePolicy {
  final String supabaseUrl;
  final String supabaseKey;
  final String id;
  final String userId;
  final String uid;
  final String config;
  final String email;
  final String updateAt;
  final String version;
  final String createdAt;
  final String tableName;
  final String checkTable;
  final String owner;
  SupabasePolicy(
      {required this.supabaseUrl,
      required this.supabaseKey,
      required this.id,
      required this.userId,
      required this.uid,
      required this.config,
      required this.email,
      required this.updateAt,
      required this.version,
      required this.createdAt,
      required this.tableName,
      required this.checkTable,
      required this.owner});

  factory SupabasePolicy.fromJson(Map<dynamic, dynamic> json) {
    return SupabasePolicy(
        supabaseUrl: json['supabaseUrl'],
        supabaseKey: json['supabaseKey'],
        id: json['id'],
        userId: json['user_id'],
        uid: json['uid'],
        config: json['config'],
        email: json['email'],
        updateAt: json['update_at'],
        version: json['version'],
        createdAt: json['created_at'],
        tableName: json['table_name'],
        checkTable: json['check_table'],
        owner: json['owner']);
  }
}
