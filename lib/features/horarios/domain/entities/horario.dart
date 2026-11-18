class Horario {
  final String id;
  final String barberoId;
  final int dia; // 1 = lunes ... 7 = domingo
  final String horaInicio; // formato HH:mm
  final String horaFin; // formato HH:mm
  final bool activo;

  const Horario({
    required this.id,
    required this.barberoId,
    required this.dia,
    required this.horaInicio,
    required this.horaFin,
    this.activo = true,
  });

  Horario copyWith({
    int? dia,
    String? horaInicio,
    String? horaFin,
    bool? activo,
  }) {
    return Horario(
      id: id,
      barberoId: barberoId,
      dia: dia ?? this.dia,
      horaInicio: horaInicio ?? this.horaInicio,
      horaFin: horaFin ?? this.horaFin,
      activo: activo ?? this.activo,
    );
  }
}
