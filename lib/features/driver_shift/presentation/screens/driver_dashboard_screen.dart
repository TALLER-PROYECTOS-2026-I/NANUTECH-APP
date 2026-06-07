import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/database/database_service.dart';
import '../../../../core/sync/sync_service.dart';

import '../../domain/jornada_model.dart';
import '../../services/jornada_api_service.dart';

import '../../../authentication/presentation/screens/login_screen.dart';
import '../../../historial_jornadas/presentation/screens/historial_jornadas_screen.dart';
import '../../../authentication/services/session_service.dart';

import '../../../emergency_alerts/services/emergency_alert_api_service.dart';
import '../../../emergency_alerts/services/location_service.dart';
import '../../../emergency_alerts/presentation/widgets/sos_panic_button.dart';
import '../../../emergency_alerts/presentation/widgets/mechanical_assistance_modal.dart';

class DriverDashboardScreen extends StatefulWidget {
  final String conductorId;
  final String token;
  final String nombres;

  const DriverDashboardScreen({
    super.key,
    required this.conductorId,
    required this.token,
    required this.nombres,
  });

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  final syncService = SyncService();
  final jornadaApi = JornadaApiService();
  final sessionService = SessionService();

  /// Servicio encargado de consumir los endpoints HU21:
  /// POST /alertas/sos y POST /alertas/auxilio.
  final emergencyApi = EmergencyAlertApiService();

  /// Servicio encargado de obtener latitud y longitud reales
  /// desde el GPS del dispositivo.
  final locationService = LocationService();

  StreamSubscription? connectivitySubscription;
  Timer? timer;
  Timer? sosPollingTimer;

  bool isOnline = false;
  bool loading = true;
  bool syncing = false;

  /// Cuando se dispara SOS, la app queda bloqueada visualmente
  /// hasta que un administrador levante la alerta desde el panel.
  bool sosLocked = false;

  JornadaModel? jornada;
  Duration elapsed = Duration.zero;
  int jornadasMes = 0;
  Duration horasTrabajadas = Duration.zero;

  @override
  void initState() {
    super.initState();
    listenConnectivity();
    loadJornada();
    startTimer();
  }

  void listenConnectivity() {
    connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((_) async {
      final connected = await hasRealInternet();

      if (!mounted) return;

      setState(() {
        isOnline = connected;
      });

      if (connected) {
        await syncPendingEvents();
        await refreshJornadaSilently();
      }
    });
  }

  Future<void> refreshJornadaSilently() async {
    try {
      final connected = await hasRealInternet();

      if (!connected) {
        if (mounted) {
          setState(() {
            isOnline = false;
          });
        }
        return;
      }

      final remote = await jornadaApi.getJornadaActual(
        conductorId: widget.conductorId,
        token: widget.token,
      );

      if (remote != null) {
        await saveJornadaCache(remote);

        if (mounted) {
          setState(() {
            jornada = remote;
            isOnline = true;
          });
        }
      }

      await loadCounters();
      await sessionService.updateLastActivity();
    } catch (_) {
      if (mounted) {
        setState(() {
          isOnline = false;
        });
      }
    }
  }

