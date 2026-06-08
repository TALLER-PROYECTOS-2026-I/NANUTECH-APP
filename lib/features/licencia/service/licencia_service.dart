import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

/// Servicio para manejar las operaciones de licencia
class LicenciaService {
  /// Actualiza la licencia del conductor
  /// Envía: categoria y fechaVencimiento
  /// Endpoint: PUT /conductores/licencia
  Future<void> actualizarLicencia({
    required String categoria,
    required String fechaVencimiento,
  }) async {
    try {
      await ApiClient.dio.put(
        '/conductores/licencia',
        data: {
          'categoria': categoria,
          'fechaVencimiento': fechaVencimiento,
        },
      );
    } on DioException catch (e) {
      final mensajeError = e.response?.data['message'] ?? 'Error al actualizar licencia';
      throw Exception(mensajeError);
    }
  }
}
