import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:computacion_movil_proyecto/core/theme/app_theme.dart';
import 'package:computacion_movil_proyecto/features/auth/presentation/screens/role_selection_screen.dart';

void main() {
  testWidgets('muestra las tres opciones sin seleccionar un rol', (
    tester,
  ) async {
    AccessRole? selectedRole;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: RoleSelectionScreen(
          onRoleSelected: (role) => selectedRole = role,
        ),
      ),
    );

    expect(find.text('Cliente'), findsOneWidget);
    expect(find.text('Barbero'), findsOneWidget);
    expect(find.text('Administrador'), findsOneWidget);
    expect(selectedRole, isNull);
  });

  final options = {
    'Cliente': AccessRole.cliente,
    'Barbero': AccessRole.barbero,
    'Administrador': AccessRole.administrador,
  };

  for (final option in options.entries) {
    testWidgets('pulsar ${option.key} comunica la opción correcta', (
      tester,
    ) async {
      AccessRole? selectedRole;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: RoleSelectionScreen(
            onRoleSelected: (role) => selectedRole = role,
          ),
        ),
      );

      final cardTitle = find.text(option.key);

      await tester.ensureVisible(cardTitle);
      await tester.tap(cardTitle);
      await tester.pump();

      expect(selectedRole, option.value);
    });
  }
}