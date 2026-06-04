import 'package:flutter/material.dart';

class LicenciaBanner extends StatelessWidget {
  final int diasRestantes;

  const LicenciaBanner({super.key, required this.diasRestantes});

  @override
  Widget build(BuildContext context) {
    Color color;
    String mensaje;

    if (diasRestantes > 30) {
      color = Colors.green;

      mensaje = 'Licencia Vigente - $diasRestantes días restantes';
    } else if (diasRestantes > 0) {
      color = Colors.orange;

      mensaje =
          'Atención: Licencia próxima a vencer - $diasRestantes días restantes';
    } else {
      color = Colors.red;

      mensaje = 'Alerta: Licencia Vencida. Inhabilitado para operar';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: color,
      child: Text(
        mensaje,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
