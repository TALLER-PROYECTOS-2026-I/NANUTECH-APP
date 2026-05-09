import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../models/user_model.dart';

class AuthService {
  Future<UserModel> login(
    String email,
    String password,
  ) async {
    try {
      final response = await ApiClient.dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      return UserModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Error en login',
      );
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await ApiClient.dio.post(
        '/auth/forgot-password',
        data: {
          'email': email,
        },
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ??
            'No se pudo enviar el código de recuperación.',
      );
    }
  }

  Future<void> confirmForgotPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      await ApiClient.dio.post(
        '/auth/forgot-password/confirm',
        data: {
          'email': email,
          'code': code,
          'newPassword': newPassword,
        },
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ??
            'No se pudo restablecer la contraseña.',
      );
    }
  }
}