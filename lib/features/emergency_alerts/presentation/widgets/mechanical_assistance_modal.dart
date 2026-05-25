import 'package:flutter/material.dart';

/// Modal de Auxilio Mecánico para HU21.
///
/// Este componente muestra:
/// - Explicación del servicio.
/// - Avisos importantes.
/// - Contacto de emergencia.
/// - Selector de tipo de falla.
/// - Campo opcional de detalle.
/// - Botón para confirmar la solicitud.
///
/// La lógica de envío al backend NO está aquí.
/// Este widget solo recoge los datos y los devuelve al Dashboard.
class MechanicalAssistanceResult {
  final String tipoFalla;
  final String detalle;

  MechanicalAssistanceResult({
    required this.tipoFalla,
    required this.detalle,
  });
}

class MechanicalAssistanceModal extends StatefulWidget {
  const MechanicalAssistanceModal({super.key});

  @override
  State<MechanicalAssistanceModal> createState() =>
      _MechanicalAssistanceModalState();
}

class _MechanicalAssistanceModalState extends State<MechanicalAssistanceModal> {
  /// Lista exigida por HU21 para clasificar la falla mecánica.
  final List<String> fallas = const [
    'Falla de Motor',
    'Pinchazo/Llantas',
    'Fallo en frenos',
    'Problema eléctrico',
    'Falta de combustible',
    'Problema de transmisión',
    'Otro',
  ];

  String? selectedFalla;
  final detalleController = TextEditingController();

  @override
  void dispose() {
    detalleController.dispose();
    super.dispose();
  }

  void confirmarAuxilio() {
    if (selectedFalla == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: const Text(
            'Selecciona el tipo de falla antes de solicitar auxilio.',
          ),
        ),
      );
      return;
    }

    Navigator.pop(
      context,
      MechanicalAssistanceResult(
        tipoFalla: selectedFalla!,
        detalle: detalleController.text.trim(),
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

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xffffedd5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.build_circle,
                        color: Color(0xffea580c),
                        size: 34,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Auxilio Mecánico',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                const _SectionTitle(
                  icon: Icons.info_outline,
                  title: '¿Cómo funciona el servicio?',
                ),

                const Text(
                  'Selecciona el tipo de falla que presenta la unidad. '
                  'El sistema enviará tu ubicación actual y la información '
                  'de la jornada al administrador para gestionar asistencia.',
                  style: TextStyle(height: 1.4),
                ),

                const SizedBox(height: 18),

                const _SectionTitle(
                  icon: Icons.warning_amber_rounded,
                  title: 'Avisos Importantes',
                ),

                const _BulletText(
                  text:
                      'Estaciona la unidad en una zona segura si es posible.',
                ),
                const _BulletText(
                  text:
                      'No intentes reparar fallas críticas sin autorización.',
                ),
                const _BulletText(
                  text:
                      'Mantén comunicación con operaciones mientras llega el soporte.',
                ),

                const SizedBox(height: 18),

                const _SectionTitle(
                  icon: Icons.phone_in_talk,
                  title: 'Contacto de Emergencia',
                ),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xffeff6ff),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xffbfdbfe),
                    ),
                  ),
                  child: const Text(
                    'Central de Operaciones NANU TECH\n'
                    'Teléfono: 999 000 111\n'
                    'Horario: Atención inmediata durante jornada activa',
                    style: TextStyle(height: 1.4),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Selecciona la falla',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 10),

                DropdownButtonFormField<String>(
                  value: selectedFalla,
                  items: fallas
                      .map(
                        (falla) => DropdownMenuItem(
                          value: falla,
                          child: Text(falla),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedFalla = value;
                    });
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.car_repair),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    hintText: 'Tipo de falla',
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: detalleController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Detalle opcional',
                    hintText: 'Ejemplo: ruido en el motor, llanta dañada...',
                    prefixIcon: const Icon(Icons.notes),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: confirmarAuxilio,
                    icon: const Icon(Icons.send),
                    label: const Text(
                      'Confirmar y Solicitar Auxilio',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffea580c),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

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

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xff2563eb),
            size: 21,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletText extends StatelessWidget {
  final String text;

  const _BulletText({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}