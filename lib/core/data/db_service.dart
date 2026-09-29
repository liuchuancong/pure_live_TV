import 'package:pure_live/modules/live/iptv/data/database.dart' as database;

class DbService {
  DbService._internal();
  static final DbService to = DbService._internal();

  late final database.AppDatabase db = database.AppDatabase();
}
