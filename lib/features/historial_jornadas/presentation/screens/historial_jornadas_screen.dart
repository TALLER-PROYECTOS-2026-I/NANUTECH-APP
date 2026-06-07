import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/config/api_config.dart';
import '../../../authentication/presentation/screens/login_screen.dart';
import '../../../authentication/services/session_service.dart';
import '../../domain/historial_jornada_model.dart';
import '../../services/historial_jornada_service.dart';

// ─── Paleta — mismos colores que el Dashboard ─────────────────────────────────
const _kBlue     = Color(0xFF2563EB);
const _kBlueDark = Color(0xFF1E3A8A);
const _kBg       = Color(0xFFF4F7FB);
const _kGreen    = Color(0xFF16A34A);
const _kOrange   = Color(0xFFF59E0B);
const _kPurple   = Color(0xFF7C3AED);
const _kTxtMain  = Color(0xFF1E293B);
const _kTxtSub   = Color(0xFF64748B);
const _kTxtMuted = Color(0xFF94A3B8);
const _kBorder   = Color(0xFFE2E8F0);

/// Pantalla HU04 — Historial de Jornadas.
///
/// Los filtros de período se aplican en el cliente para evitar
/// el error de SQL del backend (syntax error at or near "$2").
class HistorialJornadasScreen extends StatefulWidget {
  final String token;
  final String nombres;

  const HistorialJornadasScreen({
    super.key,
    required this.token,
    required this.nombres,
  });

  @override
  State<HistorialJornadasScreen> createState() =>
      _HistorialJornadasScreenState();
}

