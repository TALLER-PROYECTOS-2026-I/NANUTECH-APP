import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();

    final path = join(dbPath, 'nanutech_driver.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(
    Database db,
    int version,
  ) async {

    // SESIÓN

    await db.execute('''
      CREATE TABLE session_local (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT,
        conductor_id TEXT,
        email TEXT,
        nombres TEXT,
        apellidos TEXT,
        rol TEXT,
        token TEXT,
        created_at TEXT
      )
    ''');

    // JORNADA

    await db.execute('''
      CREATE TABLE jornadas_local (
        id TEXT PRIMARY KEY,
        conductor_id TEXT,
        origen TEXT,
        destino TEXT,
        estado TEXT,
        hora_inicio TEXT,
        hora_fin TEXT,
        observaciones TEXT,
        updated_at TEXT
      )
    ''');

    // COLA SYNC

    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_id TEXT,
        action TEXT,
        payload TEXT,
        status TEXT,
        retry_count INTEGER,
        created_at TEXT
      )
    ''');
  }
}