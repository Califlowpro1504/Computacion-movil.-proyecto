import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/entities/servicio.dart';

class ServicioRepository {
  final SupabaseClient _client;

  ServicioRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  static const _tabla = 'servicios';

  Servicio _fromMap(Map<String, dynamic> m) {
    return Servicio(
      id: m['id'].toString(),
      barberiaId: (m['barberia_id'] ?? '').toString(),
      nombre: m['nombre'] ?? '',
      descripcion: m['descripcion'] ?? '',
      precio: (m['precio'] as num?)?.toDouble() ?? 0,
      duracionMin: (m['duracion_min'] as num?)?.toInt() ?? 0,
      activo: m['activo'] ?? true,
    );
  }

  Map<String, dynamic> _toMap(Servicio s) => {
        'barberia_id': s.barberiaId,
        'nombre': s.nombre,
        'descripcion': s.descripcion,
        'precio': s.precio,
        'duracion_min': s.duracionMin,
        'activo': s.activo,
      };

  Future<List<Servicio>> obtenerPorBarberia(String barberiaId) async {
    final data =
        await _client.from(_tabla).select().eq('barberia_id', barberiaId);
    return data.map<Servicio>(_fromMap).toList();
  }

  Future<void> crear(Servicio s) async {
    await _client.from(_tabla).insert(_toMap(s));
  }

  Future<void> actualizar(Servicio s) async {
    await _client.from(_tabla).update(_toMap(s)).eq('id', s.id);
  }

  Future<void> cambiarEstado(String id, bool activo) async {
    await _client.from(_tabla).update({'activo': activo}).eq('id', id);
  }
}
