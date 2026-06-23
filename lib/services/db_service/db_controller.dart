import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/services/db_service/db_service.dart';
import 'package:pure_live/core/sites/iptv/local/database.dart' as database;

final dbServiceProvider = Provider<DbService>((ref) {
  final db = database.AppDatabase();
  return DbService(db);
});
