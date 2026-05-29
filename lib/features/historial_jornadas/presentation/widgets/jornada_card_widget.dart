import 'package:flutter/material.dart';

import '../../data/models/jornada_historial_model.dart';

class JornadaCardWidget extends StatelessWidget {
  final JornadaHistorialModel jornada;

  const JornadaCardWidget({
    super.key,
    required this.jornada,
  });

  @override
  Widget build(BuildContext context) {
    final bool tieneObs = jornada.tieneObservaciones;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: tieneObs
            ? const Border(
                left: BorderSide(color: Color(0xFFEA580C), width: 4),
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildRuta(),
            const SizedBox(height: 10),
            _buildDetalles(),
            if (tieneObs) ...[
              const SizedBox(height: 12),
              _buildObservaciones(),
            ],
            const SizedBox(height: 8),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            jornada.estado,
            style: TextStyle(
              color: Colors.green.shade800,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Spacer(),
        Icon(Icons.local_shipping, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          jornada.placa,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRuta() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.location_on, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            jornada.rutaFormateada,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetalles() {
    return Row(
      children: [
        _buildDetalle(Icons.calendar_today, _formatearFecha(jornada.fecha)),
        const SizedBox(width: 16),
        _buildDetalle(Icons.schedule, jornada.duracionFormateada),
        const SizedBox(width: 16),
        _buildDetalle(Icons.straighten, '${jornada.kmRecorridos.toStringAsFixed(1)} km'),
      ],
    );
  }

  Widget _buildDetalle(IconData icono, String texto) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          texto,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildObservaciones() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.description,
                size: 16,
                color: Color(0xFFEA580C),
              ),
              const SizedBox(width: 6),
              const Text(
                'Observaciones del Conductor',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF9A3412),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            jornada.observaciones,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF7C2D12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        Text(
          'ID: ${jornada.codigo}',
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 11,
          ),
        ),
        if (jornada.tieneObservaciones) ...[
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.description, size: 12, color: Colors.orange.shade800),
                const SizedBox(width: 4),
                Text(
                  'Con observaciones',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _formatearFecha(String fecha) {
    if (fecha.isEmpty) return '-';

    try {
      final partes = fecha.split('-');
      if (partes.length != 3) return fecha;

      final year = partes[0];
      final month = int.parse(partes[1]);
      final day = partes[2];

      const meses = [
        'ene', 'feb', 'mar', 'abr', 'may', 'jun',
        'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
      ];

      return '$day ${meses[month - 1]} $year';
    } catch (_) {
      return fecha;
    }
  }
}