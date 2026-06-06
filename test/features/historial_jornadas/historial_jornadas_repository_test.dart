import 'package:flutter_test/flutter_test.dart';

import 'package:nanutech_driver_app/features/historial_jornadas/data/models/jornada_historial_model.dart';
import 'package:nanutech_driver_app/features/historial_jornadas/data/models/metricas_historial_model.dart';

void main() {
  group('JornadaHistorialModel', () {
    test('fromJson parsea correctamente todos los campos', () {
      final json = {
        'id': 'jor-uuid-1',
        'codigo': 'shift_test_maria_002',
        'placa': 'XYZ-789',
        'marca': 'Mercedes',
        'modelo': 'Actros',
        'origen': 'Cusco',
        'destino': 'Tacna',
        'fecha': '2026-05-20',
        'hora_inicio': '06:00 AM',
        'hora_fin': '02:30 PM',
        'km_recorridos': 520.0,
        'estado': 'COMPLETADA',
        'duracion_formateada': '8h 30m',
        'observaciones': 'Ruta sin incidentes',
      };

      final model = JornadaHistorialModel.fromJson(json);

      expect(model.id, 'jor-uuid-1');
      expect(model.codigo, 'shift_test_maria_002');
      expect(model.placa, 'XYZ-789');
      expect(model.marca, 'Mercedes');
      expect(model.modelo, 'Actros');
      expect(model.origen, 'Cusco');
      expect(model.destino, 'Tacna');
      expect(model.fecha, '2026-05-20');
      expect(model.kmRecorridos, 520.0);
      expect(model.estado, 'COMPLETADA');
      expect(model.duracionFormateada, '8h 30m');
      expect(model.observaciones, 'Ruta sin incidentes');
    });

    test('tieneObservaciones retorna true cuando hay texto', () {
      final model = JornadaHistorialModel.fromJson({
        'id': '1',
        'codigo': 'test',
        'placa': 'ABC',
        'marca': 'Test',
        'modelo': 'T',
        'origen': 'A',
        'destino': 'B',
        'fecha': '2026-05-20',
        'hora_inicio': '08:00 AM',
        'hora_fin': '04:00 PM',
        'km_recorridos': 100.0,
        'estado': 'COMPLETADA',
        'duracion_formateada': '8h 0m',
        'observaciones': 'Algo',
      });

      expect(model.tieneObservaciones, true);
    });

    test('tieneObservaciones retorna false cuando está vacío', () {
      final model = JornadaHistorialModel.fromJson({
        'id': '1',
        'codigo': 'test',
        'placa': 'ABC',
        'marca': 'Test',
        'modelo': 'T',
        'origen': 'A',
        'destino': 'B',
        'fecha': '2026-05-20',
        'hora_inicio': '08:00 AM',
        'hora_fin': '04:00 PM',
        'km_recorridos': 100.0,
        'estado': 'COMPLETADA',
        'duracion_formateada': '8h 0m',
        'observaciones': '',
      });

      expect(model.tieneObservaciones, false);
    });

    test('rutaFormateada retorna "origen → destino"', () {
      final model = JornadaHistorialModel.fromJson({
        'id': '1',
        'codigo': 'test',
        'placa': 'ABC',
        'marca': 'Test',
        'modelo': 'T',
        'origen': 'Lima',
        'destino': 'Arequipa',
        'fecha': '2026-05-20',
        'hora_inicio': '08:00 AM',
        'hora_fin': '04:00 PM',
        'km_recorridos': 100.0,
        'estado': 'COMPLETADA',
        'duracion_formateada': '8h 0m',
        'observaciones': '',
      });

      expect(model.rutaFormateada, 'Lima → Arequipa');
    });

    test('fromJson maneja valores nulos correctamente', () {
      final json = <String, dynamic>{
        'id': null,
        'codigo': null,
        'placa': null,
        'marca': null,
        'modelo': null,
        'origen': null,
        'destino': null,
        'fecha': null,
        'hora_inicio': null,
        'hora_fin': null,
        'km_recorridos': null,
        'estado': null,
        'duracion_formateada': null,
        'observaciones': null,
      };

      final model = JornadaHistorialModel.fromJson(json);

      expect(model.id, '');
      expect(model.codigo, '');
      expect(model.placa, 'N/A');
      expect(model.origen, 'No definido');
      expect(model.destino, 'No definido');
      expect(model.kmRecorridos, 0.0);
    });
  });

  group('MetricasHistorialModel', () {
    test('fromJson parsea correctamente', () {
      final json = {
        'total_jornadas': 5,
        'horas_trabajadas': 40.5,
        'km_recorridos': 2000.0,
        'con_observaciones': 2,
      };

      final model = MetricasHistorialModel.fromJson(json);

      expect(model.totalJornadas, 5);
      expect(model.horasTrabajadas, 40.5);
      expect(model.kmRecorridos, 2000.0);
      expect(model.conObservaciones, 2);
    });

    test('vacio retorna ceros', () {
      final model = MetricasHistorialModel.vacio();

      expect(model.totalJornadas, 0);
      expect(model.horasTrabajadas, 0.0);
      expect(model.kmRecorridos, 0.0);
      expect(model.conObservaciones, 0);
    });

    test('fromJson maneja strings numéricos', () {
      final json = {
        'total_jornadas': '12',
        'horas_trabajadas': '97.6',
        'km_recorridos': '4850.5',
        'con_observaciones': '4',
      };

      final model = MetricasHistorialModel.fromJson(json);

      expect(model.totalJornadas, 12);
      expect(model.horasTrabajadas, 97.6);
      expect(model.kmRecorridos, 4850.5);
      expect(model.conObservaciones, 4);
    });
  });
}