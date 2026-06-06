import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nanutech_driver_app/features/historial_jornadas/data/models/jornada_historial_model.dart';
import 'package:nanutech_driver_app/features/historial_jornadas/presentation/widgets/jornada_card_widget.dart';

void main() {
  group('JornadaCardWidget', () {
    testWidgets('renderiza placa, ruta y duración', (tester) async {
      final jornada = JornadaHistorialModel(
        id: 'jor-1',
        codigo: 'shift_test_001',
        placa: 'ABC-123',
        marca: 'Volvo',
        modelo: 'FH16',
        origen: 'Lima',
        destino: 'Arequipa',
        fecha: '2026-05-28',
        horaInicio: '08:00 AM',
        horaFin: '04:30 PM',
        kmRecorridos: 450.5,
        estado: 'COMPLETADA',
        duracionFormateada: '8h 30m',
        observaciones: '',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JornadaCardWidget(jornada: jornada),
          ),
        ),
      );

      expect(find.text('ABC-123'), findsOneWidget);
      expect(find.text('Lima → Arequipa'), findsOneWidget);
      expect(find.text('8h 30m'), findsOneWidget);
      expect(find.text('450.5 km'), findsOneWidget);
      expect(find.text('COMPLETADA'), findsOneWidget);
    });

    testWidgets('muestra borde izquierdo naranja si tiene observaciones',
        (tester) async {
      final jornada = JornadaHistorialModel(
        id: 'jor-1',
        codigo: 'shift_test_001',
        placa: 'ABC-123',
        marca: 'Volvo',
        modelo: 'FH16',
        origen: 'Lima',
        destino: 'Arequipa',
        fecha: '2026-05-28',
        horaInicio: '08:00 AM',
        horaFin: '04:30 PM',
        kmRecorridos: 450.5,
        estado: 'COMPLETADA',
        duracionFormateada: '8h 30m',
        observaciones: 'Observación de prueba',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JornadaCardWidget(jornada: jornada),
          ),
        ),
      );

      expect(find.text('Observaciones del Conductor'), findsOneWidget);
      expect(find.text('Observación de prueba'), findsOneWidget);
      expect(find.text('Con observaciones'), findsOneWidget);
    });

    testWidgets('no muestra observaciones cuando están vacías',
        (tester) async {
      final jornada = JornadaHistorialModel(
        id: 'jor-1',
        codigo: 'shift_test_001',
        placa: 'ABC-123',
        marca: 'Volvo',
        modelo: 'FH16',
        origen: 'Lima',
        destino: 'Arequipa',
        fecha: '2026-05-28',
        horaInicio: '08:00 AM',
        horaFin: '04:30 PM',
        kmRecorridos: 450.5,
        estado: 'COMPLETADA',
        duracionFormateada: '8h 30m',
        observaciones: '',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JornadaCardWidget(jornada: jornada),
          ),
        ),
      );

      expect(find.text('Observaciones del Conductor'), findsNothing);
      expect(find.text('Con observaciones'), findsNothing);
    });

    testWidgets('muestra código de jornada en footer', (tester) async {
      final jornada = JornadaHistorialModel(
        id: 'jor-1',
        codigo: 'shift_test_maria_002',
        placa: 'ABC-123',
        marca: 'Volvo',
        modelo: 'FH16',
        origen: 'Lima',
        destino: 'Arequipa',
        fecha: '2026-05-28',
        horaInicio: '08:00 AM',
        horaFin: '04:30 PM',
        kmRecorridos: 450.5,
        estado: 'COMPLETADA',
        duracionFormateada: '8h 30m',
        observaciones: '',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JornadaCardWidget(jornada: jornada),
          ),
        ),
      );

      expect(find.text('ID: shift_test_maria_002'), findsOneWidget);
    });
  });
}