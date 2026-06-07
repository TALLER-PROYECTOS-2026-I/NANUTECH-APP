import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../services/license_api_service.dart';

class LicenseScreen extends StatefulWidget {
  final String conductorId;
  final String token;
  final VoidCallback onBackToDashboard;
  final VoidCallback onOpenMenu;

  const LicenseScreen({
    super.key,
    required this.conductorId,
    required this.token,
    required this.onBackToDashboard,
    required this.onOpenMenu,
  });

  @override
  State<LicenseScreen> createState() => _LicenseScreenState();
}

class _LicenseScreenState extends State<LicenseScreen> {
  final api = LicenseApiService();
  final scrollController = ScrollController();

  final numeroController = TextEditingController();
  final autoridadController = TextEditingController();

  bool loading = true;
  bool saving = false;
  bool editing = false;

  String? error;
  String? categoria;
  DateTime? fechaEmision;
  DateTime? fechaVencimiento;

  String originalNumero = '';
  String originalCategoria = 'A-I';
  String originalAutoridad = '';
  DateTime? originalFechaEmision;
  DateTime? originalFechaVencimiento;

  String? numeroError;
  String? categoriaError;
  String? fechaEmisionError;
  String? fechaVencimientoError;
  String? autoridadError;

  final categorias = const [
    'A-I',
    'A-IIa',
    'A-IIb',
    'A-IIIa',
    'A-IIIb',
    'A-IIIc',
  ];

  @override
  void initState() {
    super.initState();
    loadLicense();
  }

