import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nanutech_driver_app/features/historial_jornadas/presentation/widgets/metrica_card_widget.dart';

void main() {
  group('MetricaCardWidget', () {
    testWidgets('renderiza título, valor e icono', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MetricaCardWidget(
              titulo: 'Jornadas',
              valor: '12',
              icono: Icons.calendar_month,
              color: Colors.blue,
            ),
          ),
        ),
      );

      expect(find.text('Jornadas'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_month), findsOneWidget);
    });

    testWidgets('aplica color al icono', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MetricaCardWidget(
              titulo: 'Horas',
              valor: '97.6h',
              icono: Icons.schedule,
              color: Colors.green,
            ),
          ),
        ),
      );

      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.schedule));
      expect(iconWidget.color, Colors.green);
    });

    testWidgets('renderiza correctamente con valor decimal',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MetricaCardWidget(
              titulo: 'Kilómetros',
              valor: '4850.5 km',
              icono: Icons.straighten,
              color: Colors.purple,
            ),
          ),
        ),
      );

      expect(find.text('Kilómetros'), findsOneWidget);
      expect(find.text('4850.5 km'), findsOneWidget);
    });
  });
}