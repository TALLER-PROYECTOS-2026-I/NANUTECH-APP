class LicenciaModel {
  final String numeroLicencia;
  final String categoria;
  final String fechaEmision;
  final String fechaVencimiento;
  final String autoridadEmisora;

  LicenciaModel({
    required this.numeroLicencia,
    required this.categoria,
    required this.fechaEmision,
    required this.fechaVencimiento,
    required this.autoridadEmisora,
  });

  factory LicenciaModel.fromJson(Map<String, dynamic> json) {
    return LicenciaModel(
      numeroLicencia: json['numero_licencia']?.toString() ?? '',
      categoria: json['categoria']?.toString() ?? '',
      fechaEmision: json['fecha_emision']?.toString() ?? '',
      fechaVencimiento: json['fecha_vencimiento']?.toString() ?? '',
      autoridadEmisora: json['autoridad_emisora']?.toString() ?? '',
    );
  }
}
