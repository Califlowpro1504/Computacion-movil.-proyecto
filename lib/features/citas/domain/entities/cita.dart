class Cita {
  final String id;
  final String userId;
  final String barberiaId;
  final String barberoId;
  final String servicioId;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String estado;

  const Cita({
    required this.id,
    required this.userId,
    required this.barberiaId,
    required this.barberoId,
    required this.servicioId,
    required this.fechaInicio,
    required this.fechaFin,
    this.estado = 'pendiente',
  });

  Cita copyWith({DateTime? fechaInicio, DateTime? fechaFin, String? estado}) {
    return Cita(
      id: id,
      userId: userId,
      barberiaId: barberiaId,
      barberoId: barberoId,
      servicioId: servicioId,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      estado: estado ?? this.estado,
    );
  }
}
