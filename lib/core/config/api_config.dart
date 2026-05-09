class ApiConfig {
  // CAMBIA POR TU URL REAL

  // LOCAL
  // static const String baseUrl = 'http://192.168.100.181:3000';

  // AWS
  static const String baseUrl =
      'https://q26dwk17da.execute-api.us-east-1.amazonaws.com/Stage';

  static const Duration timeout = Duration(seconds: 30);
}