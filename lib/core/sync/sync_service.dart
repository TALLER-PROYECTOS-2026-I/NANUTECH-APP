import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../database/database_service.dart';

class SyncService {

  Future<void> saveOfflineEvent({
    required String eventType,
    required Map<String, dynamic> payload,
  }) async {

    final db = await DatabaseService.database;

    await db.insert(
      'offline_events',
      {
        'event_type': eventType,
        'payload': jsonEncode(payload),
        'synced': 0,
        'created_at': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<List<Map<String, dynamic>>> getPendingEvents() async {

    final db = await DatabaseService.database;

    return await db.query(
      'offline_events',
      where: 'synced = ?',
      whereArgs: [0],
    );
  }

  Future<void> markAsSynced(int id) async {

    final db = await DatabaseService.database;

    await db.update(
      'offline_events',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

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