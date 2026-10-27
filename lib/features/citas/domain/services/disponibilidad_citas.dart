import '../entities/cita.dart';
import '../../../horarios/domain/entities/horario.dart';

class DisponibilidadCitas {
  const DisponibilidadCitas();

  /// Comprueba si una cita cabe dentro de un horario activo.
  bool cabeEnHorario({
    required DateTime inicio,
    required int duracionMinutos,
    required List<Horario> horarios,
  }) {
    if (duracionMinutos <= 0 || !inicio.isAfter(DateTime.now())) {
      return false;
    }

    // DateTime.weekday usa 1 = lunes y 7 = domingo.
    final dia = inicio.weekday;
    final minutoInicio = inicio.hour * 60 + inicio.minute;
    final minutoFin = minutoInicio + duracionMinutos;

    return horarios.any((horario) {
      if (!horario.activo || horario.dia != dia) {
        return false;
      }

      final partesInicio = horario.horaInicio.split(':');
      final partesFin = horario.horaFin.split(':');

      final inicioHorario =
          int.parse(partesInicio[0]) * 60 + int.parse(partesInicio[1]);
      final finHorario = int.parse(partesFin[0]) * 60 + int.parse(partesFin[1]);

      return minutoInicio >= inicioHorario && minutoFin <= finHorario;
    });
  }

  /// Comprueba si el intervalo se cruza con otra cita ocupada.
  bool tieneCruce({
    required DateTime inicio,
    required DateTime fin,
    required List<Cita> citas,
  }) {
    if (!fin.isAfter(inicio)) return true;

    return citas.any((cita) {
      if (cita.estado != 'pendiente' && cita.estado != 'confirmada') {
        return false;
      }

      // Los intervalos [inicio, fin) permiten citas consecutivas.
      return inicio.isBefore(cita.fechaFin) && cita.fechaInicio.isBefore(fin);
    });
  }
}
