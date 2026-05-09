import 'package:dio/dio.dart';
import '../config/api_config.dart';

class ApiClient {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.timeout,
      receiveTimeout: ApiConfig.timeout,
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );
}