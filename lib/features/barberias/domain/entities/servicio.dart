class Servicio {
  final String id;
  final String barberiaId;
  final String nombre;
  final String descripcion;
  final int duracionMinutos;
  final double precio;
  final bool activo;

  const Servicio({
    required this.id,
    required this.barberiaId,
    required this.nombre,
    required this.descripcion,
    required this.duracionMinutos,
    required this.precio,
    required this.activo,
  });
}
