class Servicio {
  final String id;
  final String barberiaId;
  final String nombre;
  final String descripcion;
  final double precio;
  final int duracionMin;
  final bool activo;

  const Servicio({
    required this.id,
    required this.barberiaId,
    required this.nombre,
    this.descripcion = '',
    required this.precio,
    required this.duracionMin,
    this.activo = true,
  });

  Servicio copyWith({
    String? nombre,
    String? descripcion,
    double? precio,
    int? duracionMin,
    bool? activo,
  }) {
    return Servicio(
      id: id,
      barberiaId: barberiaId,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      precio: precio ?? this.precio,
      duracionMin: duracionMin ?? this.duracionMin,
      activo: activo ?? this.activo,
    );
  }
}