  @override
  void dispose() {
    numeroController.dispose();
    autoridadController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> loadLicense() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final response = await api.getLicense(
        token: widget.token,
        conductorId: widget.conductorId,
      );

      final data = response['data'] ?? {};

      final licenciaData = data['licencia'] ?? data;

      originalNumero =
          '${licenciaData['numero_licencia'] ?? licenciaData['licencia'] ?? ''}';

      originalCategoria =
          '${licenciaData['categoria_licencia'] ?? licenciaData['categoria'] ?? 'A-I'}';

      originalAutoridad =
          '${licenciaData['autoridad_emisora'] ?? licenciaData['autoridad'] ?? 'MTC'}';

      originalFechaEmision = parseDate(
        licenciaData['fecha_emision_licencia'] ??
            licenciaData['fecha_emision'],
      );

      originalFechaVencimiento = parseDate(
        licenciaData['fecha_vencimiento_licencia'] ??
            licenciaData['fecha_vencimiento'],
      );

      restoreOriginalValues();

      setState(() {
        loading = false;
      });
    } on DioException catch (e) {
      setState(() {
        loading = false;
        error = e.response?.data?['message'] ??
            'Error de conexión. No se pudo cargar la licencia.';
      });
    } catch (_) {
      setState(() {
        loading = false;
        error = 'Error de conexión. No se pudo cargar la licencia.';
      });
    }
  }

  DateTime? parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  String formatDate(DateTime? value) {
    if (value == null) return '-';

    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  String toApiDate(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }

  void restoreOriginalValues() {
    numeroController.text = originalNumero;
    autoridadController.text = originalAutoridad;
    categoria = categorias.contains(originalCategoria)
        ? originalCategoria
        : 'A-I';
    fechaEmision = originalFechaEmision;
    fechaVencimiento = originalFechaVencimiento;

    clearErrors();
  }

  void clearErrors() {
    numeroError = null;
    categoriaError = null;
    fechaEmisionError = null;
    fechaVencimientoError = null;
    autoridadError = null;
  }

  int categoryRank(String value) {
    return categorias.indexOf(value);
  }

  bool validateFields({bool showMessages = true}) {
    clearErrors();

    final numero = numeroController.text.trim();
    final autoridad = autoridadController.text.trim();
    final now = DateTime.now();

    if (numero.isEmpty) {
      numeroError = 'El campo Número de Licencia es obligatorio.';
    }

    if (categoria == null || categoria!.isEmpty) {
      categoriaError = 'El campo Categoría es obligatorio.';
    }

    if (fechaEmision == null) {
      fechaEmisionError = 'El campo Fecha de Emisión es obligatorio.';
    }

    if (fechaVencimiento == null) {
      fechaVencimientoError =
          'El campo Fecha de Vencimiento es obligatorio.';
    }

    if (autoridad.isEmpty) {
      autoridadError = 'El campo Autoridad Emisora es obligatorio.';
    }

    if (fechaEmision != null &&
        fechaVencimiento != null &&
        !fechaVencimiento!.isAfter(fechaEmision!)) {
      fechaVencimientoError =
          'La fecha de vencimiento debe ser posterior a la fecha de emisión.';
    }

    if (fechaVencimiento != null) {
      final today = DateTime(now.year, now.month, now.day);
      final vencimiento = DateTime(
        fechaVencimiento!.year,
        fechaVencimiento!.month,
        fechaVencimiento!.day,
      );

      if (vencimiento.isBefore(today) || vencimiento.isAtSameMomentAs(today)) {
        fechaVencimientoError =
            'Error: La fecha de vencimiento ingresada se encuentra expirada';
      }
    }

    if (categoria != null &&
        categoryRank(categoria!) < categoryRank(originalCategoria)) {
      categoriaError =
          'Error: No se permite registrar una categoría vehicular inferior a la actual';
    }

    setState(() {});

    final valid = numeroError == null &&
        categoriaError == null &&
        fechaEmisionError == null &&
        fechaVencimientoError == null &&
        autoridadError == null;

    if (!valid && showMessages) {
      showMessage(
        numeroError ??
            categoriaError ??
            fechaEmisionError ??
            fechaVencimientoError ??
            autoridadError ??
            'Datos inválidos.',
      );
    }

    return valid;
  }

  Future<void> pickDate({
    required bool isEmission,
  }) async {
    if (!editing) return;

    final initial = isEmission
        ? fechaEmision ?? DateTime.now()
        : fechaVencimiento ?? DateTime.now();

    final result = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2045),
    );

    if (result == null) return;

    setState(() {
      if (isEmission) {
        fechaEmision = result;
      } else {
        fechaVencimiento = result;
      }
    });

    validateFields(showMessages: false);
  }

  void startEditing() {
    setState(() {
      editing = true;
      clearErrors();
    });
  }

  void cancelEditing() {
    setState(() {
      restoreOriginalValues();
      editing = false;
    });
  }

  Future<void> saveLicense() async {
    if (!validateFields()) return;

    setState(() {
      saving = true;
    });

    try {
      final response = await api.updateLicense(
        token: widget.token,
        conductorId: widget.conductorId,
        numeroLicencia: numeroController.text.trim(),
        categoria: categoria!,
        fechaEmision: toApiDate(fechaEmision!),
        fechaVencimiento: toApiDate(fechaVencimiento!),
        autoridadEmisora: autoridadController.text.trim(),
      );

      originalNumero = numeroController.text.trim();
      originalCategoria = categoria!;
      originalFechaEmision = fechaEmision;
      originalFechaVencimiento = fechaVencimiento;
      originalAutoridad = autoridadController.text.trim();

      setState(() {
        editing = false;
        saving = false;
      });

      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );

      showMessage(
        response['message'] ?? 'Licencia actualizada correctamente.',
        success: true,
      );
    } on DioException catch (e) {
      setState(() {
        saving = false;
      });

      showMessage(
        e.response?.data?['message'] ??
            'No se pudo actualizar la licencia.',
      );
    } catch (_) {
      setState(() {
        saving = false;
      });

      showMessage('No se pudo actualizar la licencia.');
    }
  }

  int daysRemaining() {
    if (fechaVencimiento == null) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final vencimiento = DateTime(
      fechaVencimiento!.year,
      fechaVencimiento!.month,
      fechaVencimiento!.day,
    );

    return vencimiento.difference(today).inDays;
  }

  LicenseBannerData bannerData() {
    final days = daysRemaining();

    if (days <= 0) {
      return LicenseBannerData(
        color: Colors.red.shade700,
        icon: Icons.error,
        message: 'Alerta: Licencia Vencida. Inhabilitado para operar',
      );
    }

    if (days <= 30) {
      return LicenseBannerData(
        color: Colors.orange.shade700,
        icon: Icons.warning,
        message: 'Atención: Licencia próxima a vencer - $days días restantes',
      );
    }

    return LicenseBannerData(
      color: Colors.green.shade700,
      icon: Icons.check_circle,
      message: 'Licencia Vigente - $days días restantes',
    );
  }

  void showMessage(String message, {bool success = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: success ? Colors.green.shade700 : Colors.red.shade700,
        content: Text(message),
      ),
    );
  }

  bool fieldValid(String? error, String value) {
    return editing && value.trim().isNotEmpty && error == null;
  }

  @override
  Widget build(BuildContext context) {
    final banner = bannerData();

    return Scaffold(
      backgroundColor: const Color(0xfff4f7fb),
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? _LicenseErrorState(
                    message: error!,
                    onRetry: loadLicense,
                    onBack: widget.onBackToDashboard,
                  )
                : ListView(
    controller: scrollController,
    padding: EdgeInsets.zero,
    children: [
      _DriverSectionHeader(
        title: 'Mi Licencia',
        subtitle: 'Consulta y actualización de licencia',
        onOpenMenu: widget.onOpenMenu,
        onRetry: loadLicense,
      ),
      const SizedBox(height: 16),
      _LicenseBanner(data: banner),
      const SizedBox(height: 18),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: _FieldCard(
          child: TextField(
            controller: numeroController,
            enabled: editing,
            decoration: InputDecoration(
              labelText: 'Número de Licencia *',
              errorText: numeroError,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: _FieldCard(
          child: DropdownButtonFormField<String>(
            value: categoria,
            decoration: InputDecoration(
              labelText: 'Categoría *',
              errorText: categoriaError,
              border: const OutlineInputBorder(),
            ),
            items: categorias
                .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                .toList(),
            onChanged: editing
                ? (value) {
                    setState(() => categoria = value);
                    validateFields(showMessages: false);
                  }
                : null,
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: _DateBox(
          title: 'Fecha de Emisión *',
          value: formatDate(fechaEmision),
          error: fechaEmisionError,
          enabled: editing,
          onTap: () => pickDate(isEmission: true),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: _DateBox(
          title: 'Fecha de Vencimiento *',
          value: formatDate(fechaVencimiento),
          error: fechaVencimientoError,
          enabled: editing,
          onTap: () => pickDate(isEmission: false),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: _FieldCard(
          child: TextField(
            controller: autoridadController,
            enabled: editing,
            decoration: InputDecoration(
              labelText: 'Autoridad Emisora *',
              errorText: autoridadError,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
      ),
      const SizedBox(height: 14),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: !editing
            ? ElevatedButton.icon(
                onPressed: startEditing,
                icon: const Icon(Icons.edit),
                label: const Text('Editar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff2563eb),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              )
            : Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: saving ? null : saveLicense,
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar Licencia'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff16a34a),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: saving ? null : cancelEditing,
                    icon: const Icon(Icons.close),
                    label: const Text('Cancelar'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ],
              ),
      ),
      const SizedBox(height: 22),
    ],
  ),
      ),
    );
  }
}

class LicenseBannerData {
  final Color color;
  final IconData icon;
  final String message;

  LicenseBannerData({
    required this.color,
    required this.icon,
    required this.message,
  });
}


class _LicenseBanner extends StatelessWidget {
  final LicenseBannerData data;

  const _LicenseBanner({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: data.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: data.color),
      ),
      child: Row(
        children: [
          Icon(data.icon, color: data.color, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              data.message,
              style: TextStyle(
                color: data.color,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  final Widget child;

  const _FieldCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
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
      child: child,
    );
  }
}

class _DateBox extends StatelessWidget {
  final String title;
  final String value;
  final String? error;
  final bool enabled;
  final VoidCallback onTap;

  const _DateBox({
    required this.title,
    required this.value,
    required this.error,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _FieldCard(
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: title,
            errorText: error,
            border: const OutlineInputBorder(),
            suffixIcon: enabled
                ? const Icon(Icons.calendar_month)
                : const Icon(Icons.lock_outline),
          ),
          child: Text(value),
        ),
      ),
    );
  }
}

class _LicenseErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  const _LicenseErrorState({
    required this.message,
    required this.onRetry,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 54, color: Colors.red),
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
            TextButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Volver al Dashboard'),
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