class _HistorialJornadasScreenState extends State<HistorialJornadasScreen>
    with SingleTickerProviderStateMixin {
  final _svc     = HistorialJornadaService();
  final _session = SessionService();

  bool    _loading = true;
  String? _error;
  DateTime _lastUpd = DateTime.now();

  // Datos crudos completos (sin filtrar)
  List<HistorialJornadaModel> _allJornadas = [];

  // Filtros activos
  String? _periodo;   // null | 'semana' | 'mes'
  String? _obsFilter; // null | 'con'    | 'sin'

  late final AnimationController _fadeCtrl;
  late final Animation<double>   _fade;

  // ── Init ──────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _load();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Carga — sin params de periodo para evitar bug backend ─────────────────

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });

    try {
      final ok = await _net();
      if (!ok) {
        if (mounted) setState(() { _loading = false; _error = 'Sin conexión. Verifica tu red.'; });
        return;
      }

      // Siempre pedimos TODOS los registros — filtramos en cliente
      final jornadas = await _svc.getHistorial(token: widget.token);

      if (!mounted) return;
      setState(() {
        _allJornadas = jornadas;
        _loading = false;
        _lastUpd = DateTime.now();
      });
      _fadeCtrl.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<bool> _net() async {
    try {
      final host = Uri.parse(ApiConfig.baseUrl).host;
      final r = await InternetAddress.lookup(host)
          .timeout(const Duration(seconds: 4));
      return r.isNotEmpty && r.first.rawAddress.isNotEmpty;
    } catch (_) { return false; }
  }

  // ── Filtrado en cliente ───────────────────────────────────────────────────

  /// Aplica los filtros de período y observaciones sobre la lista completa.
  List<HistorialJornadaModel> get _jornadasFiltradas {
    var lista = _allJornadas;

    // Filtro período
    if (_periodo != null) {
      final now  = DateTime.now();
      final DateTime cutoff;
      if (_periodo == 'semana') {
        cutoff = now.subtract(const Duration(days: 7));
      } else {
        // 'mes' → primer día del mes actual
        cutoff = DateTime(now.year, now.month, 1);
      }
      lista = lista.where((j) {
        final fecha = DateTime.tryParse(j.fecha);
        if (fecha == null) return true;
        return !fecha.isBefore(cutoff);
      }).toList();
    }

    // Filtro observaciones
    if (_obsFilter == 'con') {
      lista = lista
          .where((j) => j.observaciones != null && j.observaciones!.trim().isNotEmpty)
          .toList();
    } else if (_obsFilter == 'sin') {
      lista = lista
          .where((j) => j.observaciones == null || j.observaciones!.trim().isEmpty)
          .toList();
    }

    return lista;
  }

  /// Calcula métricas a partir de la lista filtrada.
  HistorialMetricasModel get _metricasFiltradas {
    final lista = _jornadasFiltradas;
    double horas = 0;
    double km    = 0;
    int    conObs = 0;

    for (final j in lista) {
      km += j.kmRecorridos;
      horas += _parseDuracion(j.duracionFormateada);
      if (j.observaciones != null && j.observaciones!.trim().isNotEmpty) conObs++;
    }

    return HistorialMetricasModel(
      totalJornadas:    lista.length,
      horasTrabajadas:  horas,
      kmRecorridos:     km,
      conObservaciones: conObs,
    );
  }

  /// Parsea "8h 30m" → 8.5  |  "26h 15m" → 26.25  |  "0h 45m" → 0.75
  double _parseDuracion(String dur) {
    if (dur.isEmpty) return 0;
    final hM = RegExp(r'(\d+)h').firstMatch(dur);
    final mM = RegExp(r'(\d+)m').firstMatch(dur);
    final h  = double.tryParse(hM?.group(1) ?? '0') ?? 0;
    final m  = double.tryParse(mM?.group(1) ?? '0') ?? 0;
    return h + m / 60;
  }

  // ── Handlers filtros ─────────────────────────────────────────────────────

  void _setPeriodo(String? v) => setState(() => _periodo = v);
  void _setObs(String? v)     => setState(() => _obsFilter = v);

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _hhmm() {
    final h = _lastUpd.hour.toString().padLeft(2, '0');
    final m = _lastUpd.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _fmtFecha(String raw) {
    final p = raw.split('-');
    if (p.length != 3) return raw;
    const ms = ['','ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic'];
    final idx = int.tryParse(p[1]) ?? 0;
    final lbl = (idx >= 1 && idx <= 12) ? ms[idx] : '?';
    return '${p[2]} $lbl ${p[0]}';
  }

  void _logout() async {
    await _session.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final jornadas = _jornadasFiltradas;
    final metricas = _metricasFiltradas;

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(children: [
        _appBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _pageHeader(context),
                const SizedBox(height: 20),

                // Métricas
                if (_loading)
                  _skelMetricas()
                else if (_error != null)
                  _errBanner()
                else
                  FadeTransition(
                      opacity: _fade, child: _metricsRow(metricas)),

                const SizedBox(height: 20),
                _filtros(),
                const SizedBox(height: 20),

                // Listado
                if (_loading)
                  _skelCards()
                else if (_error == null) ...[
                  if (jornadas.isEmpty) _empty() else _grid(jornadas),
                ],

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  Widget _appBar() => Container(
    padding: const EdgeInsets.fromLTRB(20, 44, 16, 14),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [_kBlueDark, _kBlue],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Row(children: [
      const Icon(Icons.local_shipping, color: Colors.white, size: 26),
      const SizedBox(width: 8),
      const Expanded(child: Text('Nanutech Driver',
          style: TextStyle(color: Colors.white, fontSize: 18,
              fontWeight: FontWeight.bold))),
      Text('Última act. ${_hhmm()}',
          style: const TextStyle(color: Colors.white70, fontSize: 11)),
      const SizedBox(width: 8),
      _RefreshBtn(onTap: _load),
      IconButton(
        onPressed: _logout,
        tooltip: 'Cerrar sesión',
        icon: const Icon(Icons.logout, color: Colors.white, size: 20),
      ),
    ]),
  );

  // ── Encabezado ────────────────────────────────────────────────────────────

  Widget _pageHeader(BuildContext context) => Row(children: [
    GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kBorder),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.07), blurRadius: 8)],
        ),
        child: const Icon(Icons.arrow_back_rounded, color: _kBlue, size: 20),
      ),
    ),
    const SizedBox(width: 14),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Historial de Jornadas',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
              color: _kTxtMain)),
      Text('Hola, ${widget.nombres} — consulta tus jornadas completadas',
          style: const TextStyle(fontSize: 12, color: _kTxtSub)),
    ]),
  ]);

  // ── Métricas ──────────────────────────────────────────────────────────────

  Widget _metricsRow(HistorialMetricasModel m) {
    final h    = m.horasTrabajadas;
    final hInt = h.truncate();
    final hMin = ((h - hInt) * 60).round();
    final horasLabel = hMin == 0 ? '${hInt}h' : '${h.toStringAsFixed(1)}h';
    final km   = m.kmRecorridos;
    final kmLabel = '${km.toStringAsFixed(km == km.truncateToDouble() ? 0 : 1)} km';

    return Row(children: [
      Expanded(child: _MCard(label: 'TOTAL JORNADAS',    value: '${m.totalJornadas}',    icon: Icons.calendar_month_rounded,  color: _kBlue)),
      const SizedBox(width: 12),
      Expanded(child: _MCard(label: 'HORAS TRABAJADAS',  value: horasLabel,               icon: Icons.access_time_rounded,     color: _kGreen)),
      const SizedBox(width: 12),
      Expanded(child: _MCard(label: 'KILÓMETROS',        value: kmLabel,                  icon: Icons.trending_up_rounded,     color: _kPurple)),
      const SizedBox(width: 12),
      Expanded(child: _MCard(label: 'CON OBSERVACIONES', value: '${m.conObservaciones}',  icon: Icons.warning_amber_rounded,   color: _kOrange)),
    ]);
  }

  Widget _skelMetricas() => Row(
    children: List.generate(4, (i) => Expanded(
      child: Container(
        margin: EdgeInsets.only(left: i == 0 ? 0 : 12),
        height: 92,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBorder),
        ),
        child: const _Shimmer(),
      ),
    )),
  );

  // ── Filtros ───────────────────────────────────────────────────────────────

  Widget _filtros() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _kBorder),
      boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.04), blurRadius: 8)],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const _FLbl('PERÍODO'), const SizedBox(width: 12),
        _Chip(label: 'Última semana', active: _periodo == 'semana',
            onTap: () => _setPeriodo(_periodo == 'semana' ? null : 'semana')),
        const SizedBox(width: 8),
        _Chip(label: 'Último mes',    active: _periodo == 'mes',
            onTap: () => _setPeriodo(_periodo == 'mes' ? null : 'mes')),
        const SizedBox(width: 8),
        _Chip(label: 'Todas',         active: _periodo == null,
            onTap: () => _setPeriodo(null)),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        const _FLbl('ESTADO'), const SizedBox(width: 12),
        _Chip(label: 'Todas',             active: _obsFilter == null,
            onTap: () => _setObs(null)),
        const SizedBox(width: 8),
        _Chip(label: 'Con observaciones', active: _obsFilter == 'con',
            onTap: () => _setObs(_obsFilter == 'con' ? null : 'con')),
        const SizedBox(width: 8),
        _Chip(label: 'Sin observaciones', active: _obsFilter == 'sin',
            onTap: () => _setObs(_obsFilter == 'sin' ? null : 'sin')),
      ]),
    ]),
  );

  // ── Grid de jornadas ─────────────────────────────────────────────────────

  Widget _grid(List<HistorialJornadaModel> jornadas) {
    final rows = <Widget>[];
    for (int i = 0; i < jornadas.length; i += 2) {
      rows.add(IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _JCard(j: jornadas[i], fmtFecha: _fmtFecha)),
          const SizedBox(width: 14),
          Expanded(child: i + 1 < jornadas.length
              ? _JCard(j: jornadas[i + 1], fmtFecha: _fmtFecha)
              : const SizedBox()),
        ]),
      ));
      if (i + 2 < jornadas.length) rows.add(const SizedBox(height: 14));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        '${jornadas.length} jornada${jornadas.length != 1 ? 's' : ''} encontrada${jornadas.length != 1 ? 's' : ''}',
        style: const TextStyle(color: _kTxtSub, fontSize: 13),
      ),
      const SizedBox(height: 14),
      ...rows,
    ]);
  }

  Widget _skelCards() => Column(
    children: List.generate(2, (_) => Container(
      margin: const EdgeInsets.only(bottom: 14),
      height: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: const _Shimmer(),
    )),
  );

  // ── Estado vacío / error ─────────────────────────────────────────────────

  Widget _empty() => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(children: [
        CircleAvatar(
          backgroundColor: _kBlue.withOpacity(0.08),
          radius: 32,
          child: const Icon(Icons.history_rounded, color: _kBlue, size: 30),
        ),
        const SizedBox(height: 16),
        const Text('No tienes jornadas registradas en este período',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                color: _kTxtMain)),
        const SizedBox(height: 6),
        const Text('Prueba cambiando el filtro de período o estado.',
            style: TextStyle(color: _kTxtSub, fontSize: 13)),
      ]),
    ),
  );

  Widget _errBanner() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.red.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.red.shade200),
    ),
    child: Row(children: [
      Icon(Icons.error_outline_rounded, color: Colors.red.shade600, size: 20),
      const SizedBox(width: 12),
      Expanded(child: Text(_error!,
          style: TextStyle(color: Colors.red.shade700, fontSize: 13))),
      const SizedBox(width: 12),
      GestureDetector(
        onTap: _load,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.red.shade100,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text('Reintentar',
              style: TextStyle(color: Colors.red.shade700,
                  fontWeight: FontWeight.w600, fontSize: 12)),
        ),
      ),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// METRIC CARD
// ─────────────────────────────────────────────────────────────────────────────

class _MCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _MCard({required this.label, required this.value,
    required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [color, color.withOpacity(0.78)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(
          color: color.withOpacity(0.28), blurRadius: 14,
          offset: const Offset(0, 4))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Flexible(child: Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 10,
                fontWeight: FontWeight.w700, letterSpacing: 0.8))),
        Icon(icon, color: Colors.white70, size: 16),
      ]),
      const SizedBox(height: 10),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 26,
          fontWeight: FontWeight.w800, height: 1)),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// CHIPS & LABEL
