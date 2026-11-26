import 'dart:async';

import 'package:computacion_movil_proyecto/features/auth/presentation/screens/password_recovery_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'valida el correo y muestra una confirmación sin revelar cuentas',
    (tester) async {
      final sent = Completer<void>();
      final emails = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: PasswordRecoveryScreen.request(
            onSubmit: (email) {
              emails.add(email);
              return sent.future;
            },
          ),
        ),
      );
      final button = find.text('Enviar enlace');
      await tester.tap(button);
      expect(emails, isEmpty);
      await tester.enterText(
        find.byType(TextFormField),
        ' prueba@example.com ',
      );
      await tester.tap(button);
      await tester.pump();
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(emails, ['prueba@example.com']);
      sent.complete();
      await tester.pumpAndSettle();
      expect(find.textContaining('Si la cuenta existe'), findsOneWidget);
    },
  );

  testWidgets(
    'confirma la contraseña exacta y permite reintentar tras un error',
    (tester) async {
      final passwords = <String>[];
      const password = ' una frase segura ';
      await tester.pumpWidget(
        MaterialApp(
          home: PasswordRecoveryScreen.reset(
            onSubmit: (value) async {
              passwords.add(value);
              if (passwords.length == 1) throw StateError('fallo simulado');
            },
            onCancel: () async {},
          ),
        ),
      );
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), password);
      await tester.enterText(fields.at(1), password.trim());
      await tester.tap(find.text('Guardar contraseña'));
      await tester.pumpAndSettle();
      expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
      expect(passwords, isEmpty);

      await tester.enterText(fields.at(1), password);
      await tester.tap(find.text('Guardar contraseña'));
      await tester.pumpAndSettle();
      expect(find.textContaining('No pudimos completar'), findsOneWidget);
      await tester.tap(find.text('Guardar contraseña'));
      await tester.pumpAndSettle();
      expect(passwords, [password, password]);
    },
  );
}
