import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/data/services/auth_email_redirect.dart';

class ProfileService {
  ProfileService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<Map<String, dynamic>?> obtenerMiPerfil() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw StateError('No hay una sesión iniciada.');
    }

    final profile = await _client
        .from('profiles')
        .select('id, nombre, apellido, telefono')
        .eq('id', user.id)
        .maybeSingle();

    if (profile == null) {
      return null;
    }

    return {...profile, 'correo': user.email ?? ''};
  }

  Future<void> solicitarCambioCorreo(String correo) async {
    await _client.auth.updateUser(
      UserAttributes(email: correo),
      emailRedirectTo: authEmailRedirect,
    );
  }

  Future<void> actualizarMisDatos({
    required String nombre,
    required String apellido,
    required String telefono,
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw StateError('No hay una sesión iniciada.');
    }

    final cleanNombre = nombre.trim();
    final cleanApellido = apellido.trim();
    final cleanTelefono = telefono.trim();

    if (cleanNombre.isEmpty ||
        cleanApellido.isEmpty ||
        !RegExp(r'^[0-9]{7,15}$').hasMatch(cleanTelefono)) {
      throw ArgumentError('Los datos del perfil no son válidos.');
    }

    final updated = await _client
        .from('profiles')
        .update({
          'nombre': cleanNombre,
          'apellido': cleanApellido,
          'telefono': cleanTelefono,
        })
        .eq('id', user.id)
        .select('id')
        .maybeSingle();

    if (updated == null) {
      throw StateError('No se pudo actualizar el perfil.');
    }
  }
}