// ─────────────────────────────────────────────────────────────────────────────

class _FLbl extends StatelessWidget {
  final String t;
  const _FLbl(this.t);
  @override
  Widget build(BuildContext context) => Text(t,
      style: const TextStyle(color: _kTxtMuted, fontSize: 10,
          fontWeight: FontWeight.w700, letterSpacing: 1));
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: active ? _kBlue : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: active ? _kBlue : _kBorder),
      ),
      child: Text(label, style: TextStyle(
        color: active ? Colors.white : _kTxtSub,
        fontSize: 12,
        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
      )),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// REFRESH BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _RefreshBtn extends StatefulWidget {
  final VoidCallback onTap;
  const _RefreshBtn({required this.onTap});
  @override State<_RefreshBtn> createState() => _RefreshBtnState();
}

class _RefreshBtnState extends State<_RefreshBtn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700));
  @override void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () { _c.forward(from: 0); widget.onTap(); },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: Colors.white24, borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        RotationTransition(turns: _c,
            child: const Icon(Icons.refresh_rounded, size: 14,
                color: Colors.white)),
        const SizedBox(width: 4),
        const Text('Actualizar',
            style: TextStyle(color: Colors.white, fontSize: 12)),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// JORNADA CARD
// ─────────────────────────────────────────────────────────────────────────────

