import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';

class DriverHistoryApiService {
  Future<Map<String, dynamic>> getMetrics({
    required String token,
  }) async {
    final response = await ApiClient.dio.get(
      '/jornadas/metricas',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    return response.data;
  }

  Future<Map<String, dynamic>> getHistory({
    required String token,
  }) async {
    final response = await ApiClient.dio.get(
      '/jornadas/historial',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    return response.data;
  }
}