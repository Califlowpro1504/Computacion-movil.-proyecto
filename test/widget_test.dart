import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:computacion_movil_proyecto/features/auth/presentation/screens/session_gate.dart';
import 'package:computacion_movil_proyecto/features/home/presentation/screens/home_screen.dart';

void main() {
  testWidgets('login, inicio y cierre siguen los cambios de sesión', (tester) async {
    final changes = StreamController<bool>();
    addTearDown(changes.close);
    await tester.pumpWidget(MaterialApp(
      home: SessionGate(
        sessionChanges: changes.stream,
        initiallySignedIn: false,
        signedOutBuilder: (_) => const Text('Formulario de acceso'),
        signedInBuilder: (_) => HomeScreen(
          email: 'prueba@example.com',
          onSignOut: () async => changes.add(false),
        ),
      ),
    ));
    expect(find.text('Formulario de acceso'), findsOneWidget);
    changes.add(true);
    await tester.pumpAndSettle();
    expect(find.text('Sesión iniciada'), findsOneWidget);
    expect(find.text('Formulario de acceso'), findsNothing);
    await tester.ensureVisible(find.text('Cerrar sesión'));
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Formulario de acceso'), findsOneWidget);
    expect(find.text('Sesión iniciada'), findsNothing);
  });

  testWidgets('una sesión restaurada muestra directamente el inicio', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: SessionGate(
        sessionChanges: const Stream<bool>.empty(),
        initiallySignedIn: true,
        signedOutBuilder: (_) => const Text('Acceso'),
        signedInBuilder: (_) => const Text('Inicio'),
      ),
    ));
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Acceso'), findsNothing);
  });

  testWidgets('un cierre fallido muestra error y permite reintentar', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(MaterialApp(home: HomeScreen(
      email: null,
      onSignOut: () async {
        attempts++;
        throw Exception('Fallo de conexión');
      },
    )));
    await tester.ensureVisible(find.text('Cerrar sesión'));
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('No pudimos cerrar la sesión. Inténtalo de nuevo.'), findsOneWidget);
    await tester.ensureVisible(find.text('Cerrar sesión'));
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
  });
}
