class MetricasHistorialModel {
  final int totalJornadas;
  final double horasTrabajadas;
  final double kmRecorridos;
  final int conObservaciones;

  MetricasHistorialModel({
    required this.totalJornadas,
    required this.horasTrabajadas,
    required this.kmRecorridos,
    required this.conObservaciones,
  });

  factory MetricasHistorialModel.fromJson(Map<String, dynamic> json) {
    return MetricasHistorialModel(
      totalJornadas: _parseInt(json['total_jornadas']),
      horasTrabajadas: _parseDouble(json['horas_trabajadas']),
      kmRecorridos: _parseDouble(json['km_recorridos']),
      conObservaciones: _parseInt(json['con_observaciones']),
    );
  }

  factory MetricasHistorialModel.vacio() {
    return MetricasHistorialModel(
      totalJornadas: 0,
      horasTrabajadas: 0.0,
      kmRecorridos: 0.0,
      conObservaciones: 0,
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}