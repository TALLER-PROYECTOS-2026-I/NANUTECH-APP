import 'package:flutter/material.dart';

enum ObservacionesOpcion { todas, con, sin }

class FiltrosObservacionesWidget extends StatelessWidget {
  final ObservacionesOpcion valorActual;
  final ValueChanged<ObservacionesOpcion> onChanged;

  const FiltrosObservacionesWidget({
    super.key,
    required this.valorActual,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildOpcion('Todas', ObservacionesOpcion.todas),
        const SizedBox(width: 8),
        _buildOpcion('Con Observaciones', ObservacionesOpcion.con),
        const SizedBox(width: 8),
        _buildOpcion('Sin Observaciones', ObservacionesOpcion.sin),
      ],
    );
  }

  Widget _buildOpcion(String texto, ObservacionesOpcion opcion) {
    final bool activo = valorActual == opcion;

    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(opcion),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: activo ? const Color(0xFF1E3A8A) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: activo ? const Color(0xFF1E3A8A) : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (opcion == ObservacionesOpcion.con && activo) ...[
                Icon(Icons.description, size: 14, color: Colors.white),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  texto,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: activo ? Colors.white : Colors.grey.shade700,
                    fontWeight: activo ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}