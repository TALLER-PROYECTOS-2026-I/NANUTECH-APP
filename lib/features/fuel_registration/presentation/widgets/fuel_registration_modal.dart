import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/fuel_receipt_service.dart';

class FuelRegistrationResult {
  final double galones;
  final double costoTotal;
  final double kilometrajeActual;
  final String fotoComprobanteUrl;

  FuelRegistrationResult({
    required this.galones,
    required this.costoTotal,
    required this.kilometrajeActual,
    required this.fotoComprobanteUrl,
  });
}

class FuelRegistrationModal extends StatefulWidget {
  final String placa;
  final bool isOnline;
  final double ultimoKilometraje;

  const FuelRegistrationModal({
    super.key,
    required this.placa,
    required this.isOnline,
    required this.ultimoKilometraje,
  });

  @override
  State<FuelRegistrationModal> createState() => _FuelRegistrationModalState();
}

class _FuelRegistrationModalState extends State<FuelRegistrationModal> {
  final galonesController = TextEditingController();
  final costoController = TextEditingController();
  final kilometrajeController = TextEditingController();

  final receiptService = FuelReceiptService();

  XFile? selectedFile;
  String? kilometrajeError;

  @override
  void dispose() {
    galonesController.dispose();
    costoController.dispose();
    kilometrajeController.dispose();
    super.dispose();
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red.shade700,
        content: Text(message),
      ),
    );
  }

  Future<void> pickImageFromGallery() async {
    try {
      final file = await receiptService.pickFromGallery();

      if (file == null) return;

      setState(() {
        selectedFile = file;
      });
    } catch (e) {
      showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> pickImageFromCamera() async {
    try {
      final file = await receiptService.pickFromCamera();

      if (file == null) return;

      setState(() {
        selectedFile = file;
      });
    } catch (e) {
      showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void confirm() {
    final galonesText = galonesController.text.trim();
    final costoText = costoController.text.trim();
    final kilometrajeText = kilometrajeController.text.trim();

    if (galonesText.isEmpty) {
      showError('El campo Galones es obligatorio para continuar');
      return;
    }

    if (costoText.isEmpty) {
      showError('El campo Costo Total es obligatorio para continuar');
      return;
    }

    if (kilometrajeText.isEmpty) {
      showError('El campo Kilometraje es obligatorio para continuar');
      return;
    }

    if (selectedFile == null) {
      showError(
        'El campo Foto del Comprobante es obligatorio para continuar',
      );
      return;
    }

    final galones = double.tryParse(galonesText.replaceAll(',', '.'));
    final costo = double.tryParse(costoText.replaceAll(',', '.'));
    final kilometraje = double.tryParse(kilometrajeText.replaceAll(',', '.'));

    if (galones == null || galones <= 0) {
      showError('El campo Galones es obligatorio para continuar');
      return;
    }

    if (costo == null || costo <= 0) {
      showError('El campo Costo Total es obligatorio para continuar');
      return;
    }

    if (kilometraje == null || kilometraje <= 0) {
      showError('El campo Kilometraje es obligatorio para continuar');
      return;
    }

    if (kilometraje <= widget.ultimoKilometraje) {
      setState(() {
        kilometrajeError =
            'El kilometraje debe ser mayor al último registro de la unidad';
      });
      return;
    }

    Navigator.pop(
      context,
      FuelRegistrationResult(
        galones: galones,
        costoTotal: costo,
        kilometrajeActual: kilometraje,
        fotoComprobanteUrl: selectedFile!.path,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 18,
          bottom: MediaQuery.of(context).viewInsets.bottom + 18,
        ),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Registrar Combustible',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                _InfoBox(
                  title: 'Unidad asociada',
                  value: widget.placa,
                  icon: Icons.local_shipping,
                ),
                const SizedBox(height: 10),
                _InfoBox(
                  title: 'Estado de red',
                  value: widget.isOnline ? 'Online' : 'Offline',
                  icon: widget.isOnline ? Icons.wifi : Icons.wifi_off,
                ),
                const SizedBox(height: 10),
                _InfoBox(
                  title: 'Último kilometraje',
                  value: widget.ultimoKilometraje.toStringAsFixed(1),
                  icon: Icons.speed,
                ),
                const SizedBox(height: 18),
                _NumberField(
                  controller: galonesController,
                  label: 'Galones *',
                  icon: Icons.local_gas_station,
                ),
                const SizedBox(height: 12),
                _NumberField(
                  controller: costoController,
                  label: 'Costo Total (Soles) *',
                  icon: Icons.payments,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: kilometrajeController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Kilometraje Actual *',
                    prefixIcon: const Icon(Icons.speed),
                    errorText: kilometrajeError,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onChanged: (_) {
                    if (kilometrajeError != null) {
                      setState(() {
                        kilometrajeError = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 18),
                const Text(
                  'Foto del Comprobante *',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (selectedFile == null)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: pickImageFromGallery,
                          icon: const Icon(Icons.photo),
                          label: const Text('Galería'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: pickImageFromCamera,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Cámara'),
                        ),
                      ),
                    ],
                  )
                else
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          File(selectedFile!.path),
                          width: double.infinity,
                          height: 160,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                selectedFile = null;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: confirm,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Confirmar Registro'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff2563eb),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;

  const _NumberField({
    required this.controller,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _InfoBox({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xffeff6ff),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffbfdbfe)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xff2563eb)),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}