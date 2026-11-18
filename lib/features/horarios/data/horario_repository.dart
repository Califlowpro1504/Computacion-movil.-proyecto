import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/entities/horario.dart';

class HorarioRepository {
  final SupabaseClient _client;

  HorarioRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  static const _tabla = 'horarios';

  // Postgres devuelve la hora como HH:mm:ss; nos quedamos con HH:mm.
  String _hhmm(dynamic v) {
    final s = (v ?? '00:00').toString();
    return s.length >= 5 ? s.substring(0, 5) : s;
  }

  Horario _fromMap(Map<String, dynamic> m) {
    return Horario(
      id: m['id'].toString(),
      barberoId: (m['barbero_id'] ?? '').toString(),
      dia: (m['dia'] as num?)?.toInt() ?? 1,
      horaInicio: _hhmm(m['hora_inicio']),
      horaFin: _hhmm(m['hora_fin']),
      activo: m['activo'] ?? true,
    );
  }

  Map<String, dynamic> _toMap(Horario h) => {
        'barbero_id': h.barberoId,
        'dia': h.dia,
        'hora_inicio': h.horaInicio,
        'hora_fin': h.horaFin,
        'activo': h.activo,
      };

  Future<List<Horario>> obtenerPorBarbero(String barberoId) async {
    final data = await _client
        .from(_tabla)
        .select()
        .eq('barbero_id', barberoId)
        .order('dia')
        .order('hora_inicio');
    return data.map<Horario>(_fromMap).toList();
  }

  Future<void> crear(Horario h) async {
    await _client.from(_tabla).insert(_toMap(h));
  }

  Future<void> actualizar(Horario h) async {
    await _client.from(_tabla).update(_toMap(h)).eq('id', h.id);
  }

  Future<void> cambiarEstado(String id, bool activo) async {
    await _client.from(_tabla).update({'activo': activo}).eq('id', id);
  }

  Future<void> eliminar(String id) async {
    await _client.from(_tabla).delete().eq('id', id);
  }
}
