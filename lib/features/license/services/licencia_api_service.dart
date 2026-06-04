import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../domain/licencia_model.dart';

class LicenciaApiService {
  Future<LicenciaModel> obtenerLicencia({required String token}) async {
    try {
      final response = await ApiClient.dio.get(
        '/conductores/licencia',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final data = response.data['data'];

      return LicenciaModel.fromJson(data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'No se pudo obtener la licencia',
      );
    }
  }

  Future<void> actualizarLicencia({
    required String token,
    required String numeroLicencia,
    required String categoria,
    required String fechaEmision,
    required String fechaVencimiento,
    required String autoridadEmisora,
  }) async {
    try {
      await ApiClient.dio.put(
        '/conductores/licencia',
        data: {
          'numeroLicencia': numeroLicencia,
          'categoria': categoria,
          'fechaEmision': fechaEmision,
          'fechaVencimiento': fechaVencimiento,
          'autoridadEmisora': autoridadEmisora,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'No se pudo actualizar la licencia',
      );
    }
  }
}
