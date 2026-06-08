import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../service/licencia_service.dart';

/// Pantalla de gestión de la Licencia de Conducir (HU18)
/// Permite editar categoría y fecha de vencimiento
class LicenciaScreen extends StatefulWidget {
  final String? numeroLicencia;
  final String? categoriaActual;
  final String? fechaEmision;
  final String? fechaVencimientoActual;

  const LicenciaScreen({
    Key? key,
    this.numeroLicencia,
    this.categoriaActual,
    this.fechaEmision,
    this.fechaVencimientoActual,
  }) : super(key: key);

  @override
  State<LicenciaScreen> createState() => _LicenciaScreenState();
}

class _LicenciaScreenState extends State<LicenciaScreen> {
  // ==================== Variables ====================
  
  final LicenciaService _service = LicenciaService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late TextEditingController _categoriaController;
  late TextEditingController _fechaVencimientoController;

  bool _cargando = false;

  // Categorías disponibles según regulación MTC Perú
  final List<String> _categorias = [
    'A-I',
    'A-IIa',
    'A-IIb',
    'A-IIIa',
    'A-IIIb',
    'A-IV',
  ];

  String? _categoriaSeleccionada;

  // ==================== Ciclo de vida ====================

  @override
  void initState() {
    super.initState();
    _categoriaController = TextEditingController(text: widget.categoriaActual ?? '');
    _fechaVencimientoController = TextEditingController(text: widget.fechaVencimientoActual ?? '');
    _categoriaSeleccionada = widget.categoriaActual;
  }

  @override
  void dispose() {
    _categoriaController.dispose();
    _fechaVencimientoController.dispose();
    super.dispose();
  }

  // ==================== Métodos ====================

  /// Abre el selector de fecha
  Future<void> _seleccionarFecha() async {
    final fechaActual = _parsearFecha(_fechaVencimientoController.text);
    
    final fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: fechaActual ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (fechaSeleccionada != null) {
      _fechaVencimientoController.text = DateFormat('dd/MM/yyyy').format(fechaSeleccionada);
    }
  }

  /// Parsea una fecha en formato DD/MM/YYYY
  DateTime? _parsearFecha(String fecha) {
    try {
      final partes = fecha.split('/');
      if (partes.length != 3) return null;
      return DateTime(
        int.parse(partes[2]),
        int.parse(partes[1]),
        int.parse(partes[0]),
      );
    } catch (e) {
      return null;
    }
  }

  /// Verifica si la licencia está vencida
  bool _esVencida(String fecha) {
    try {
      final fechaVencimiento = _parsearFecha(fecha);
      if (fechaVencimiento == null) return false;
      return DateTime.now().isAfter(fechaVencimiento);
    } catch (e) {
      return false;
    }
  }

  /// Calcula días vencido
  int _diasVencido(String fecha) {
    try {
      final fechaVencimiento = _parsearFecha(fecha);
      if (fechaVencimiento == null) return 0;
      final diferencia = DateTime.now().difference(fechaVencimiento).inDays;
      return diferencia > 0 ? diferencia : 0;
    } catch (e) {
      return 0;
    }
  }

  /// Guarda los cambios en el servidor
  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);

    try {
      await _service.actualizarLicencia(
        categoria: _categoriaSeleccionada ?? widget.categoriaActual ?? '',
        fechaVencimiento: _fechaVencimientoController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Licencia actualizada correctamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _cargando = false);
    }
  }

  // ==================== Validaciones ====================

  String? _validarFecha(String? valor) {
    if (valor == null || valor.isEmpty) {
      return 'Campo obligatorio';
    }

    try {
      final partes = valor.split('/');
      if (partes.length != 3) return 'Formato inválido (DD/MM/YYYY)';

      final dia = int.parse(partes[0]);
      final mes = int.parse(partes[1]);
      final anio = int.parse(partes[2]);

      if (dia < 1 || dia > 31 || mes < 1 || mes > 12) {
        return 'Fecha inválida';
      }

      DateTime(anio, mes, dia);
      return null;
    } catch (e) {
      return 'Fecha inválida';
    }
  }

  // ==================== Build ====================

  @override
  Widget build(BuildContext context) {
    final esVencida = _esVencida(_fechaVencimientoController.text);
    final diasVencido = _diasVencido(_fechaVencimientoController.text);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Licencia'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================== Alerta de vencimiento ====================
            if (esVencida)
              Container(
                padding: const EdgeInsets.all(16.0),
                margin: const EdgeInsets.only(bottom: 24.0),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red, width: 2),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock,
                      color: Colors.red,
                      size: 32.0,
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Licencia Vencida',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            'Inhabilitado para operar',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            'Venció hace $diasVencido ${diasVencido == 1 ? 'día' : 'días'}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16.0),
                margin: const EdgeInsets.only(bottom: 24.0),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green, width: 2),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 32.0,
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Licencia Vigente',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            'Vence: ${_fechaVencimientoController.text}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // ==================== Formulario ====================
            Text(
              'Datos de Licencia',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Categoría
                  DropdownButtonFormField<String>(
                    value: _categoriaSeleccionada,
                    decoration: InputDecoration(
                      labelText: 'Categoría',
                      prefixIcon: const Icon(Icons.category),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    items: _categorias.map((categoria) {
                      return DropdownMenuItem<String>(
                        value: categoria,
                        child: Text(categoria),
                      );
                    }).toList(),
                    onChanged: (valor) {
                      setState(() => _categoriaSeleccionada = valor);
                    },
                    validator: (valor) {
                      if (valor == null || valor.isEmpty) {
                        return 'Selecciona una categoría';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),

                  // Fecha de vencimiento
                  TextFormField(
                    controller: _fechaVencimientoController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Fecha de Vencimiento',
                      prefixIcon: const Icon(Icons.date_range),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: _seleccionarFecha,
                      ),
                    ),
                    onTap: _seleccionarFecha,
                    validator: _validarFecha,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32.0),

            // ==================== Botones ====================
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _cargando ? null : () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _cargando ? null : _guardar,
                    icon: _cargando
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                        : const Icon(Icons.save),
                    label: Text(_cargando ? 'Guardando...' : 'Guardar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
