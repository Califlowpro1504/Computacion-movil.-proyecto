import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:computacion_movil_proyecto/features/auth/presentation/screens/profile_access_gate.dart';
import 'package:computacion_movil_proyecto/features/auth/presentation/screens/role_selection_screen.dart';

const validProfile = <String, dynamic>{
  'id': 'usuario-prueba',
  'rol': 'cliente',
  'activo': true,
};

Widget buildTestApp({
  required Future<Map<String, dynamic>?> Function() loadProfile,
  AccessRole? selectedRole = AccessRole.cliente,
  Future<void> Function()? onSignOut,
}) {
  return MaterialApp(
    home: ProfileAccessGate(
      userId: 'usuario-prueba',
      selectedRole: selectedRole,
      loadProfile: loadProfile,
      onSignOut: onSignOut ?? (() async {}),
      authorizedBuilder: (_) => const Scaffold(body: Text('Inicio autorizado')),
    ),
  );
}

void main() {
  testWidgets('permite entrar a un cliente activo', (tester) async {
    await tester.pumpWidget(
      buildTestApp(loadProfile: () async => validProfile),
    );

    await tester.pumpAndSettle();

    expect(find.text('Inicio autorizado'), findsOneWidget);
  });

  testWidgets('verifica una sesión restaurada sin selección previa', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestApp(selectedRole: null, loadProfile: () async => validProfile),
    );

    await tester.pumpAndSettle();

    expect(find.text('Inicio autorizado'), findsOneWidget);
  });

  for (final role in [AccessRole.barbero, AccessRole.administrador]) {
    testWidgets('bloquea al cliente que selecciona ${role.name}', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(selectedRole: role, loadProfile: () async => validProfile),
      );

      await tester.pumpAndSettle();

      expect(find.text('Inicio autorizado'), findsNothing);
      expect(
        find.text(
          'Tu cuenta es Cliente. Regresa al acceso y selecciona Cliente.',
        ),
        findsOneWidget,
      );
    });
  }

  final blockedProfiles = <String, Map<String, dynamic>?>{
    'perfil inexistente': null,
    'cuenta inactiva': {...validProfile, 'activo': false},
    'perfil de otra cuenta': {...validProfile, 'id': 'otra-cuenta'},
    'rol no configurado': {...validProfile, 'rol': 'rol-desconocido'},
  };

  for (final entry in blockedProfiles.entries) {
    testWidgets('bloquea ${entry.key}', (tester) async {
      await tester.pumpWidget(
        buildTestApp(loadProfile: () async => entry.value),
      );

      await tester.pumpAndSettle();

      expect(find.text('Inicio autorizado'), findsNothing);
      expect(find.text('Volver al acceso'), findsOneWidget);
    });
  }

  testWidgets('espera la consulta antes de mostrar el inicio', (tester) async {
    final result = Completer<Map<String, dynamic>?>();

    await tester.pumpWidget(buildTestApp(loadProfile: () => result.future));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Inicio autorizado'), findsNothing);

    result.complete(validProfile);
    await tester.pumpAndSettle();

    expect(find.text('Inicio autorizado'), findsOneWidget);
  });

  testWidgets('bloquea una consulta fallida y permite reintentar', (
    tester,
  ) async {
    var attempts = 0;

    await tester.pumpWidget(
      buildTestApp(
        loadProfile: () async {
          attempts++;

          if (attempts == 1) {
            throw Exception('Fallo simulado');
          }

          return validProfile;
        },
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Inicio autorizado'), findsNothing);

    final retryButton = find.text('Reintentar comprobación');
    await tester.ensureVisible(retryButton);
    await tester.tap(retryButton);
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('Inicio autorizado'), findsOneWidget);
  });

  testWidgets('volver al acceso solicita cerrar la sesión', (tester) async {
    var signOutRequested = false;

    await tester.pumpWidget(
      buildTestApp(
        selectedRole: AccessRole.administrador,
        loadProfile: () async => validProfile,
        onSignOut: () async {
          signOutRequested = true;
        },
      ),
    );

    await tester.pumpAndSettle();

    final backButton = find.text('Volver al acceso');
    await tester.ensureVisible(backButton);
    await tester.tap(backButton);
    await tester.pumpAndSettle();

    expect(signOutRequested, isTrue);
  });
}
