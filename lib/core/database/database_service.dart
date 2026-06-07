import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Servicio centralizado de SQLite para Nanutech Driver.
///
/// Esta BD local permite:
/// - Mantener sesión del chofer.
/// - Guardar la jornada actual en caché.
/// - Guardar eventos offline pendientes.
/// - Registrar logs de sincronización.
/// - Mantener el bloqueo local de SOS para HU21.
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
      version: 5,
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
    /// Tabla de sesión local.
    ///
    /// Permite que el chofer no tenga que iniciar sesión cada vez que abre la app.
    /// last_activity_at sirve para expirar sesión por inactividad.
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

    /// Migración segura por si la BD ya existía sin last_activity_at.
    try {
      await db.execute(
        'ALTER TABLE session_local ADD COLUMN last_activity_at TEXT',
      );
    } catch (_) {}

    /// Caché de jornada actual.
    ///
    /// Sirve para que la app pueda mostrar la jornada aunque no haya internet.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS jornada_cache (
        id TEXT PRIMARY KEY,
        data TEXT,
        updated_at TEXT
      )
    ''');

    /// Cola offline principal.
    ///
    /// Aquí se guardan acciones hechas sin internet:
    /// - START_JORNADA
    /// - END_JORNADA
    /// - SOS_ALERT
    /// - MECHANICAL_ASSISTANCE
    ///
    /// priority:
    /// - 0 = SOS, máxima prioridad.
    /// - 1 = Auxilio mecánico.
    /// - 2 = Jornada u otros eventos normales.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS offline_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_type TEXT NOT NULL,
        payload TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        priority INTEGER DEFAULT 2,
        retry_count INTEGER DEFAULT 0,
        last_error TEXT,
        created_at TEXT,
        synced_at TEXT
      )
    ''');

    /// Migración segura por si offline_events ya existía sin priority.
    try {
      await db.execute(
        'ALTER TABLE offline_events ADD COLUMN priority INTEGER DEFAULT 2',
      );
    } catch (_) {}

    /// Estado local de emergencia HU21.
    ///
    /// Sirve para que si el chofer envía SOS y cierra la app,
    /// al abrirla nuevamente siga bloqueada.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS emergency_state (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        sos_locked INTEGER DEFAULT 0,
        sos_event_id TEXT,
        sos_message TEXT,
        created_at TEXT
      )
    ''');

    /// Registros offline de combustible HU15.
    ///
    /// Guarda abastecimientos cuando no hay internet.
    /// La HU15 exige límite máximo de 10 registros offline pendientes.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS offline_fuel_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        payload TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        retry_count INTEGER DEFAULT 0,
        last_error TEXT,
        created_at TEXT,
        synced_at TEXT
      )
    ''');

    /// Logs simples de sincronización.
    ///
    /// Sirve para depurar qué eventos offline se sincronizaron o fallaron.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        message TEXT,
        created_at TEXT
      )
    ''');
  }
}