import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProfileService {
  AuthProfileService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<Map<String, dynamic>?> obtenerPerfilDeAcceso() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      return null;
    }

    final profile = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (profile == null) return null;
    return {
      for (final key in ['id', 'rol', 'activo', 'es_admin']) key: profile[key],
    };
  }
}
