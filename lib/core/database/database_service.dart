import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Servicio centralizado de SQLite para la app móvil.
///
/// Responsabilidades:
/// - Crear la base de datos local.
/// - Crear tablas para sesión, jornada cacheada, eventos offline y logs.
/// - Aplicar migraciones simples cuando ya existe una BD previa.
class DatabaseService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final path = join(
      await getDatabasesPath(),
      'nanutech_driver.db',
    );

    return openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _createTables(db);
      },
      onOpen: (db) async {
        await _createTables(db);
      },
    );
  }

  static Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS session_local (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT,
        conductor_id TEXT,
        email TEXT,
        nombres TEXT,
        apellidos TEXT,
        role TEXT,
        token TEXT,
        created_at TEXT,
        last_activity_at TEXT
      )
    ''');

    try {
      await db.execute(
        'ALTER TABLE session_local ADD COLUMN last_activity_at TEXT',
      );
    } catch (_) {}

    await db.execute('''
      CREATE TABLE IF NOT EXISTS jornada_cache (
        id TEXT PRIMARY KEY,
        data TEXT,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS offline_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_type TEXT NOT NULL,
        payload TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        retry_count INTEGER DEFAULT 0,
        last_error TEXT,
        created_at TEXT,
        synced_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        message TEXT,
        created_at TEXT
      )
    ''');
  }
}