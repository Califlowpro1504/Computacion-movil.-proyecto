import 'package:flutter_test/flutter_test.dart';
import 'package:computacion_movil_proyecto/features/auth/presentation/validators/auth_validators.dart';

void main() {
  group('Contraseña de registro', () {
    test('rechaza valores vacíos y menos de 12 caracteres', () {
      for (final password in [null, '', 'sol y luna', 'abcdefghijk']) {
        expect(AuthValidators.validarPassword(password), isNotNull);
      }
    });

    test('acepta 12 caracteres y frases largas con espacios', () {
      for (final password in [
        'cielo bosque',
        'Mi bicicleta cruza el bosque cada domingo',
        '  cielo bosque  ',
        List.filled(30, 'cielo bosque ').join(),
      ]) {
        expect(AuthValidators.validarPassword(password), isNull);
      }
    });

    test('rechaza contraseñas comunes, espacios y repeticiones', () {
      for (final password in [
        '123456789012',
        'Password1234',
        '  PASSWORD1234  ',
        'qwerty123456',
        'contraseña123',
        'aaaaaaaaaaaa',
        '            ',
      ]) {
        expect(AuthValidators.validarPassword(password), isNotNull);
      }
    });

    test('cuenta caracteres Unicode y no unidades UTF-16', () {
      expect(AuthValidators.validarPassword('🌳🌞🚲🌻🌊🌙'), isNotNull);
    });
  });

  group('Confirmación exacta', () {
    test('requiere confirmación', () {
      expect(AuthValidators.validarConfirmacion(null, null), isNotNull);
      expect(AuthValidators.validarConfirmacion('', ''), isNotNull);
    });

    test('respeta espacios y mayúsculas', () {
      const password = '  cielo bosque  ';
      expect(AuthValidators.validarConfirmacion(password, password), isNull);
      expect(AuthValidators.validarConfirmacion(password, password.trim()), isNotNull);
      expect(AuthValidators.validarConfirmacion(password, password.toUpperCase()), isNotNull);
    });
  });

  group('Inicio de sesión', () {
    test('requiere una contraseña sin aplicar las reglas nuevas', () {
      expect(AuthValidators.validarPasswordLogin(null), isNotNull);
      expect(AuthValidators.validarPasswordLogin(''), isNotNull);
      expect(AuthValidators.validarPasswordLogin('abc123'), isNull);
      expect(AuthValidators.validarPasswordLogin('password1234'), isNull);
    });
  });
}
