class Barbero {
  final String id;
  final String barberiaId;
  final String nombre;
  final String apellido;
  final String descripcion;
  final String fotografia;
  final bool activo;

  const Barbero({
    required this.id,
    required this.barberiaId,
    required this.nombre,
    required this.apellido,
    this.descripcion = '',
    this.fotografia = '',
    this.activo = true,
  });

  Barbero copyWith({
    String? nombre,
    String? apellido,
    String? descripcion,
    String? fotografia,
    bool? activo,
  }) {
    return Barbero(
      id: id,
      barberiaId: barberiaId,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      descripcion: descripcion ?? this.descripcion,
      fotografia: fotografia ?? this.fotografia,
      activo: activo ?? this.activo,
    );
  }
}
