import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../domain/jornada_model.dart';

class JornadaApiService {
  Future<JornadaModel?> getJornadaActual({
    required String conductorId,
    required String token,
  }) async {
    try {
      final response = await ApiClient.dio.get(
        '/jornadas/actual/$conductorId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final data = response.data['data'];

      if (data == null) return null;

      return JornadaModel.fromJson(data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ??
            'No se pudo obtener la jornada actual',
      );
    }
  }

  Future<JornadaModel> iniciarJornada({
    required String jornadaId,
    required String conductorId,
    required String token,
  }) async {
    final response = await ApiClient.dio.post(
      '/jornadas/iniciar',
      data: {
        'jornada_id': jornadaId,
        'conductor_id': conductorId,
        'event_id_cliente': DateTime.now().millisecondsSinceEpoch.toString(),
        'timestamp_local': DateTime.now().toIso8601String(),
        'created_offline': false,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    return JornadaModel.fromJson(response.data['data']);
  }

  Future<JornadaModel> finalizarJornada({
    required String jornadaId,
    required String conductorId,
    required String token,
    String? observaciones,
  }) async {
    final response = await ApiClient.dio.post(
      '/jornadas/finalizar',
      data: {
        'jornada_id': jornadaId,
        'conductor_id': conductorId,
        'event_id_cliente': DateTime.now().millisecondsSinceEpoch.toString(),
        'timestamp_local': DateTime.now().toIso8601String(),
        'observaciones': observaciones ?? '',
        'created_offline': false,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    return JornadaModel.fromJson(response.data['data']);
  }
}