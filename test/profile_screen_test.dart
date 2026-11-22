import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:computacion_movil_proyecto/features/profile/presentation/screens/profile_screen.dart';

const exampleProfile = <String, dynamic>{
  'nombre': 'Ana',
  'apellido': 'Prueba',
  'correo': 'prueba@example.com',
  'telefono': '3000000000',
};

Widget buildProfileApp(Future<Map<String, dynamic>?> Function() loader) {
  return MaterialApp(home: ProfileScreen(loadProfile: loader));
}

void main() {
  testWidgets('muestra los datos del perfil', (tester) async {
    await tester.pumpWidget(buildProfileApp(() async => exampleProfile));

    await tester.pumpAndSettle();

    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Prueba'), findsOneWidget);
    expect(find.text('prueba@example.com'), findsOneWidget);

    await tester.ensureVisible(find.text('Teléfono'));
    expect(find.text('3000000000'), findsOneWidget);
  });

  testWidgets('muestra carga mientras espera los datos', (tester) async {
    final result = Completer<Map<String, dynamic>?>();

    await tester.pumpWidget(buildProfileApp(() => result.future));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Ana'), findsNothing);

    result.complete(exampleProfile);
    await tester.pumpAndSettle();

    expect(find.text('Ana'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('informa cuando no existe el perfil', (tester) async {
    await tester.pumpWidget(buildProfileApp(() async => null));

    await tester.pumpAndSettle();

    expect(
      find.text('No encontramos tu perfil. Contacta al administrador.'),
      findsOneWidget,
    );
    expect(find.text('Ana'), findsNothing);
  });

  testWidgets('permite reintentar después de un error', (tester) async {
    var attempts = 0;

    await tester.pumpWidget(
      buildProfileApp(() async {
        attempts++;

        if (attempts == 1) {
          throw Exception('Error simulado');
        }

        return exampleProfile;
      }),
    );

    await tester.pumpAndSettle();

    expect(
      find.text('No pudimos cargar tu perfil. Revisa tu conexión.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('Ana'), findsOneWidget);
  });
}
