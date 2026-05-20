import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/session_service.dart';
import '../../../driver_shift/presentation/screens/driver_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  bool obscurePassword = true;

  int failedAttempts = 0;
  DateTime? blockedUntil;

  bool get isBlocked {
    if (blockedUntil == null) return false;
    return DateTime.now().isBefore(blockedUntil!);
  }

  int get remainingAttempts {
    final remaining = 5 - failedAttempts;
    return remaining < 0 ? 0 : remaining;
  }

  bool isValidEmail(String email) {
    final regex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
    return regex.hasMatch(email);
  }

  void showTopMessage(
    String message, {
    bool success = false,
  }) {
    final overlay = Overlay.of(context);

    final entry = OverlayEntry(
      builder: (_) => Positioned(
        top: 50,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: success ? Colors.green.shade700 : Colors.red.shade700,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  success ? Icons.check_circle : Icons.error,
                  color: Colors.white,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);

    Future.delayed(const Duration(seconds: 3), () {
      entry.remove();
    });
  }

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (isBlocked) {
      final seconds = blockedUntil!.difference(DateTime.now()).inSeconds;

      showTopMessage(
        '¡Cuenta Bloqueada! Espera $seconds segundos por seguridad.',
      );
      return;
    }

    if (email.isEmpty || password.isEmpty) {
      showTopMessage('Ingresa correo y contraseña.');
      return;
    }

    if (!isValidEmail(email)) {
      showTopMessage('El correo no tiene un formato válido.');
      return;
    }

    try {
      setState(() {
        loading = true;
      });

      final authService = AuthService();

      final user = await authService.login(
        email,
        password,
      );

      if (!user.isChofer) {
        showTopMessage(
          'Acceso denegado. Esta app es solo para choferes.',
        );
        return;
      }

      failedAttempts = 0;
      blockedUntil = null;

      final sessionService = SessionService();
      await sessionService.saveSession(user);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DriverDashboardScreen(
            conductorId: user.conductorId,
            token: user.token,
            nombres: user.nombres,
          ),
        ),
      );
    } catch (_) {
      failedAttempts++;

      if (failedAttempts >= 5) {
        blockedUntil = DateTime.now().add(
          const Duration(minutes: 5),
        );

        showTopMessage(
          '¡Cuenta Bloqueada! Espera 5 minutos por seguridad.',
        );
      } else {
        showTopMessage(
          'Credenciales incorrectas. Intentos restantes: $remainingAttempts',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

Future<void> showForgotPasswordDialog() async {
  final emailRecoveryController = TextEditingController(
    text: emailController.text.trim(),
  );

  final result = await showDialog<String>(
    context: context,
    builder: (_) {
      String? localError;

      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Recuperar contraseña'),
            content: TextField(
              controller: emailRecoveryController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Correo registrado',
                prefixIcon: const Icon(Icons.email),
                errorText: localError,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  final email = emailRecoveryController.text.trim();

                  if (email.isEmpty) {
                    setDialogState(() {
                      localError = 'Ingresa tu correo registrado.';
                    });
                    return;
                  }

                  if (!isValidEmail(email)) {
                    setDialogState(() {
                      localError = 'Correo inválido.';
                    });
                    return;
                  }

                  Navigator.pop(context, email);
                },
                child: const Text('Enviar código'),
              ),
            ],
          );
        },
      );
    },
  );

  if (result == null) return;

  try {
    final authService = AuthService();

    await authService.forgotPassword(result);

    showTopMessage(
      'Código enviado al correo registrado.',
      success: true,
    );

    await showConfirmPasswordDialog(result);
  } catch (e) {
    showTopMessage(e.toString());
  }
}

Future<void> showConfirmPasswordDialog(String email) async {
  final codeController = TextEditingController();
  final newPasswordController = TextEditingController();

  bool obscureNewPassword = true;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Nueva contraseña'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(
                    labelText: 'Código de verificación',
                    prefixIcon: Icon(Icons.verified),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: newPasswordController,
                  obscureText: obscureNewPassword,
                  decoration: InputDecoration(
                    labelText: 'Nueva contraseña',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNewPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          obscureNewPassword = !obscureNewPassword;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Restablecer'),
              ),
            ],
          );
        },
      );
    },
  );

  if (confirmed != true) return;

  if (codeController.text.trim().isEmpty ||
      newPasswordController.text.trim().isEmpty) {
    showTopMessage('Ingresa el código y la nueva contraseña.');
    return;
  }

  try {
    final authService = AuthService();

    await authService.confirmForgotPassword(
      email: email,
      code: codeController.text.trim(),
      newPassword: newPasswordController.text.trim(),
    );

    showTopMessage(
      'Contraseña restablecida correctamente.',
      success: true,
    );
  } catch (e) {
    showTopMessage(e.toString());
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1E3A8A),
              Color(0xFF2563EB),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_shipping,
                      size: 90,
                      color: Color(0xFF1E3A8A),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Nanutech Driver',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Inicio de sesión del conductor'),
                    const SizedBox(height: 32),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Correo',
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: showForgotPasswordDialog,
                        child: const Text('Olvidé mi contraseña'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: loading || isBlocked ? null : login,
                      child: loading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              'Ingresar',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}