  Future<bool> hasRealInternet() async {
    try {
      final host = Uri.parse(ApiConfig.baseUrl).host;

      final result = await InternetAddress.lookup(host)
          .timeout(const Duration(seconds: 3));

      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void startTimer() {
    timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => updateElapsed(),
    );
  }

  void updateElapsed() {
    final current = jornada;

    if (current == null || current.estado != 'EN_PROCESO') {
      if (mounted && elapsed != Duration.zero) {
        setState(() {
          elapsed = Duration.zero;
        });
      }
      return;
    }

    final inicio = current.horaInicio;

    if (inicio == null || inicio.isEmpty) return;

    final startDate = DateTime.tryParse(inicio);

    if (startDate == null) return;

    final nextElapsed = DateTime.now().toUtc().difference(startDate.toUtc());

    if (mounted) {
      setState(() {
        elapsed = nextElapsed;
      });
    }
  }

  String formatDuration(Duration duration) {
    final h = duration.inHours.toString().padLeft(2, '0');
    final m = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    return '$h:$m:$s';
  }

  String formatDate(String? value) {
    if (value == null || value.isEmpty) return '-';

    final date = DateTime.tryParse(value);
    if (date == null) return value;

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String formatDateTime(String? value) {
    if (value == null || value.isEmpty) return '-';

    final date = DateTime.tryParse(value);
    if (date == null) return value;

    final local = date.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}:'
        '${local.second.toString().padLeft(2, '0')}';
  }

  Future<void> loadJornada() async {
    setState(() => loading = true);

    try {
      final connected = await hasRealInternet();

      setState(() {
        isOnline = connected;
      });

      if (connected) {
        final remote = await jornadaApi.getJornadaActual(
          conductorId: widget.conductorId,
          token: widget.token,
        );

        if (remote != null) {
          await saveJornadaCache(remote);
          setState(() => jornada = remote);
        } else {
          final local = await getJornadaCache();
          setState(() => jornada = local);
        }
      } else {
        final local = await getJornadaCache();
        setState(() => jornada = local);
      }

      await loadCounters();
      await sessionService.updateLastActivity();
    } catch (_) {
      final local = await getJornadaCache();

      setState(() {
        jornada = local;
        isOnline = false;
      });

      await loadCounters();
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> saveJornadaCache(JornadaModel jornada) async {
    final db = await DatabaseService.database;

    await db.insert(
      'jornada_cache',
      {
        'id': jornada.id,
        'data': jsonEncode(jornada.toJson()),
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<JornadaModel?> getJornadaCache() async {
    final db = await DatabaseService.database;

    final result = await db.query(
      'jornada_cache',
      limit: 1,
    );

    if (result.isEmpty) return null;

    return JornadaModel.fromJson(
      jsonDecode(result.first['data'].toString()),
    );
  }

  Future<void> loadCounters() async {
    final local = jornada;

    int totalJornadas = 0;
    Duration totalHoras = Duration.zero;

    if (local != null && local.estado == 'COMPLETADA') {
      totalJornadas = 1;

      if (local.duracionTotalSegundos != null) {
        totalHoras = Duration(seconds: local.duracionTotalSegundos!);
      } else if (local.horaInicio != null && local.horaFin != null) {
        final inicio = DateTime.tryParse(local.horaInicio!);
        final fin = DateTime.tryParse(local.horaFin!);

        if (inicio != null && fin != null) {
          totalHoras = fin.toUtc().difference(inicio.toUtc());
        }
      }
    }

    if (!mounted) return;

    setState(() {
      jornadasMes = totalJornadas;
      horasTrabajadas = totalHoras;
    });
  }

  Future<void> iniciarTurno() async {
    if (jornada == null) return;

    final connected = await hasRealInternet();

    if (connected) {
      try {
        final updated = await jornadaApi.iniciarJornada(
          jornadaId: jornada!.id,
          conductorId: widget.conductorId,
          token: widget.token,
        );

        await saveJornadaCache(updated);
        await sessionService.updateLastActivity();

        setState(() {
          jornada = updated;
          isOnline = true;
        });

        showMessage('¡Turno iniciado exitosamente!', success: true);
        return;
      } on DioException {
        await iniciarTurnoOffline();
        return;
      } catch (_) {
        await iniciarTurnoOffline();
        return;
      }
    }

    await iniciarTurnoOffline();
  }

  Future<void> iniciarTurnoOffline() async {
    if (jornada == null) return;

    final now = DateTime.now().toUtc().toIso8601String();

    await syncService.saveOfflineEvent(
      eventType: 'START_JORNADA',
      payload: {
        'jornada_id': jornada!.id,
        'conductor_id': widget.conductorId,
        'timestamp_local': now,
      },
    );

    final localUpdated = JornadaModel(
      id: jornada!.id,
      conductorId: jornada!.conductorId,
      origen: jornada!.origen,
      destino: jornada!.destino,
      estado: 'EN_PROCESO',
      placa: jornada!.placa,
      contratoId: jornada!.contratoId,
      fechaJornada: jornada!.fechaJornada,
      horaInicio: now,
      horaFin: jornada!.horaFin,
      observaciones: jornada!.observaciones,
      duracionTotalSegundos: jornada!.duracionTotalSegundos,
    );

    await saveJornadaCache(localUpdated);
    await sessionService.updateLastActivity();

    setState(() {
      jornada = localUpdated;
      isOnline = false;
    });

    showMessage('Sin conexión. Inicio guardado localmente.', success: true);
  }

  Future<void> finalizarTurno() async {
    if (jornada == null) return;

    if (sosLocked) {
      showMessage('Sistema bloqueado por alerta SOS.');
      return;
    }

    final observaciones = await askObservaciones();

    if (observaciones == null) return;

    final connected = await hasRealInternet();

    if (connected) {
      try {
        final updated = await jornadaApi.finalizarJornada(
          jornadaId: jornada!.id,
          conductorId: widget.conductorId,
          token: widget.token,
          observaciones: observaciones,
        );

        await saveJornadaCache(updated);
        await sessionService.updateLastActivity();

        setState(() {
          jornada = updated;
          isOnline = true;
        });

        await loadCounters();

        showMessage(
          '¡Turno finalizado exitosamente! Duración: ${formatDuration(getTotalDuration(updated))}',
          success: true,
        );

        return;
      } on DioException {
        await finalizarTurnoOffline(observaciones);
        return;
      } catch (_) {
        await finalizarTurnoOffline(observaciones);
        return;
      }
    }

    await finalizarTurnoOffline(observaciones);
  }
    Duration getTotalDuration(JornadaModel current) {
    if (current.duracionTotalSegundos != null) {
      return Duration(seconds: current.duracionTotalSegundos!);
    }

    if (current.horaInicio != null && current.horaFin != null) {
      final inicio = DateTime.tryParse(current.horaInicio!);
      final fin = DateTime.tryParse(current.horaFin!);

      if (inicio != null && fin != null) {
        return fin.toUtc().difference(inicio.toUtc());
      }
    }

    return Duration.zero;
  }

  Future<void> finalizarTurnoOffline(String observaciones) async {
    if (jornada == null) return;

    final now = DateTime.now().toUtc().toIso8601String();

    await syncService.saveOfflineEvent(
      eventType: 'END_JORNADA',
      payload: {
        'jornada_id': jornada!.id,
        'conductor_id': widget.conductorId,
        'timestamp_local': now,
        'observaciones': observaciones,
      },
    );

    final localUpdated = JornadaModel(
      id: jornada!.id,
      conductorId: jornada!.conductorId,
      origen: jornada!.origen,
      destino: jornada!.destino,
      estado: 'COMPLETADA',
      placa: jornada!.placa,
      contratoId: jornada!.contratoId,
      fechaJornada: jornada!.fechaJornada,
      horaInicio: jornada!.horaInicio,
      horaFin: now,
      observaciones: observaciones,
      duracionTotalSegundos: null,
    );

    await saveJornadaCache(localUpdated);
    await sessionService.updateLastActivity();

    setState(() {
      jornada = localUpdated;
      isOnline = false;
    });

    await loadCounters();

    showMessage(
      'Sin conexión. Finalización guardada localmente. Se sincronizará automáticamente.',
      success: true,
    );
  }

  /// HU21 - Envía alerta SOS con ubicación real del dispositivo.
  ///
  /// Flujo:
  /// 1. Valida que exista una jornada EN_PROCESO.
  /// 2. Solicita GPS real con LocationService.
  /// 3. Si hay internet, envía POST /alertas/sos.
  /// 4. Si no hay internet, guarda evento SOS_ALERT en SQLite.
  /// 5. Bloquea visualmente la app por seguridad.
  Future<void> sendSosAlert() async {
    if (jornada == null || jornada!.estado != 'EN_PROCESO') {
      showMessage('Solo puedes enviar SOS con una jornada en proceso.');
      return;
    }

    try {
      final position = await locationService.getCurrentPosition();
      final eventId = 'SOS-${DateTime.now().millisecondsSinceEpoch}';
      final connected = await hasRealInternet();

      if (connected) {
        await emergencyApi.sendSos(
          token: widget.token,
          jornadaId: jornada!.id,
          conductorId: widget.conductorId,
          latitud: position.latitude,
          longitud: position.longitude,
          eventIdCliente: eventId,
        );
      } else {
        await syncService.saveOfflineEvent(
          eventType: 'SOS_ALERT',
          priority: 0,
          payload: {
            'jornada_id': jornada!.id,
            'conductor_id': widget.conductorId,
            'latitud': position.latitude,
            'longitud': position.longitude,
            'timestamp_local': DateTime.now().toIso8601String(),
            'created_offline': true,
            'event_id_cliente': eventId,
          },
        );
      }

      await sessionService.updateLastActivity();

      if (!mounted) return;

      setState(() {
        sosLocked = true;
      });

      startSosPolling();

    } catch (e) {
      showMessage(
        e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void startSosPolling() {
  sosPollingTimer?.cancel();

  sosPollingTimer = Timer.periodic(
    const Duration(seconds: 10),
    (_) => checkSosResolved(),
  );
}

Future<void> checkSosResolved() async {
  if (!sosLocked || jornada == null) return;

  try {
    final hasSos = await emergencyApi.hasActiveSos(
      token: widget.token,
      jornadaId: jornada!.id,
    );

    if (!hasSos && mounted) {
      sosPollingTimer?.cancel();

      setState(() {
        sosLocked = false;
      });

      showMessage(
        'Alerta SOS resuelta. Sistema desbloqueado.',
        success: true,
      );
    }
  } catch (_) {
    // Si falla la consulta, la app mantiene el bloqueo por seguridad.
  }
}

  /// HU21 - Abre modal de Auxilio Mecánico y envía solicitud.
  ///
  /// Flujo:
  /// 1. Valida jornada EN_PROCESO.
  /// 2. Muestra modal con información, avisos, contacto y selector.
  /// 3. Obtiene GPS real del dispositivo.
  /// 4. Si hay internet, envía POST /alertas/auxilio.
  /// 5. Si no hay internet, guarda MECHANICAL_ASSISTANCE con prioridad.
  Future<void> openMechanicalAssistance() async {
    if (jornada == null || jornada!.estado != 'EN_PROCESO') {
      showMessage('Solo puedes solicitar auxilio con una jornada en proceso.');
      return;
    }

    final result = await showModalBottomSheet<MechanicalAssistanceResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const MechanicalAssistanceModal(),
    );

    if (result == null) return;

    try {
      final position = await locationService.getCurrentPosition();
      final eventId = 'AUX-${DateTime.now().millisecondsSinceEpoch}';
      final connected = await hasRealInternet();

      if (connected) {
        await emergencyApi.sendMechanicalAssistance(
          token: widget.token,
          jornadaId: jornada!.id,
          conductorId: widget.conductorId,
          tipoFalla: result.tipoFalla,
          detalle: result.detalle,
          latitud: position.latitude,
          longitud: position.longitude,
          eventIdCliente: eventId,
        );
      } else {
        await syncService.saveOfflineEvent(
          eventType: 'MECHANICAL_ASSISTANCE',
          priority: 1,
          payload: {
            'jornada_id': jornada!.id,
            'conductor_id': widget.conductorId,
            'tipo_falla_mecanica': result.tipoFalla,
            'detalle': result.detalle,
            'latitud': position.latitude,
            'longitud': position.longitude,
            'timestamp_local': DateTime.now().toIso8601String(),
            'created_offline': true,
            'event_id_cliente': eventId,
          },
        );
      }

      await sessionService.updateLastActivity();

      showMessage(
        'Auxilio Mecánico Solicitado. Tu solicitud ha sido enviada.',
        success: true,
      );
    } catch (e) {
      showMessage(
        e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Sincroniza eventos offline.
  ///
  /// HU21 exige prioridad absoluta para SOS si se generó sin conexión.
  /// Por eso primero se procesan SOS_ALERT, luego Auxilio, y al final
  /// eventos normales de jornada.
  Future<void> syncPendingEvents() async {
    if (syncing) return;

    final connected = await hasRealInternet();

    if (!connected) {
      if (mounted) {
        setState(() {
          isOnline = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        syncing = true;
      });
    }

    final events = await syncService.getPendingEvents();

    final sortedEvents = [...events]..sort((a, b) {
        int priority(String type) {
          if (type == 'SOS_ALERT') return 0;
          if (type == 'MECHANICAL_ASSISTANCE') return 1;
          return 2;
        }

        return priority(a['event_type']).compareTo(
          priority(b['event_type']),
        );
      });

    for (final event in sortedEvents) {
      try {
        final payload = jsonDecode(event['payload']);

        if (event['event_type'] == 'SOS_ALERT') {
          await emergencyApi.sendSos(
            token: widget.token,
            jornadaId: payload['jornada_id'],
            conductorId: payload['conductor_id'],
            latitud: payload['latitud'],
            longitud: payload['longitud'],
            eventIdCliente: payload['event_id_cliente'],
          );

          if (mounted) {
            setState(() {
              sosLocked = true;
            });
          }
        }

        if (event['event_type'] == 'MECHANICAL_ASSISTANCE') {
          await emergencyApi.sendMechanicalAssistance(
            token: widget.token,
            jornadaId: payload['jornada_id'],
            conductorId: payload['conductor_id'],
            tipoFalla: payload['tipo_falla_mecanica'],
            detalle: payload['detalle'] ?? '',
            latitud: payload['latitud'],
            longitud: payload['longitud'],
            eventIdCliente: payload['event_id_cliente'],
          );
        }

        if (event['event_type'] == 'START_JORNADA') {
          await jornadaApi.iniciarJornada(
            jornadaId: payload['jornada_id'],
            conductorId: payload['conductor_id'],
            token: widget.token,
          );
        }

        if (event['event_type'] == 'END_JORNADA') {
          await jornadaApi.finalizarJornada(
            jornadaId: payload['jornada_id'],
            conductorId: payload['conductor_id'],
            token: widget.token,
            observaciones: payload['observaciones'],
          );
        }

        await syncService.markAsSynced(event['id']);
        await syncService.addLog('Evento ${event['id']} sincronizado');
      } catch (e) {
        await syncService.addLog('Error sincronizando ${event['id']}: $e');
      }
    }

    if (mounted) {
      setState(() {
        syncing = false;
      });
    }
  }

  Future<String?> askObservaciones() {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Finalizar turno'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Observaciones opcionales',
            hintText: 'Ejemplo: Ruta finalizada sin incidentes.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffdc2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(
              context,
              controller.text.trim(),
            ),
            icon: const Icon(Icons.stop_circle),
            label: const Text('Finalizar'),
          ),
        ],
      ),
    );
  }

  Future<void> logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Deseas cerrar tu sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await sessionService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (_) => false,
    );
  }

  void showMessage(String message, {bool success = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: success ? Colors.green.shade700 : Colors.red.shade700,
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    connectivitySubscription?.cancel();
    timer?.cancel();
    sosPollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = jornada;

    if (sosLocked) {
      return const _SosLockedScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xfff4f7fb),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadJornada,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _Header(
                    name: widget.nombres,
                    isOnline: isOnline,
                    syncing: syncing,
                    onLogout: logout,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        _StatsRow(
                          jornadasMes: jornadasMes,
                          horasTrabajadas: formatDuration(horasTrabajadas),
                        ),
                        const SizedBox(height: 18),
                        if (current == null || current.estado == 'COMPLETADA')
                          _NoJourneyCard(
                            jornadasMes: jornadasMes,
                            horasTrabajadas: formatDuration(horasTrabajadas),
                            completed: current?.estado == 'COMPLETADA',
                          )
                        else
                          _JourneyCard(
                            jornada: current,
                            driverName: widget.nombres,
                            elapsed: elapsed,
                            formatDuration: formatDuration,
                            formatDate: formatDate,
                            formatDateTime: formatDateTime,
                            onStart: iniciarTurno,
                            onFinish: finalizarTurno,
                          ),
                        const SizedBox(height: 18),
                        if (current != null && current.estado == 'EN_PROCESO')
                          _EmergencyActionsCard(
                            onSosCompleted: sendSosAlert,
                            onMechanicalAssistance:
                                openMechanicalAssistance,
                          ),
                        const SizedBox(height: 18),
                        const _RulesCard(),
                        const SizedBox(height: 18),
                        _HistorialNavCard(
                          token: widget.token,
                          nombres: widget.nombres,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _SosLockedScreen extends StatelessWidget {
  const _SosLockedScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xff7f1d1d),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock,
                color: Colors.white,
                size: 86,
              ),
              SizedBox(height: 24),
              Text(
                '¡ALERTA SOS!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Ubicación enviada al administrador. Sistema bloqueado por seguridad.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmergencyActionsCard extends StatelessWidget {
  final Future<void> Function() onSosCompleted;
  final VoidCallback onMechanicalAssistance;

  const _EmergencyActionsCard({
    required this.onSosCompleted,
    required this.onMechanicalAssistance,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SosPanicButton(
          enabled: true,
          onCompleted: onSosCompleted,
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onMechanicalAssistance,
            icon: const Icon(Icons.build_circle),
            label: const Text('Auxilio Mecánico'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xffea580c),
              side: const BorderSide(
                color: Color(0xffea580c),
                width: 1.4,
              ),
              padding: const EdgeInsets.symmetric(vertical: 15),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}


class _Header extends StatelessWidget {
  final String name;
  final bool isOnline;
  final bool syncing;
  final VoidCallback onLogout;

  const _Header({
    required this.name,
    required this.isOnline,
    required this.syncing,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOnline
              ? const [
                  Color(0xff1e3a8a),
                  Color(0xff2563eb),
                ]
              : const [
                  Color(0xff92400e),
                  Color(0xfff97316),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_shipping,
                color: Colors.white,
                size: 34,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Nanutech Driver',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: onLogout,
                tooltip: 'Cerrar sesión',
                icon: const Icon(
                  Icons.logout,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            'Hola, $name',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            syncing
                ? 'Sincronizando pendientes...'
                : isOnline
                    ? 'Conectado y listo para operar'
                    : 'Modo offline: tus acciones se guardarán localmente',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int jornadasMes;
  final String horasTrabajadas;

  const _StatsRow({
    required this.jornadasMes,
    required this.horasTrabajadas,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.calendar_month,
            title: 'Jornadas del Mes',
            value: jornadasMes.toString(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.schedule,
            title: 'Horas Trabajadas',
            value: horasTrabajadas,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xff2563eb)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoJourneyCard extends StatelessWidget {
  final int jornadasMes;
  final String horasTrabajadas;
  final bool completed;

  const _NoJourneyCard({
    required this.jornadasMes,
    required this.horasTrabajadas,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Icon(
            completed ? Icons.check_circle : Icons.assignment_late,
            size: 58,
            color: completed ? Colors.green : Colors.orange,
          ),
          const SizedBox(height: 12),
          const Text(
            'No tienes jornadas asignadas',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            completed
                ? 'Tu última jornada fue finalizada correctamente.'
                : 'Cuando tengas una jornada pendiente aparecerá aquí.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 14),
          Text('Jornadas del Mes: $jornadasMes'),
          Text('Horas Trabajadas: $horasTrabajadas'),
        ],
      ),
    );
  }
}

class _JourneyCard extends StatelessWidget {
  final JornadaModel jornada;
  final String driverName;
  final Duration elapsed;
  final String Function(Duration duration) formatDuration;
  final String Function(String? value) formatDate;
  final String Function(String? value) formatDateTime;
  final VoidCallback onStart;
  final VoidCallback onFinish;

  const _JourneyCard({
    required this.jornada,
    required this.driverName,
    required this.elapsed,
    required this.formatDuration,
    required this.formatDate,
    required this.formatDateTime,
    required this.onStart,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final isPending =
        jornada.estado == 'PENDIENTE' || jornada.estado == 'REGISTRADA';
    final isProgress = jornada.estado == 'EN_PROCESO';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusChip(status: jornada.estado),
          const SizedBox(height: 14),
          Text(
            '${jornada.origen} → ${jornada.destino}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          _InfoLine(
            icon: Icons.badge,
            label: 'Conductor',
            value: driverName,
          ),
          _InfoLine(
            icon: Icons.local_shipping,
            label: 'Placa',
            value: jornada.placa ?? 'No disponible',
          ),
          _InfoLine(
            icon: Icons.description,
            label: 'Contrato',
            value: jornada.contratoId ?? 'No disponible',
          ),
          _InfoLine(
            icon: Icons.event,
            label: 'Fecha',
            value: formatDate(jornada.fechaJornada),
          ),
          _InfoLine(
            icon: Icons.play_circle,
            label: 'Inicio',
            value: formatDateTime(jornada.horaInicio),
          ),
          _InfoLine(
            icon: Icons.stop_circle,
            label: 'Fin',
            value: formatDateTime(jornada.horaFin),
          ),
          if (isProgress) ...[
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Text(
                    'Tiempo Transcurrido',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatDuration(elapsed),
                    style: const TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff1e3a8a),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (isPending)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Iniciar Turno'),
              ),
            ),
          if (isProgress)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffdc2626),
                  foregroundColor: Colors.white,
                ),
                onPressed: onFinish,
                icon: const Icon(Icons.stop_circle),
                label: const Text('Finalizar Turno'),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'PENDIENTE' => Colors.orange,
      'REGISTRADA' => Colors.orange,
      'EN_PROCESO' => Colors.blue,
      'COMPLETADA' => Colors.green,
      _ => Colors.grey,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color.shade700,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xff2563eb)),
          const SizedBox(width: 8),
          SizedBox(
            width: 82,
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

class _RulesCard extends StatelessWidget {
  const _RulesCard();

  @override
  Widget build(BuildContext context) {
    final rules = [
      ('Seguridad', 'Verifica la unidad antes de partir.'),
      ('Puntualidad', 'Marca inicio y fin de turno correctamente.'),
      ('Inspección', 'Reporta fallas o incidencias.'),
      ('Responsabilidad', 'Mantén comunicación con operaciones.'),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xffeff6ff),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xffbfdbfe)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reglas Generales de NANU TECH',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          ...rules.map(
            (rule) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xff2563eb),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${rule.$1}: ',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(text: rule.$2),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tarjeta de navegación al Historial de Jornadas
// ─────────────────────────────────────────────────────────────────────────────

class _HistorialNavCard extends StatelessWidget {
  final String token;
  final String nombres;

  const _HistorialNavCard({
    required this.token,
    required this.nombres,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HistorialJornadasScreen(
            token: token,
            nombres: nombres,
          ),
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xff1e3a8a), Color(0xff2563eb)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff2563eb).withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.history_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Historial de Jornadas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Consulta tus jornadas completadas, métricas y estadísticas',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white70,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}