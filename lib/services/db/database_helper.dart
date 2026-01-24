import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const String _dbName = 'med_cabinet_v2.db';
  static const int _dbVersion = 2;

  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
            CREATE TABLE medicines (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              expiryDate TEXT NOT NULL,
              quantity INTEGER NOT NULL,
              location TEXT NOT NULL,
              notes TEXT,
              createdAt TEXT NOT NULL,
              
              dailyReminderEnabled INTEGER NOT NULL DEFAULT 0,
              dailyReminderHour INTEGER,
              dailyReminderMinute INTEGER
            )
          ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE medicines ADD COLUMN dailyReminderEnabled INTEGER NOT NULL DEFAULT 0',
          );
          await db.execute(
            'ALTER TABLE medicines ADD COLUMN dailyReminderHour INTEGER',
          );
          await db.execute(
            'ALTER TABLE medicines ADD COLUMN dailyReminderMinute INTEGER',
          );
        }
      },
    );
  }
}
