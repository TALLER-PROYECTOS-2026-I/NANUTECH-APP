import 'package:flutter/material.dart';

import '../../data/models/jornada_historial_model.dart';
import '../../data/models/metricas_historial_model.dart';
import '../../data/repositories/historial_jornadas_repository.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/filtros_observaciones_widget.dart';
import '../widgets/filtros_periodo_widget.dart';
import '../widgets/jornada_card_widget.dart';
import '../widgets/metrica_card_widget.dart';

class HistorialJornadasScreen extends StatefulWidget {
  final String conductorId;
  final String token;

  const HistorialJornadasScreen({
    super.key,
    required this.conductorId,
    required this.token,
  });

  @override
  State<HistorialJornadasScreen> createState() => _HistorialJornadasScreenState();
}

class _HistorialJornadasScreenState extends State<HistorialJornadasScreen> {
  final repository = HistorialJornadasRepository();

  bool loading = true;
  String? errorMensaje;
  MetricasHistorialModel metricas = MetricasHistorialModel.vacio();
  List<JornadaHistorialModel> jornadas = [];

  PeriodoOpcion periodoSeleccionado = PeriodoOpcion.mes;
  ObservacionesOpcion observacionesSeleccionado = ObservacionesOpcion.todas;

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    setState(() {
      loading = true;
      errorMensaje = null;
    });

    try {
      final periodoStr = _periodoToString(periodoSeleccionado);
      final obsStr = _observacionesToString(observacionesSeleccionado);

      final results = await Future.wait([
        repository.getMetricas(token: widget.token, periodo: periodoStr),
        repository.getHistorial(
          token: widget.token,
          periodo: periodoStr,
          observaciones: obsStr,
        ),
      ]);

      if (mounted) {
        setState(() {
          metricas = results[0] as MetricasHistorialModel;
          jornadas = results[1] as List<JornadaHistorialModel>;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMensaje = e.toString().replaceAll('Exception: ', '');
          loading = false;
        });
      }
    }
  }

  void onFiltroPeriodoChanged(PeriodoOpcion nuevoPeriodo) {
    if (periodoSeleccionado == nuevoPeriodo) return;

    setState(() {
      periodoSeleccionado = nuevoPeriodo;
    });
    cargarDatos();
  }

  void onFiltroObservacionesChanged(ObservacionesOpcion nuevaObservacion) {
    if (observacionesSeleccionado == nuevaObservacion) return;

    setState(() {
      observacionesSeleccionado = nuevaObservacion;
    });
    cargarDatos();
  }

  String _periodoToString(PeriodoOpcion opcion) {
    switch (opcion) {
      case PeriodoOpcion.semana:
        return 'semana';
      case PeriodoOpcion.mes:
        return 'mes';
      case PeriodoOpcion.todas:
        return 'todas';
    }
  }

  String _observacionesToString(ObservacionesOpcion opcion) {
    switch (opcion) {
      case ObservacionesOpcion.todas:
        return 'todas';
      case ObservacionesOpcion.con:
        return 'con';
      case ObservacionesOpcion.sin:
        return 'sin';
    }
  }

  String _formatearHoras(double horas) {
    if (horas == horas.truncate()) {
      return '${horas.toInt()}h';
    }
    return '${horas.toStringAsFixed(1)}h';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : errorMensaje != null
                    ? ErrorStateWidget(
                        mensaje: errorMensaje!,
                        onReintentar: cargarDatos,
                      )
                    : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                tooltip: 'Volver al Dashboard',
              ),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Historial de Jornadas',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Consulta tu historial completo de jornadas completadas',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Última act: ${_formatearHoraActual()}',
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: cargarDatos,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMetricas(),
          const SizedBox(height: 20),
          _buildFiltros(),
          const SizedBox(height: 20),
          _buildListaJornadas(),
        ],
      ),
    );
  }

  Widget _buildMetricas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resumen del Período',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: MetricaCardWidget(
                titulo: 'Jornadas',
                valor: metricas.totalJornadas.toString(),
                icono: Icons.calendar_month,
                color: const Color(0xFF2563EB),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricaCardWidget(
                titulo: 'Horas Trab.',
                valor: _formatearHoras(metricas.horasTrabajadas),
                icono: Icons.schedule,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: MetricaCardWidget(
                titulo: 'Kilómetros',
                valor: '${metricas.kmRecorridos.toStringAsFixed(1)} km',
                icono: Icons.straighten,
                color: const Color(0xFF7C3AED),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricaCardWidget(
                titulo: 'Con Obs.',
                valor: metricas.conObservaciones.toString(),
                icono: Icons.description,
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFiltros() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Filtrar por Período',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        FiltrosPeriodoWidget(
          valorActual: periodoSeleccionado,
          onChanged: onFiltroPeriodoChanged,
        ),
        const SizedBox(height: 16),
        const Text(
          'Filtrar por Observaciones',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        FiltrosObservacionesWidget(
          valorActual: observacionesSeleccionado,
          onChanged: onFiltroObservacionesChanged,
        ),
      ],
    );
  }

  Widget _buildListaJornadas() {
    if (jornadas.isEmpty) {
      return const EmptyStateWidget();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jornadas Completadas (${jornadas.length})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        ...jornadas.map((j) => JornadaCardWidget(jornada: j)),
      ],
    );
  }

  String _formatearHoraActual() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}';
  }
}