import '../../../../core/database/database_service.dart';
import '../domain/user_model.dart';

/// Servicio encargado de manejar la sesión local del conductor.
///
/// Funciones:
/// - Guardar sesión después del login.
/// - Recuperar sesión al abrir la app.
/// - Actualizar actividad.
/// - Expirar sesión tras 2 horas de inactividad.
/// - Cerrar sesión.
class SessionService {
  static const int inactivityLimitHours = 2;

  Future<void> saveSession(UserModel user) async {
    final db = await DatabaseService.database;
    final now = DateTime.now().toIso8601String();

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
        'created_at': now,
        'last_activity_at': now,
      },
    );
  }

  Future<Map<String, dynamic>?> getSession() async {
    final db = await DatabaseService.database;

    final result = await db.query('session_local');

    if (result.isEmpty) return null;

    return result.first;
  }

  Future<void> updateLastActivity() async {
    final db = await DatabaseService.database;

    await db.update(
      'session_local',
      {
        'last_activity_at': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<bool> isSessionExpired() async {
    final session = await getSession();

    if (session == null) return true;

    final lastActivityRaw =
        session['last_activity_at'] ?? session['created_at'];

    if (lastActivityRaw == null) return true;

    final lastActivity = DateTime.tryParse(
      lastActivityRaw.toString(),
    );

    if (lastActivity == null) return true;

    final difference = DateTime.now().difference(lastActivity);

    return difference.inHours >= inactivityLimitHours;
  }

  Future<void> logout() async {
    final db = await DatabaseService.database;

    await db.delete('session_local');
  }
}