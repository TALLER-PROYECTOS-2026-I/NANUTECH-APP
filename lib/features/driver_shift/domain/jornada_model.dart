class JornadaModel {
  final String id;
  final String conductorId;
  final String? unidadId;
  final String origen;
  final String destino;
  final String estado;
  final String? placa;
  final String? contratoId;
  final String? fechaJornada;
  final String? horaInicio;
  final String? horaFin;
  final String? observaciones;
  final int? duracionTotalSegundos;

  JornadaModel({
    required this.id,
    required this.conductorId,
    this.unidadId,
    required this.origen,
    required this.destino,
    required this.estado,
    this.placa,
    this.contratoId,
    this.fechaJornada,
    this.horaInicio,
    this.horaFin,
    this.observaciones,
    this.duracionTotalSegundos,
  });

  factory JornadaModel.fromJson(Map<String, dynamic> json) {
    return JornadaModel(
      id: (json['id'] ?? '').toString(),
      conductorId: (json['conductor_id'] ?? '').toString(),
      unidadId: (json['unidad_id'] ?? json['camion_id'])?.toString(),
      origen: (json['origen'] ?? 'No definido').toString(),
      destino: (json['destino'] ?? 'No definido').toString(),
      estado: (json['estado'] ?? '').toString().toUpperCase(),
      placa: (json['placa'] ?? json['unidad_placa'] ?? 'No disponible').toString(),
      contratoId: (json['contrato_id'] ?? 'No disponible').toString(),
      fechaJornada: json['fecha_jornada']?.toString(),
      horaInicio: json['hora_inicio']?.toString(),
      horaFin: json['hora_fin']?.toString(),
      observaciones: json['observaciones']?.toString(),
      duracionTotalSegundos: json['duracion_total_segundos'] is int
          ? json['duracion_total_segundos']
          : int.tryParse('${json['duracion_total_segundos'] ?? ''}'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conductor_id': conductorId,
      'unidad_id': unidadId,
      'origen': origen,
      'destino': destino,
      'estado': estado,
      'placa': placa,
      'contrato_id': contratoId,
      'fecha_jornada': fechaJornada,
      'hora_inicio': horaInicio,
      'hora_fin': horaFin,
      'observaciones': observaciones,
      'duracion_total_segundos': duracionTotalSegundos,
    };
  }
}