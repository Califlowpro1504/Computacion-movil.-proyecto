import 'package:supabase_flutter/supabase_flutter.dart';

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
}
