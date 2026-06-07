import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';

class LicenseApiService {
  Future<Map<String, dynamic>> getLicense({
    required String token,
    required String conductorId,
  }) async {
    final response = await ApiClient.dio.get(
      '/conductores/licencia',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    return response.data;
  }

  Future<Map<String, dynamic>> updateLicense({
    required String token,
    required String conductorId,
    required String numeroLicencia,
    required String categoria,
    required String fechaEmision,
    required String fechaVencimiento,
    required String autoridadEmisora,
  }) async {
    final response = await ApiClient.dio.put(
      '/conductores/licencia',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
      data: {
        'conductorId': conductorId,
        'numeroLicencia': numeroLicencia,
        'categoria': categoria,
        'fechaEmision': fechaEmision,
        'fechaVencimiento': fechaVencimiento,
        'autoridadEmisora': autoridadEmisora,
      },
    );

    return response.data;
  }
}