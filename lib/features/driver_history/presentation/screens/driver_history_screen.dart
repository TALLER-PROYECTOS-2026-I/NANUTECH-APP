import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../services/driver_history_api_service.dart';

class DriverHistoryScreen extends StatefulWidget {
  final String conductorId;
  final String token;
  final VoidCallback onBackToDashboard;
  final VoidCallback onOpenMenu;

  const DriverHistoryScreen({
    super.key,
    required this.conductorId,
    required this.token,
    required this.onBackToDashboard,
    required this.onOpenMenu,
  });

  @override
  State<DriverHistoryScreen> createState() => _DriverHistoryScreenState();
}

class _DriverHistoryScreenState extends State<DriverHistoryScreen> {
  final api = DriverHistoryApiService();

  bool loading = true;
  String? error;

  Map<String, dynamic> metrics = {};
  List<dynamic> allJornadas = [];
  List<dynamic> filteredJornadas = [];

  String periodFilter = 'TODAS';
  String observationFilter = 'TODAS';

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final metricsResponse = await api.getMetrics(token: widget.token);
      final historyResponse = await api.getHistory(token: widget.token);

      final metricsData = metricsResponse['data'] ?? {};
      final historyData = historyResponse['data'];

      final jornadas = historyData is List
          ? historyData
          : historyData?['jornadas'] is List
              ? historyData['jornadas']
              : [];

      setState(() {
        metrics = metricsData;
        allJornadas = jornadas;
        filteredJornadas = jornadas;
      });

