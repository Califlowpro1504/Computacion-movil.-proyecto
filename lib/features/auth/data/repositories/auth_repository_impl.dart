import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _client = Supabase.instance.client;

  AppUser _crearAppUser(Map<String, dynamic> data, String correo) {
    return AppUser(
      id: data['id'] as String,
      nombre: data['nombre'] as String,
      apellido: data['apellido'] as String,
      correo: correo,
      telefono: data['telefono'] as String,
      rol: data['rol'] as String,
      terminosAceptados: data['terminos_aceptados'] as bool,
      fechaRegistro:
          DateTime.tryParse(data['fecha_registro']?.toString() ?? '') ??
          DateTime.now(),
      activo: data['activo'] as bool? ?? true,
      esAdmin: data['es_admin'] as bool? ?? false,
    );
  }

  Future<AppUser> _obtenerPerfil(String userId, String correo) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();

    return _crearAppUser(data, correo);
  }

  @override
  Future<AppUser> register({
    required String nombre,
    required String apellido,
    required String correo,
    required String telefono,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: correo.trim(),
        password: password,
        data: {
          'nombre': nombre.trim(),
          'apellido': apellido.trim(),
          'telefono': telefono.trim(),
        },
      );

      final user = response.user;

      if (user == null) {
        throw Exception('No se pudo crear la cuenta.');
      }

      return AppUser(
        id: user.id,
        nombre: nombre.trim(),
        apellido: apellido.trim(),
        correo: correo.trim(),
        telefono: telefono.trim(),
        rol: 'cliente',
        terminosAceptados: true,
        fechaRegistro: DateTime.now(),
      );
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('already registered') ||
          e.message.toLowerCase().contains('already exists')) {
        throw Exception('Este correo ya se encuentra registrado.');
      }

      throw Exception(e.message);
    }
  }

  @override
  Future<AppUser> login({
    required String correo,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: correo.trim(),
        password: password,
      );

      final user = response.user;

      if (user == null) {
        throw Exception('No se pudo iniciar sesión.');
      }

      final perfil = await _obtenerPerfil(user.id, user.email ?? correo.trim());

      if (!perfil.activo) {
        await _client.auth.signOut(scope: SignOutScope.local);
        throw Exception('Esta cuenta se encuentra desactivada.');
      }

      return perfil;
    } on AuthException {
      throw Exception('Correo o contraseña incorrectos.');
    } on PostgrestException {
      await _client.auth.signOut(scope: SignOutScope.local);
      throw Exception(
        'No se pudo consultar tu perfil. Contacta con el administrador.',
      );
    }
  }

  @override
  Future<void> logout() async {
    await _client.auth.signOut();
  }

  @override
  Future<AppUser?> get usuarioActual async {
    final user = _client.auth.currentUser;

    if (user == null) {
      return null;
    }

    try {
      final perfil = await _obtenerPerfil(user.id, user.email ?? '');

      if (!perfil.activo) {
        await _client.auth.signOut(scope: SignOutScope.local);
        return null;
      }

      return perfil;
    } on PostgrestException {
      await _client.auth.signOut(scope: SignOutScope.local);
      return null;
    }
  }
}
