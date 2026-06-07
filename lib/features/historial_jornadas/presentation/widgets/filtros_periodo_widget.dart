import 'package:flutter/material.dart';

enum PeriodoOpcion { semana, mes, todas }

class FiltrosPeriodoWidget extends StatelessWidget {
  final PeriodoOpcion valorActual;
  final ValueChanged<PeriodoOpcion> onChanged;

  const FiltrosPeriodoWidget({
    super.key,
    required this.valorActual,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildOpcion('Última Semana', PeriodoOpcion.semana),
        const SizedBox(width: 8),
        _buildOpcion('Último Mes', PeriodoOpcion.mes),
        const SizedBox(width: 8),
        _buildOpcion('Todas', PeriodoOpcion.todas),
      ],
    );
  }

  Widget _buildOpcion(String texto, PeriodoOpcion opcion) {
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
          child: Text(
            texto,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: activo ? Colors.white : Colors.grey.shade700,
              fontWeight: activo ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}