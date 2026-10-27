import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/cita.dart';

class CitaRepository {
  final SupabaseClient _client;

  CitaRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

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
    required DateTime fechaFin,
  }) async {
    final usuario = _client.auth.currentUser;

    if (usuario == null) {
      throw Exception('Debes iniciar sesión para reservar una cita.');
    }

    if (!fechaFin.isAfter(fechaInicio)) {
      throw Exception(
        'La hora de finalización debe ser posterior a la de inicio.',
      );
    }

    if (!fechaInicio.isAfter(DateTime.now())) {
      throw Exception('Selecciona una fecha y hora futuras.');
    }

    final data = await _client
        .from(_tabla)
        .insert({
          'user_id': usuario.id,
          'barberia_id': barberiaId,
          'barbero_id': barberoId,
          'servicio_id': servicioId,
          'fecha_inicio': fechaInicio.toUtc().toIso8601String(),
          'fecha_fin': fechaFin.toUtc().toIso8601String(),
          'estado': 'pendiente',
        })
        .select()
        .single();

    return _fromMap(data);
  }
}
