import 'package:dio/dio.dart';
import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/database/database_service.dart';
class FuelApiService {
  Future<Map<String, dynamic>> getLastMileage({
    required String token,
    required String unidadId,
  }) async {
    final response = await ApiClient.dio.get(
      '/combustible/ultimo-km/$unidadId',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    return response.data;
  }

  Future<Map<String, dynamic>> registerFuel({
    required String token,
    required String jornadaId,
    required String conductorId,
    required double galones,
    required double costoTotal,
    required double kilometrajeActual,
    required String fotoComprobanteUrl,
    double? latitud,
    double? longitud,
    bool createdOffline = false,
  }) async {
    final data = {
      'jornada_id': jornadaId,
      'conductor_id': conductorId,
      'galones': galones,
      'costo_total': costoTotal,
      'kilometraje_actual': kilometrajeActual,
      'foto_comprobante_url': fotoComprobanteUrl,
      'latitud': latitud,
      'longitud': longitud,
      'created_offline': createdOffline,
      'timestamp_local': DateTime.now().toIso8601String(),
    };

    final response = await ApiClient.dio.post(
      '/combustible',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
      data: data,
    );

    return response.data;
  }

  Future<int> countPendingOfflineFuelRecords() async {
  final db = await DatabaseService.database;

  final result = await db.rawQuery('''
    SELECT COUNT(*) AS total
    FROM offline_fuel_records
    WHERE synced = 0
  ''');

  final total = result.first['total'];

  if (total is int) return total;

  return int.tryParse(total.toString()) ?? 0;
}
Future<void> saveOfflineFuelRecord({
  required Map<String, dynamic> payload,
}) async {
  final pending = await countPendingOfflineFuelRecords();

  if (pending >= 10) {
    throw Exception(
      'Límite de registros offline alcanzado. Sincronice con la red para continuar',
    );
  }

  final db = await DatabaseService.database;

  await db.insert(
    'offline_fuel_records',
    {
      'payload': jsonEncode(payload),
      'synced': 0,
      'retry_count': 0,
      'created_at': DateTime.now().toIso8601String(),
    },
  );
}
}