import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';

class EmergencyAlertApiService {
  Future<Map<String, dynamic>> sendSos({
    required String token,
    required String jornadaId,
    required String conductorId,
    required double latitud,
    required double longitud,
    required String eventIdCliente,
  }) async {
    final data = {
      'jornada_id': jornadaId,
      'conductor_id': conductorId,
      'latitud': latitud,
      'longitud': longitud,
      'timestamp_local': DateTime.now().toIso8601String(),
      'created_offline': false,
      'event_id_cliente': eventIdCliente,
    };

    try {
      print('=========== SOS PAYLOAD ===========');
      print(data);
      print('TOKEN VACIO: ${token.isEmpty}');
      print('===================================');

      final response = await ApiClient.dio.post(
        '/alertas/sos',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
        data: data,
      );

      print('=========== SOS RESPONSE ===========');
      print(response.data);
      print('====================================');

      return response.data;
    } on DioException catch (e) {
      print('=========== SOS ERROR ===========');
      print('STATUS: ${e.response?.statusCode}');
      print('DATA: ${e.response?.data}');
      print('MESSAGE: ${e.message}');
      print('=================================');

      throw Exception(
        e.response?.data?['message'] ??
            'Error al registrar alerta SOS.',
      );
    }
  }

  Future<Map<String, dynamic>> sendMechanicalAssistance({
    required String token,
    required String jornadaId,
    required String conductorId,
    required String tipoFalla,
    required String detalle,
    required double latitud,
    required double longitud,
    required String eventIdCliente,
  }) async {
    final data = {
      'jornada_id': jornadaId,
      'conductor_id': conductorId,
      'tipo_falla_mecanica': tipoFalla,
      'detalle': detalle,
      'latitud': latitud,
      'longitud': longitud,
      'timestamp_local': DateTime.now().toIso8601String(),
      'created_offline': false,
      'event_id_cliente': eventIdCliente,
    };

    try {
      print('=========== AUXILIO PAYLOAD ===========');
      print(data);
      print('TOKEN VACIO: ${token.isEmpty}');
      print('=======================================');

      final response = await ApiClient.dio.post(
        '/alertas/auxilio',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
        data: data,
      );

      print('=========== AUXILIO RESPONSE ===========');
      print(response.data);
      print('========================================');

      return response.data;
    } on DioException catch (e) {
      print('=========== AUXILIO ERROR ===========');
      print('STATUS: ${e.response?.statusCode}');
      print('DATA: ${e.response?.data}');
      print('MESSAGE: ${e.message}');
      print('=====================================');

      throw Exception(
        e.response?.data?['message'] ??
            'Error al solicitar auxilio mecánico.',
      );
    }
  }

  Future<bool> hasActiveSos({
  required String token,
  required String jornadaId,
}) async {
  final response = await ApiClient.dio.get(
    '/alertas/activas',
    options: Options(
      headers: {
        'Authorization': 'Bearer $token',
      },
    ),
    queryParameters: {
      'tipo': 'PANICO',
      'estado': 'ACTIVA',
    },
  );

  final data = response.data['data'];

  if (data is! List) return false;

  return data.any((alerta) {
    return alerta['jornada_id'] == jornadaId &&
        alerta['tipo'] == 'PANICO' &&
        alerta['estado'] == 'ACTIVA';
  });
}
}