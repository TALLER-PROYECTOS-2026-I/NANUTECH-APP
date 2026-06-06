class JornadaHistorialModel {
  final String id;
  final String codigo;
  final String placa;
  final String marca;
  final String modelo;
  final String origen;
  final String destino;
  final String fecha;
  final String horaInicio;
  final String horaFin;
  final double kmRecorridos;
  final String estado;
  final String duracionFormateada;
  final String observaciones;

  JornadaHistorialModel({
    required this.id,
    required this.codigo,
    required this.placa,
    required this.marca,
    required this.modelo,
    required this.origen,
    required this.destino,
    required this.fecha,
    required this.horaInicio,
    required this.horaFin,
    required this.kmRecorridos,
    required this.estado,
    required this.duracionFormateada,
    required this.observaciones,
  });

  factory JornadaHistorialModel.fromJson(Map<String, dynamic> json) {
    return JornadaHistorialModel(
      id: (json['id'] ?? '').toString(),
      codigo: (json['codigo'] ?? '').toString(),
      placa: (json['placa'] ?? 'N/A').toString(),
      marca: (json['marca'] ?? 'N/A').toString(),
      modelo: (json['modelo'] ?? 'N/A').toString(),
      origen: (json['origen'] ?? 'No definido').toString(),
      destino: (json['destino'] ?? 'No definido').toString(),
      fecha: (json['fecha'] ?? '').toString(),
      horaInicio: (json['hora_inicio'] ?? '').toString(),
      horaFin: (json['hora_fin'] ?? '').toString(),
      kmRecorridos: _parseDouble(json['km_recorridos']),
      estado: (json['estado'] ?? '').toString().toUpperCase(),
      duracionFormateada: (json['duracion_formateada'] ?? '0h 0m').toString(),
      observaciones: (json['observaciones'] ?? '').toString(),
    );
  }

  bool get tieneObservaciones =>
      observaciones.isNotEmpty && observaciones.trim().isNotEmpty;

  String get rutaFormateada => '$origen → $destino';

  String get placaModelo {
    if (placa == 'N/A' || placa.isEmpty) return 'N/A';
    return '$placa ($marca $modelo)';
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}