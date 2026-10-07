import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _client = Supabase.instance.client;

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
        email: correo,
        password: password,
      );

      final userId = response.user?.id;
      if (userId == null) {
        throw Exception('No se pudo crear la cuenta.');
      }

      await _client.from('profiles').insert({
        'id': userId,
        'nombre': nombre,
        'apellido': apellido,
        'telefono': telefono,
        'rol': 'cliente',
        'terminos_aceptados': true,
      });

      return AppUser(
        id: userId,
        nombre: nombre,
        apellido: apellido,
        correo: correo,
        telefono: telefono,
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
        email: correo,
        password: password,
      );

      final userId = response.user?.id;
      if (userId == null) {
        throw Exception('No se pudo iniciar sesión.');
      }

      final data = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      return AppUser(
        id: userId,
        nombre: data['nombre'],
        apellido: data['apellido'],
        correo: correo,
        telefono: data['telefono'],
        rol: data['rol'],
        terminosAceptados: data['terminos_aceptados'],
        fechaRegistro: DateTime.parse(data['fecha_registro']),
        activo: data['activo'],
      );
    } on AuthException catch (_) {
      throw Exception('Correo o contraseña incorrectos.');
    }
  }

  @override
  Future<void> logout() async {
    await _client.auth.signOut();
  }

  @override
  AppUser? get usuarioActual {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return null;
  }
}