class UserModel {
  final String userId;
  final String conductorId;
  final String email;
  final String nombres;
  final String apellidos;
  final String role;
  final String token;

  UserModel({
    required this.userId,
    required this.conductorId,
    required this.email,
    required this.nombres,
    required this.apellidos,
    required this.role,
    required this.token,
  });

  bool get isChofer => role.toLowerCase() == 'chofer';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] ?? {};
    final session = json['session'] ?? {};

    return UserModel(
      userId: (user['id'] ?? '').toString(),
      conductorId: (user['id'] ?? '').toString(),
      email: (user['email'] ?? '').toString(),
      nombres: (user['nombres'] ?? '').toString(),
      apellidos: (user['apellidos'] ?? '').toString(),
      role: (user['role'] ?? json['role'] ?? '').toString(),
      token: (session['accessToken'] ?? '').toString(),
    );
  }
}