      applyFilters();
    } on DioException catch (e) {
      setState(() {
        error = e.response?.data?['message'] ??
            'Error de conexión. No se pudo cargar el historial.';
      });
    } catch (_) {
      setState(() {
        error = 'Error de conexión. No se pudo cargar el historial.';
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  void applyFilters() {
    final now = DateTime.now();

    final filtered = allJornadas.where((item) {
      final fechaText = '${item['fecha_jornada'] ?? item['fecha'] ?? ''}';
      final fecha = DateTime.tryParse(fechaText);

      bool periodOk = true;

      if (periodFilter == 'SEMANA' && fecha != null) {
        periodOk = fecha.isAfter(now.subtract(const Duration(days: 7)));
      }

      if (periodFilter == 'MES' && fecha != null) {
        periodOk = fecha.isAfter(now.subtract(const Duration(days: 30)));
      }

      final observacion = '${item['observaciones'] ?? ''}'.trim();
      final hasObs = observacion.isNotEmpty;

      bool obsOk = true;

      if (observationFilter == 'CON_OBSERVACIONES') {
        obsOk = hasObs;
      }

      if (observationFilter == 'SIN_OBSERVACIONES') {
        obsOk = !hasObs;
      }

      return periodOk && obsOk;
    }).toList();

    setState(() {
      filteredJornadas = filtered;
    });
  }

  String formatDate(String? value) {
    if (value == null || value.isEmpty) return '-';

    final date = DateTime.tryParse(value);
    if (date == null) return value;

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String formatHour(String? value) {
    if (value == null || value.isEmpty) return '-';

    final date = DateTime.tryParse(value);
    if (date == null) return '-';

    final local = date.toLocal();

    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  String formatDuration(dynamic secondsValue) {
    final seconds = secondsValue is int
        ? secondsValue
        : int.tryParse('${secondsValue ?? 0}') ?? 0;

    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    return '${hours}h ${minutes}m';
  }

  double toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f7fb),
      body: SafeArea(
        child: Column(
          children: [
            _DriverSectionHeader(
              title: 'Historial de Jornadas',
              subtitle: 'Consulta tus jornadas finalizadas',
              onOpenMenu: widget.onOpenMenu,
              onRetry: loadHistory,
            ),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : error != null
                      ? _ErrorState(
                          message: error!,
                          onRetry: loadHistory,
                        )
                      : RefreshIndicator(
                          onRefresh: loadHistory,
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
                            children: [
                              _MetricsGrid(metrics: metrics),
                              const SizedBox(height: 18),
                              _Filters(
                                periodFilter: periodFilter,
                                observationFilter: observationFilter,
                                onPeriodChanged: (value) {
                                  setState(() {
                                    periodFilter = value;
                                  });
                                  applyFilters();
                                },
                                onObservationChanged: (value) {
                                  setState(() {
                                    observationFilter = value;
                                  });
                                  applyFilters();
                                },
                              ),
                              const SizedBox(height: 18),
                              if (filteredJornadas.isEmpty)
                                const _EmptyState()
                              else
                                ...filteredJornadas.map(
                                  (jornada) => _JornadaHistoryCard(
                                    jornada: jornada,
                                    formatDate: formatDate,
                                    formatHour: formatHour,
                                    formatDuration: formatDuration,
                                    toDouble: toDouble,
                                  ),
                                ),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onRetry;

  const _HistoryHeader({
    required this.onBack,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xff1e3a8a),
            Color(0xff2563eb),
          ],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            tooltip: 'Volver al Dashboard',
          ),
          const Expanded(
            child: Text(
              'Historial de Jornadas',
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  final Map<String, dynamic> metrics;

  const _MetricsGrid({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Total de Jornadas',
                value: '${metrics['total_jornadas'] ?? 0}',
                icon: Icons.calendar_month,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: 'Horas Trabajadas',
                value: '${metrics['horas_trabajadas'] ?? 0}',
                icon: Icons.schedule,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Kilómetros Recorridos',
                value: '${metrics['kilometros_recorridos'] ?? 0}',
                icon: Icons.route,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: 'Con Observaciones',
                value: '${metrics['jornadas_con_observaciones'] ?? 0}',
                icon: Icons.notes,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xff2563eb)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  final String periodFilter;
  final String observationFilter;
  final ValueChanged<String> onPeriodChanged;
  final ValueChanged<String> onObservationChanged;

  const _Filters({
    required this.periodFilter,
    required this.observationFilter,
    required this.onPeriodChanged,
    required this.onObservationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: periodFilter,
          decoration: const InputDecoration(
            labelText: 'Período',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'SEMANA', child: Text('Última Semana')),
            DropdownMenuItem(value: 'MES', child: Text('Último Mes')),
            DropdownMenuItem(value: 'TODAS', child: Text('Todas')),
          ],
          onChanged: (value) {
            if (value != null) onPeriodChanged(value);
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: observationFilter,
          decoration: const InputDecoration(
            labelText: 'Observaciones',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'TODAS', child: Text('Todas')),
            DropdownMenuItem(
              value: 'CON_OBSERVACIONES',
              child: Text('Con Observaciones'),
            ),
            DropdownMenuItem(
              value: 'SIN_OBSERVACIONES',
              child: Text('Sin Observaciones'),
            ),
          ],
          onChanged: (value) {
            if (value != null) onObservationChanged(value);
          },
        ),
      ],
    );
  }
}

class _JornadaHistoryCard extends StatelessWidget {
  final dynamic jornada;
  final String Function(String?) formatDate;
  final String Function(String?) formatHour;
  final String Function(dynamic) formatDuration;
  final double Function(dynamic) toDouble;

  const _JornadaHistoryCard({
    required this.jornada,
    required this.formatDate,
    required this.formatHour,
    required this.formatDuration,
    required this.toDouble,
  });

  @override
  Widget build(BuildContext context) {
    final id = '${jornada['id'] ?? jornada['codigo'] ?? '-'}';
    final origen = '${jornada['origen'] ?? 'No definido'}';
    final destino = '${jornada['destino'] ?? 'No definido'}';
    final fecha = '${jornada['fecha_jornada'] ?? jornada['fecha'] ?? ''}';
    final inicio = '${jornada['hora_inicio'] ?? ''}';
    final fin = '${jornada['hora_fin'] ?? ''}';

    final kilometros = toDouble(
      jornada['kilometros'] ??
          jornada['distancia_km'] ??
          jornada['distancia_total_km'],
    );

    final duracion = jornada['duracion_total_segundos'];
    final observaciones = '${jornada['observaciones'] ?? ''}'.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Jornada: $id',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$origen → $destino',
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xff1e3a8a),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _Line(label: 'Fecha', value: formatDate(fecha)),
          _Line(
            label: 'Horario',
            value: '${formatHour(inicio)} - ${formatHour(fin)}',
          ),
          _Line(
            label: 'Kilómetros',
            value: '${kilometros.toStringAsFixed(1)} km',
          ),
          const _Line(label: 'Estado', value: 'Completada'),
          _Line(label: 'Duración', value: formatDuration(duracion)),
          if (observaciones.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Observaciones',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xfff8fafc),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(observaciones),
            ),
          ],
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final String label;
  final String value;

  const _Line({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      alignment: Alignment.center,
      child: const Text(
        'No tienes jornadas registradas en este período',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 54, color: Colors.red),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
class _DriverSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onOpenMenu;
  final VoidCallback onRetry;

  const _DriverSectionHeader({
    required this.title,
    required this.subtitle,
    required this.onOpenMenu,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 205,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xff1e3a8a),
            Color(0xff2563eb),
          ],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onOpenMenu,
                icon: const Icon(Icons.menu, color: Colors.white),
              ),
              const Icon(Icons.local_shipping, color: Colors.white, size: 28),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Nanutech Driver',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, color: Colors.white),
              ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}