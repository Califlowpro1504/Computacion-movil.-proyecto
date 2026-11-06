import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/cita.dart';
import '../../domain/services/disponibilidad_citas.dart';
import '../../../horarios/domain/entities/horario.dart';

class CitaRepository {
  final SupabaseClient _client;
  final DisponibilidadCitas _disponibilidad;

  CitaRepository({
    SupabaseClient? client,
    this._disponibilidad = const DisponibilidadCitas(),
  }) : _client = client ?? Supabase.instance.client;

  static const String _tabla = 'citas';

  Cita _fromMap(Map<String, dynamic> m) {
    return Cita(
      id: m['id'].toString(),
      userId: m['user_id'].toString(),
      barberiaId: m['barberia_id'].toString(),
      barberoId: m['barbero_id'].toString(),
      servicioId: m['servicio_id'].toString(),
      fechaInicio: DateTime.parse(m['fecha_inicio'].toString()).toLocal(),
      fechaFin: DateTime.parse(m['fecha_fin'].toString()).toLocal(),
      estado: (m['estado'] ?? 'pendiente').toString(),
    );
  }

  String _hhmm(dynamic valor) {
    final texto = (valor ?? '00:00').toString();
    return texto.length >= 5 ? texto.substring(0, 5) : texto;
  }

  Future<List<Cita>> obtenerMisCitas() async {
    final usuario = _client.auth.currentUser;

    if (usuario == null) {
      throw Exception('Debes iniciar sesión para consultar tus citas.');
    }

    final data = await _client
        .from(_tabla)
        .select()
        .eq('user_id', usuario.id)
        .order('fecha_inicio');

    return data.map<Cita>(_fromMap).toList();
  }

  Future<List<Cita>> obtenerCitasDelDia({
    required String barberoId,
    required DateTime fecha,
  }) async {
    final inicioDia = DateTime(fecha.year, fecha.month, fecha.day);
    final finDia = inicioDia.add(const Duration(days: 1));

    final data = await _client
        .from(_tabla)
        .select()
        .eq('barbero_id', barberoId)
        .inFilter('estado', ['pendiente', 'confirmada'])
        .lt('fecha_inicio', finDia.toUtc().toIso8601String())
        .gt('fecha_fin', inicioDia.toUtc().toIso8601String())
        .order('fecha_inicio');

    return data.map<Cita>(_fromMap).toList();
  }

  Future<Cita> crear({
    required String barberiaId,
    required String barberoId,
    required String servicioId,
    required DateTime fechaInicio,
  }) async {
    final usuario = _client.auth.currentUser;

    if (usuario == null) {
      throw Exception('Debes iniciar sesión para reservar una cita.');
    }

    final inicio = fechaInicio.toLocal();

    if (!inicio.isAfter(DateTime.now())) {
      throw Exception('Selecciona una fecha y hora futuras.');
    }

    final barbero = await _client
        .from('barberos')
        .select('id')
        .eq('id', barberoId)
        .eq('barberia_id', barberiaId)
        .eq('activo', true)
        .maybeSingle();

    if (barbero == null) {
      throw Exception(
        'El barbero no pertenece a esta barbería o no está disponible.',
      );
    }

    final servicio = await _client
        .from('servicios')
        .select('duracion_min')
        .eq('id', servicioId)
        .eq('barberia_id', barberiaId)
        .eq('activo', true)
        .maybeSingle();

    if (servicio == null) {
      throw Exception('El servicio no existe o no está disponible.');
    }

    final duracion = (servicio['duracion_min'] as num).toInt();

    if (duracion <= 0) {
      throw Exception('El servicio tiene una duración no válida.');
    }

    final fin = inicio.add(Duration(minutes: duracion));

    final horariosData = await _client
        .from('horarios')
        .select()
        .eq('barbero_id', barberoId)
        .eq('activo', true);

    final horarios = horariosData.map<Horario>((m) {
      return Horario(
        id: m['id'].toString(),
        barberoId: m['barbero_id'].toString(),
        dia: (m['dia'] as num).toInt(),
        horaInicio: _hhmm(m['hora_inicio']),
        horaFin: _hhmm(m['hora_fin']),
        activo: m['activo'] as bool? ?? true,
      );
    }).toList();

    final cabe = _disponibilidad.cabeEnHorario(
      inicio: inicio,
      duracionMinutos: duracion,
      horarios: horarios,
    );

    if (!cabe) {
      throw Exception(
        'La cita no cabe dentro del horario laboral del barbero.',
      );
    }

    final ocupadas = await _client
        .from(_tabla)
        .select()
        .eq('barbero_id', barberoId)
        .inFilter('estado', ['pendiente', 'confirmada'])
        .lt('fecha_inicio', fin.toUtc().toIso8601String())
        .gt('fecha_fin', inicio.toUtc().toIso8601String());

    final citas = ocupadas.map<Cita>(_fromMap).toList();

    if (_disponibilidad.tieneCruce(inicio: inicio, fin: fin, citas: citas)) {
      throw Exception('Ese horario ya está reservado. Elige otro.');
    }

    final data = await _client
        .from(_tabla)
        .insert({
          'user_id': usuario.id,
          'barberia_id': barberiaId,
          'barbero_id': barberoId,
          'servicio_id': servicioId,
          'fecha_inicio': inicio.toUtc().toIso8601String(),
          'fecha_fin': fin.toUtc().toIso8601String(),
          'estado': 'pendiente',
        })
        .select()
        .single();

    return _fromMap(data);
  }

  /// Cancela una cita del usuario autenticado.
  Future<void> cancelar(String citaId) async {
    final usuario = _client.auth.currentUser;

    if (usuario == null) {
      throw Exception('Debes iniciar sesión para cancelar una cita.');
    }

    final cita = await _client
        .from(_tabla)
        .select('id, estado, fecha_inicio')
        .eq('id', citaId)
        .eq('user_id', usuario.id)
        .maybeSingle();

    if (cita == null) {
      throw Exception('No se encontró la cita o no tienes permiso.');
    }

    final estado = cita['estado'].toString();

    final fechaInicio = DateTime.parse(cita['fecha_inicio'].toString())
        .toLocal();

    if (estado != 'pendiente' && estado != 'confirmada') {
      throw Exception('Esta cita ya no se puede cancelar.');
    }

    if (!fechaInicio.isAfter(DateTime.now())) {
      throw Exception('No puedes cancelar una cita que ya comenzó.');
    }
    final resultado = await _client
        .from(_tabla)
        .update({'estado': 'cancelada'})
        .eq('id', citaId)
        .eq('user_id', usuario.id)
        .inFilter('estado', ['pendiente', 'confirmada'])
        .gt('fecha_inicio', DateTime.now().toUtc().toIso8601String())
        .select('id');

    if (resultado.isEmpty) {
      throw Exception(
        'No se pudo cancelar. La cita pudo cambiar de estado o fecha.',
      );
    }
  }
}
