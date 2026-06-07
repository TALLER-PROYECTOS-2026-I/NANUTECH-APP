import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../domain/historial_jornada_model.dart';

/// Servicio que consume los endpoints HU04:
/// - GET /jornadas/historial
/// - GET /jornadas/metricas
class HistorialJornadaService {
  /// Obtiene el listado de jornadas completadas.
  ///
  /// [token] Token JWT del conductor (conductor_id extraído automáticamente).
  /// [periodo] Filtro de período: 'semana' | 'mes' | null (todas).
  /// [observaciones] Filtro: 'con' | 'sin' | null (todas).
  Future<List<HistorialJornadaModel>> getHistorial({
    required String token,
    String? periodo,
    String? observaciones,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (periodo != null) queryParams['periodo'] = periodo;
      if (observaciones != null) queryParams['observaciones'] = observaciones;

      final response = await ApiClient.dio.get(
        '/jornadas/historial',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      final data = response.data['data'];
      if (data == null || data is! List) return [];

      return data
          .map((e) => HistorialJornadaModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Error al obtener historial';
      throw Exception(msg);
    }
  }

  /// Obtiene las métricas del conductor.
  ///
  /// [token] Token JWT del conductor.
  /// [periodo] Filtro de período: 'semana' | 'mes' | null (todas).
  Future<HistorialMetricasModel> getMetricas({
    required String token,
    String? periodo,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (periodo != null) queryParams['periodo'] = periodo;

      final response = await ApiClient.dio.get(
        '/jornadas/metricas',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      final data = response.data['data'];
      if (data == null) return HistorialMetricasModel.empty();

      return HistorialMetricasModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Error al obtener métricas';
      throw Exception(msg);
    }
  }
}