class _JCard extends StatefulWidget {
  final HistorialJornadaModel j;
  final String Function(String) fmtFecha;
  const _JCard({required this.j, required this.fmtFecha});
  @override State<_JCard> createState() => _JCardState();
}

class _JCardState extends State<_JCard> {
  bool _hov = false;

  @override
  Widget build(BuildContext context) {
    final j        = widget.j;
    final tieneObs = j.observaciones != null &&
        j.observaciones!.trim().isNotEmpty;
    final barColor = tieneObs ? _kOrange : _kBlue;

    String codigo;
    try {
      codigo = j.codigo.isNotEmpty && j.codigo.length <= 12
          ? j.codigo.toUpperCase()
          : 'HIST-${j.id.length >= 4 ? j.id.substring(0, 4).toUpperCase() : j.id.toUpperCase()}';
    } catch (_) { codigo = 'HIST'; }

    String kmLabel;
    try {
      final km = j.kmRecorridos;
      kmLabel = '${km.toStringAsFixed(km == km.truncateToDouble() ? 0 : 1)} km';
    } catch (_) { kmLabel = '— km'; }

    return MouseRegion(
      onEnter: (_) => setState(() => _hov = true),
      onExit:  (_) => setState(() => _hov = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: _hov ? const Color(0xFFF0F6FF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBorder),
          boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(_hov ? 0.09 : 0.04),
            blurRadius: _hov ? 14 : 6,
          )],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(width: 4, color: barColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Código + Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(codigo, style: const TextStyle(
                            color: _kTxtMuted, fontSize: 11,
                            fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                        _Badge(),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Ruta
                    Row(children: [
                      const Icon(Icons.location_on_rounded,
                          color: _kBlue, size: 14),
                      const SizedBox(width: 4),
                      Flexible(child: Text(
                          j.origen.isNotEmpty ? j.origen : '—',
                          style: const TextStyle(color: _kTxtMain,
                              fontSize: 14, fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(Icons.arrow_forward_rounded,
                            color: _kTxtMuted, size: 13),
                      ),
                      Flexible(child: Text(
                          j.destino.isNotEmpty ? j.destino : '—',
                          style: const TextStyle(color: _kTxtMain,
                              fontSize: 14, fontWeight: FontWeight.w700),
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis)),
                    ]),
                    const SizedBox(height: 8),

                    // Fecha y horario
                    Row(children: [
                      const Icon(Icons.calendar_today_rounded,
                          color: _kTxtMuted, size: 12),
                      const SizedBox(width: 4),
                      Flexible(child: Text(
                          j.fecha.isNotEmpty
                              ? widget.fmtFecha(j.fecha) : '—',
                          style: const TextStyle(
                              color: _kTxtSub, fontSize: 12))),
                      const SizedBox(width: 12),
                      const Icon(Icons.access_time_rounded,
                          color: _kTxtMuted, size: 12),
                      const SizedBox(width: 4),
                      Flexible(child: Text(
                          '${j.horaInicio.isNotEmpty ? j.horaInicio : "—"}'
                          ' – '
                          '${j.horaFin.isNotEmpty ? j.horaFin : "—"}',
                          style: const TextStyle(
                              color: _kTxtSub, fontSize: 12),
                          overflow: TextOverflow.ellipsis)),
                    ]),
                    const SizedBox(height: 6),

                    // Km y duración
                    Row(children: [
                      const Icon(Icons.trending_up_rounded,
                          color: _kPurple, size: 12),
                      const SizedBox(width: 4),
                      Text(kmLabel, style: const TextStyle(
                          color: _kTxtSub, fontSize: 12)),
                      const SizedBox(width: 12),
                      const Icon(Icons.timer_rounded,
                          color: _kBlue, size: 12),
                      const SizedBox(width: 4),
                      Text(
                          j.duracionFormateada.isNotEmpty
                              ? j.duracionFormateada : '—',
                          style: const TextStyle(color: _kBlue,
                              fontSize: 12, fontWeight: FontWeight.w700)),
                    ]),

                    // Observaciones — solo lectura
                    if (tieneObs) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _kOrange.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: _kOrange.withOpacity(0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                color: _kOrange, size: 13),
                            const SizedBox(width: 6),
                            Expanded(child: Text(j.observaciones!,
                                style: const TextStyle(
                                    color: _kTxtSub, fontSize: 11,
                                    height: 1.4),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: _kGreen.withOpacity(0.10),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _kGreen.withOpacity(0.4)),
    ),
    child: const Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.check_rounded, color: _kGreen, size: 11),
      SizedBox(width: 4),
      Text('Completada', style: TextStyle(
          color: _kGreen, fontSize: 11, fontWeight: FontWeight.w600)),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SHIMMER
// ─────────────────────────────────────────────────────────────────────────────

class _Shimmer extends StatefulWidget {
  const _Shimmer();
  @override State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100))
    ..repeat(reverse: true);
  @override void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, __) => Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: const [Color(0xFFE8EDF2), Color(0xFFF5F8FA),
            Color(0xFFE8EDF2)],
          stops: [0, _c.value, 1],
        ),
      ),
    ),
  );
}
