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
    final regex = RegExp(r'^[\w.+-]+@([\w-]+\.)+[\w-]{2,}$');
if (!regex.hasMatch(value.trim())) {
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

    // Registro: contraseña robusta (mínimo 8, una mayúscula y un número)
  static String? validarPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es obligatoria.';
    }
    final cumple = value.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(value) &&
        RegExp(r'[0-9]').hasMatch(value);
    if (!cumple) {
      return 'La contraseña no cumple con los requisitos establecidos.';
    }
    return null;
  }

  // Login: solo verifica que no esté vacía
  static String? validarPasswordLogin(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es obligatoria.';
    }
    return null;
  }

  static String? validarConfirmacion(String? password, String? confirmacion) {
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