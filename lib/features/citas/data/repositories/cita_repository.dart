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

    // Consultar la duración del servicio activo.
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

    // Calcular automáticamente la hora de finalización.
    final fin = inicio.add(Duration(minutes: duracion));

    // Consultar los horarios activos del barbero.
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

    // Buscar citas que se crucen con el intervalo solicitado.
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

    // Guardar la cita. Supabase también aplicará las políticas
    // de seguridad y la restricción de solapamiento de la base de datos.
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
}
