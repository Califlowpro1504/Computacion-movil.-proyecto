import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:computacion_movil_proyecto/features/profile/presentation/screens/edit_profile_screen.dart';

const exampleProfile = <String, dynamic>{
  'nombre': 'Ana',
  'apellido': 'Prueba',
  'telefono': '3000000000',
};

Future<void> openEditor(
  WidgetTester tester, {
  required Future<void> Function(String, String, String) saveProfile,
  ValueChanged<bool?>? onResult,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute<bool>(
                  builder: (_) => EditProfileScreen(
                    profile: exampleProfile,
                    saveProfile: saveProfile,
                  ),
                ),
              );

              onResult?.call(result);
            },
            child: const Text('Abrir editor'),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('Abrir editor'));
  await tester.pumpAndSettle();
}

Future<void> tapSave(WidgetTester tester) async {
  final button = find.text('Guardar cambios');

  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pump();
}

void main() {
  testWidgets('muestra los datos actuales', (tester) async {
    await openEditor(
      tester,
      saveProfile: (_, _, _) async {},
    );

    final fields = tester
        .widgetList<TextFormField>(find.byType(TextFormField))
        .toList();

    expect(fields[0].controller!.text, 'Ana');
    expect(fields[1].controller!.text, 'Prueba');
    expect(fields[2].controller!.text, '3000000000');
  });

  testWidgets('impide guardar datos inválidos', (tester) async {
    var calls = 0;

    await openEditor(
      tester,
      saveProfile: (_, _, _) async {
        calls++;
      },
    );

    await tester.enterText(find.byType(TextFormField).at(0), '');
    await tester.enterText(find.byType(TextFormField).at(2), 'abc');

    await tapSave(tester);
    await tester.pumpAndSettle();

    expect(calls, 0);
    expect(find.byType(EditProfileScreen), findsOneWidget);
  });

  testWidgets('guarda los datos y regresa indicando éxito', (tester) async {
    List<String>? savedData;
    bool? result;

    await openEditor(
      tester,
      saveProfile: (nombre, apellido, telefono) async {
        savedData = [nombre, apellido, telefono];
      },
      onResult: (value) => result = value,
    );

    await tester.enterText(
      find.byType(TextFormField).at(0),
      '  Ana María  ',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      '  Gómez  ',
    );
    await tester.enterText(
      find.byType(TextFormField).at(2),
      '3111111111',
    );

    await tapSave(tester);
    await tester.pumpAndSettle();

    expect(savedData, ['Ana María', 'Gómez', '3111111111']);
    expect(result, isTrue);
    expect(find.byType(EditProfileScreen), findsNothing);
  });

  testWidgets('cancelar regresa sin guardar', (tester) async {
    var calls = 0;
    bool? result;

    await openEditor(
      tester,
      saveProfile: (_, _, _) async {
        calls++;
      },
      onResult: (value) => result = value,
    );

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Cambio sin guardar',
    );

    final cancelButton = find.text('Cancelar');

    await tester.ensureVisible(cancelButton);
    await tester.tap(cancelButton);
    await tester.pumpAndSettle();

    expect(calls, 0);
    expect(result, isFalse);
    expect(find.byType(EditProfileScreen), findsNothing);
  });

  testWidgets('conserva los datos tras un error y permite reintentar', (
    tester,
  ) async {
    var attempts = 0;

    await openEditor(
      tester,
      saveProfile: (_, _, _) async {
        attempts++;

        if (attempts == 1) {
          throw Exception('Error simulado');
        }
      },
    );

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Nombre actualizado',
    );

    await tapSave(tester);
    await tester.pumpAndSettle();

    expect(
      find.text('No pudimos guardar los cambios. Inténtalo nuevamente.'),
      findsOneWidget,
    );

    final nameField = tester.widget<TextFormField>(
      find.byType(TextFormField).at(0),
    );

    expect(nameField.controller!.text, 'Nombre actualizado');

    await tapSave(tester);
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.byType(EditProfileScreen), findsNothing);
  });

  testWidgets('bloquea envíos repetidos mientras guarda', (tester) async {
    final pendingSave = Completer<void>();
    var calls = 0;

    await openEditor(
      tester,
      saveProfile: (_, _, _) async {
        calls++;
        await pendingSave.future;
      },
    );

    await tapSave(tester);

    expect(find.text('Guardando…'), findsOneWidget);

    final saveButton = tester.widget<ElevatedButton>(
      find.byType(ElevatedButton),
    );

    expect(saveButton.onPressed, isNull);

    for (final field in tester.widgetList<TextFormField>(
      find.byType(TextFormField),
    )) {
      expect(field.enabled, isFalse);
    }

    await tester.tap(
      find.text('Guardando…'),
      warnIfMissed: false,
    );
    await tester.pump();

    expect(calls, 1);

    pendingSave.complete();
    await tester.pumpAndSettle();

    expect(find.byType(EditProfileScreen), findsNothing);
  });
}