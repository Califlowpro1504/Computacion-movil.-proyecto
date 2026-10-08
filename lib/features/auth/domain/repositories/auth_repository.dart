import '../entities/user.dart';

abstract class AuthRepository {
  Future<AppUser> register({
    required String nombre,
    required String apellido,
    required String correo,
    required String telefono,
    required String password,
  });

  Future<AppUser> login({
    required String correo,
    required String password,
  });

  Future<void> logout();

  AppUser? get usuarioActual;
}