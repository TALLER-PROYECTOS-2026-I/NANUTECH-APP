import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../models/jornada_historial_model.dart';
import '../models/metricas_historial_model.dart';

class HistorialJornadasRepository {
  Future<List<JornadaHistorialModel>> getHistorial({
    required String token,
    required String periodo,
    required String observaciones,
  }) async {
    try {
      final response = await ApiClient.dio.get(
        '/jornadas/historial',
        queryParameters: {
          'periodo': periodo,
          'observaciones': observaciones,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final List<dynamic> data = response.data['data'] ?? [];
      return data.map((json) => JornadaHistorialModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'No se pudo obtener el historial',
      );
    }
  }

  Future<MetricasHistorialModel> getMetricas({
    required String token,
    required String periodo,
  }) async {
    try {
      final response = await ApiClient.dio.get(
        '/jornadas/metricas',
        queryParameters: {
          'periodo': periodo,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final data = response.data['data'];
      return MetricasHistorialModel.fromJson(data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'No se pudieron obtener las métricas',
      );
    }
  }
}