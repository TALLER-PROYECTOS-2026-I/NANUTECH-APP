import 'package:flutter/material.dart';

import '../../services/licencia_api_service.dart';
import '../../domain/licencia_model.dart';

import '../../../authentication/services/session_service.dart';

class LicenciaScreen extends StatefulWidget {
  const LicenciaScreen({super.key});

  @override
  State<LicenciaScreen> createState() => _LicenciaScreenState();
}

class _LicenciaScreenState extends State<LicenciaScreen> {
  final api = LicenciaApiService();
  final sessionService = SessionService();

  final numeroController = TextEditingController();
  final categoriaController = TextEditingController();
  final fechaEmisionController = TextEditingController();
  final fechaVencimientoController = TextEditingController();
  final autoridadController = TextEditingController();

  bool loading = true;
  bool saving = false;

  String token = '';

  @override
  void initState() {
    super.initState();
    cargarLicencia();
  }

  Future<void> cargarLicencia() async {
    try {
      final session = await sessionService.getSession();

      if (session == null) {
        throw Exception('Sesión no encontrada');
      }

      token = session['token'];

      final LicenciaModel licencia = await api.obtenerLicencia(token: token);

      numeroController.text = licencia.numeroLicencia;
      categoriaController.text = licencia.categoria;
      fechaEmisionController.text = licencia.fechaEmision;
      fechaVencimientoController.text = licencia.fechaVencimiento;
      autoridadController.text = licencia.autoridadEmisora;

      setState(() {
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));

      setState(() {
        loading = false;
      });
    }
  }

  Future<void> guardar() async {
    try {
      setState(() {
        saving = true;
      });

      await api.actualizarLicencia(
        token: token,
        numeroLicencia: numeroController.text,
        categoria: categoriaController.text,
        fechaEmision: fechaEmisionController.text,
        fechaVencimiento: fechaVencimientoController.text,
        autoridadEmisora: autoridadController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Licencia actualizada correctamente')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    numeroController.dispose();
    categoriaController.dispose();
    fechaEmisionController.dispose();
    fechaVencimientoController.dispose();
    autoridadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Licencia')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: numeroController,
              decoration: const InputDecoration(
                labelText: 'Número de Licencia',
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: categoriaController,
              decoration: const InputDecoration(labelText: 'Categoría'),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: fechaEmisionController,
              decoration: const InputDecoration(labelText: 'Fecha Emisión'),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: fechaVencimientoController,
              decoration: const InputDecoration(labelText: 'Fecha Vencimiento'),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: autoridadController,
              decoration: const InputDecoration(labelText: 'Autoridad Emisora'),
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saving ? null : guardar,
                child: saving
                    ? const CircularProgressIndicator()
                    : const Text('Guardar Cambios'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
