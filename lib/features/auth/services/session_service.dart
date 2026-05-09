import '../../../core/database/database_service.dart';
import '../models/user_model.dart';

class SessionService {
  Future<void> saveSession(UserModel user) async {
    final db = await DatabaseService.database;

    await db.delete('session_local');

    await db.insert(
      'session_local',
      {
        'user_id': user.userId,
        'conductor_id': user.conductorId,
        'email': user.email,
        'nombres': user.nombres,
        'apellidos': user.apellidos,
        'role': user.role,
        'token': user.token,
        'created_at': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<Map<String, dynamic>?> getSession() async {
    final db = await DatabaseService.database;

    final result = await db.query('session_local');

    if (result.isEmpty) return null;

    return result.first;
  }

  Future<void> logout() async {
    final db = await DatabaseService.database;

    await db.delete('session_local');
  }
}