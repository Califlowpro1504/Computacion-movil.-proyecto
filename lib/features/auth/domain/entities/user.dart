class AppUser {
  final String id; // uid de Firebase Auth
  final String nombre;
  final String apellido;
  final String correo;
  final String telefono;
  final String rol; // 'cliente', 'comercio', 'admin'
  final bool terminosAceptados;
  final DateTime fechaRegistro;
  final bool activo; // para RF-031: admin puede activar/suspender

  const AppUser({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.correo,
    required this.telefono,
    required this.rol,
    required this.terminosAceptados,
    required this.fechaRegistro,
    this.activo = true,
  });
}