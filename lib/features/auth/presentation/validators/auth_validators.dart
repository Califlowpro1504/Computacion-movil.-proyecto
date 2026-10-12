class AuthValidators {
  static String? validarNombre(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre es obligatorio.';
    }
    return null;
  }

  static String? validarApellido(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El apellido es obligatorio.';
    }
    return null;
  }

  static String? validarCorreo(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa un correo electrónico.';
    }
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value)) {
      return 'Ingresa un correo electrónico válido.';
    }
    return null;
  }

  static String? validarTelefono(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa un número de teléfono válido.';
    }
    final regex = RegExp(r'^[0-9]{7,15}$');
    if (!regex.hasMatch(value)) {
      return 'Ingresa un número de teléfono válido.';
    }
    return null;
  }

  static const longitudMinimaPassword = 12;

  // Lista local limitada; no sustituye la protección del servidor.
  static const _passwordsComunes = {
    '123456789012',
    '1234567890123456',
    'password1234',
    'password12345',
    'qwerty123456',
    'qwerty123456789',
    'contraseña123',
    'contrasena123',
  };

  static String? validarPasswordLogin(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es obligatoria.';
    }
    return null;
  }

  static String? validarPassword(String? value) {
    final error = validarPasswordLogin(value);
    if (error != null) return error;
    final password = value!;
    if (password.runes.length < longitudMinimaPassword) {
      return 'Usa al menos 12 caracteres.';
    }
    // Normalizar solo para detectar patrones; nunca modificar lo enviado.
    final patron = password.trim().toLowerCase();
    if (patron.isEmpty ||
        patron.runes.toSet().length == 1 ||
        _passwordsComunes.contains(patron)) {
      return 'Esta contraseña es muy predecible. Usa una frase única.';
    }
    return null;
  }

  static String? validarConfirmacion(String? password, String? confirmacion) {
    if (confirmacion == null || confirmacion.isEmpty) {
      return 'Confirma tu contraseña.';
    }
    if (confirmacion != password) {
      return 'Las contraseñas no coinciden.';
    }
    return null;
  }

  static String? validarTerminos(bool aceptado) {
    if (!aceptado) {
      return 'Debes aceptar los términos y condiciones.';
    }
    return null;
  }
}