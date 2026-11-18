import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/entities/barbero.dart';

class BarberoRepository {
  final SupabaseClient _client;

  BarberoRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  static const _tabla = 'barberos';

  Barbero _fromMap(Map<String, dynamic> m) {
    return Barbero(
      id: m['id'].toString(),
      barberiaId: (m['barberia_id'] ?? '').toString(),
      nombre: m['nombre'] ?? '',
      apellido: m['apellido'] ?? '',
      descripcion: m['descripcion'] ?? '',
      fotografia: m['fotografia'] ?? '',
      activo: m['activo'] ?? true,
    );
  }

  Map<String, dynamic> _toMap(Barbero b) => {
        'barberia_id': b.barberiaId,
        'nombre': b.nombre,
        'apellido': b.apellido,
        'descripcion': b.descripcion,
        'fotografia': b.fotografia,
        'activo': b.activo,
      };

  Future<List<Barbero>> obtenerPorBarberia(String barberiaId) async {
    final data =
        await _client.from(_tabla).select().eq('barberia_id', barberiaId);
    return data.map<Barbero>(_fromMap).toList();
  }

  Future<void> crear(Barbero b) async {
    await _client.from(_tabla).insert(_toMap(b));
  }

  Future<void> actualizar(Barbero b) async {
    await _client.from(_tabla).update(_toMap(b)).eq('id', b.id);
  }

  Future<void> cambiarEstado(String id, bool activo) async {
    await _client.from(_tabla).update({'activo': activo}).eq('id', id);
  }

  Future<void> eliminar(String id) async {
    await _client.from(_tabla).delete().eq('id', id);
  }
}
