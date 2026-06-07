/// Helpers para parsear campos que la API puede devolver como String o num.
double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

/// Modelo de una jornada completada del historial.
class HistorialJornadaModel {
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
  final String? observaciones;

  const HistorialJornadaModel({
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
    this.observaciones,
  });

  factory HistorialJornadaModel.fromJson(Map<String, dynamic> json) {
    return HistorialJornadaModel(
      id: json['id']?.toString() ?? '',
      codigo: json['codigo']?.toString() ?? '',
      placa: json['placa']?.toString() ?? '',
      marca: json['marca']?.toString() ?? '',
      modelo: json['modelo']?.toString() ?? '',
      origen: json['origen']?.toString() ?? '',
      destino: json['destino']?.toString() ?? '',
      fecha: json['fecha']?.toString() ?? '',
      horaInicio: json['hora_inicio']?.toString() ?? '',
      horaFin: json['hora_fin']?.toString() ?? '',
      kmRecorridos: _toDouble(json['km_recorridos']),
      estado: json['estado']?.toString() ?? 'COMPLETADA',
      duracionFormateada: json['duracion_formateada']?.toString() ?? '',
      observaciones: json['observaciones']?.toString(),
    );
  }

  /// Devuelve el código corto visible en la tarjeta.
  String get codigoCorto {
    if (codigo.isNotEmpty && codigo.length <= 12) return codigo.toUpperCase();
    return 'HIST-${id.substring(0, 4).toUpperCase()}';
  }
}

/// Modelo de métricas del conductor.
class HistorialMetricasModel {
  final int totalJornadas;
  final double horasTrabajadas;
  final double kmRecorridos;
  final int conObservaciones;

  const HistorialMetricasModel({
    required this.totalJornadas,
    required this.horasTrabajadas,
    required this.kmRecorridos,
    required this.conObservaciones,
  });

  factory HistorialMetricasModel.fromJson(Map<String, dynamic> json) {
    return HistorialMetricasModel(
      totalJornadas: _toInt(json['total_jornadas']),
      horasTrabajadas: _toDouble(json['horas_trabajadas']),
      kmRecorridos: _toDouble(json['km_recorridos']),
      conObservaciones: _toInt(json['con_observaciones']),
    );
  }

  static HistorialMetricasModel empty() {
    return const HistorialMetricasModel(
      totalJornadas: 0,
      horasTrabajadas: 0,
      kmRecorridos: 0,
      conObservaciones: 0,
    );
  }
}
