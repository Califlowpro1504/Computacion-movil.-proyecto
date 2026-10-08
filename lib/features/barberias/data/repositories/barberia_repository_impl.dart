import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/barberia.dart';
import '../../domain/repositories/barberia_repository.dart';

class BarberiaRepositoryImpl implements BarberiaRepository {
  final SupabaseClient _client;

  BarberiaRepositoryImpl({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  static const _tabla = 'barberias';

  Barberia _fromMap(Map<String, dynamic> m) {
    return Barberia(
      id: m['id'].toString(),
      nombre: m['nombre'] ?? '',
      direccion: m['direccion'] ?? '',
      telefono: m['telefono'] ?? '',
      imagen: m['imagen'] ?? '',
      activa: m['activa'] ?? true,
    );
  }

  Map<String, dynamic> _toMap(Barberia b) => {
        if (b.id.isNotEmpty) 'id': b.id,
        'nombre': b.nombre,
        'direccion': b.direccion,
        'telefono': b.telefono,
        'imagen': b.imagen,
        'activa': b.activa,
      };

  @override
  Future<List<Barberia>> obtenerBarberias() async {
    final data = await _client.from(_tabla).select();
    return data.map<Barberia>(_fromMap).toList();
  }

  @override
  Future<Barberia?> obtenerBarberiaPorId(String id) async {
    final data =
        await _client.from(_tabla).select().eq('id', id).maybeSingle();
    return data == null ? null : _fromMap(data);
  }

  @override
  Future<void> crearBarberia(Barberia barberia) async {
    await _client.from(_tabla).insert(_toMap(barberia));
  }

  @override
  Future<void> actualizarBarberia(Barberia barberia) async {
    await _client
        .from(_tabla)
        .update(_toMap(barberia))
        .eq('id', barberia.id);
  }

  @override
  Future<void> eliminarBarberia(String id) async {
    await _client.from(_tabla).delete().eq('id', id);
  }
}
