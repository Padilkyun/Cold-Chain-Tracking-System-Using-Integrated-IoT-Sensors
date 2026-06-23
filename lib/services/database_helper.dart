import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'capsi_box_v3.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sensor_data (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        suhu REAL,
        kelembaban REAL,
        tvoc INTEGER,
        eco2 INTEGER,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        body TEXT,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE actions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS notifications (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT,
          body TEXT,
          timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS actions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT,
          timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
        )
      ''');
    }
  }

  Future<void> insertNotification(String title, String body) async {
    final db = await database;
    await db.insert('notifications', {
      'title': title,
      'body': body,
    });
  }

  Future<List<Map<String, dynamic>>> getNotifications() async {
    final db = await database;
    return await db.query('notifications', orderBy: 'timestamp DESC');
  }

  Future<void> insertAction(String title) async {
    final db = await database;
    await db.insert('actions', {
      'title': title,
    });
  }

  Future<List<Map<String, dynamic>>> getRecentActions({int limit = 10}) async {
    final db = await database;
    return await db.query('actions', orderBy: 'timestamp DESC', limit: limit);
  }

  Future<void> insertData(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('sensor_data', {
      'suhu': data['suhu'],
      'kelembaban': data['kelembaban'],
      'tvoc': data['tvoc'],
      'eco2': data['eco2'],
    });
  }

  Future<List<Map<String, dynamic>>> getHistory(String filter) async {
    final db = await database;
    String timeFilter = '';
    
    switch (filter) {
      case '1h':
        timeFilter = "timestamp >= datetime('now', '-1 hour')";
        break;
      case '6h':
        timeFilter = "timestamp >= datetime('now', '-6 hours')";
        break;
      case '12h':
        timeFilter = "timestamp >= datetime('now', '-12 hours')";
        break;
      case '24h':
        timeFilter = "timestamp >= datetime('now', '-24 hours')";
        break;
      default:
        timeFilter = "timestamp >= datetime('now', '-12 hours')";
    }

    return await db.query(
      'sensor_data',
      where: timeFilter,
      orderBy: 'timestamp ASC',
    );
  }

  Future<void> clearOldData() async {
    final db = await database;
    // Keep only last 7 days of data
    await db.delete(
      'sensor_data',
      where: "timestamp < datetime('now', '-7 days')",
    );
  }
}
