import 'package:flutter/material.dart';

import '../../services/session_service.dart';
import 'login_screen.dart';
import '../../../driver_shift/presentation/screens/driver_dashboard_screen.dart';

/// Pantalla inicial de la app.
///
/// Decide si:
/// - El usuario debe iniciar sesión.
/// - Existe una sesión local vigente.
/// - La sesión expiró por 2 horas de inactividad.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    checkSession();
  }

  Future<void> checkSession() async {
    final sessionService = SessionService();
    final session = await sessionService.getSession();

    if (!mounted) return;

    if (session == null ||
        session['token'] == null ||
        session['token'].toString().isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );
      return;
    }

    final expired = await sessionService.isSessionExpired();

    if (expired) {
      await sessionService.logout();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );
      return;
    }

    await sessionService.updateLastActivity();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DriverDashboardScreen(
          conductorId: session['conductor_id'].toString(),
          token: session['token'].toString(),
          nombres: session['nombres'].toString(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xff1e3a8a),
      body: Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      ),
    );
  }
}