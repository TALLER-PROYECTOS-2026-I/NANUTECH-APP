import 'dart:convert';

import '../database/database_service.dart';

/// Servicio de sincronización offline-first.
///
/// Esta clase administra la cola local `offline_events`.
/// Sirve para guardar acciones cuando no hay internet y enviarlas
/// automáticamente cuando la conexión regresa.
///
/// Eventos usados:
/// - START_JORNADA
/// - END_JORNADA
/// - SOS_ALERT
/// - MECHANICAL_ASSISTANCE
class SyncService {
  /// Guarda un evento pendiente de sincronización.
  ///
  /// priority:
  /// - 0 = SOS, máxima prioridad por HU21.
  /// - 1 = Auxilio Mecánico.
  /// - 2 = Eventos normales de jornada.
  Future<void> saveOfflineEvent({
    required String eventType,
    required Map<String, dynamic> payload,
    int priority = 2,
  }) async {
    final db = await DatabaseService.database;

    await db.insert(
      'offline_events',
      {
        'event_type': eventType,
        'payload': jsonEncode(payload),
        'synced': 0,
        'priority': priority,
        'retry_count': 0,
        'created_at': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Obtiene eventos pendientes ordenados por prioridad.
  ///
  /// HU21 exige que SOS se sincronice primero si fue generado offline.
  Future<List<Map<String, dynamic>>> getPendingEvents() async {
    final db = await DatabaseService.database;

    return db.query(
      'offline_events',
      where: 'synced = ?',
      whereArgs: [0],
      orderBy: 'priority ASC, created_at ASC',
    );
  }

  /// Marca un evento como sincronizado.
  Future<void> markAsSynced(int id) async {
    final db = await DatabaseService.database;

    await db.update(
      'offline_events',
      {
        'synced': 1,
        'synced_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Guarda logs simples para depurar sincronización.
  Future<void> addLog(String message) async {
    final db = await DatabaseService.database;

    await db.insert(
      'sync_logs',
      {
        'message': message,
        'created_at': DateTime.now().toIso8601String(),
      },
    );
  }
}