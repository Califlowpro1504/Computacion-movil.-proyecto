import 'package:supabase_flutter/supabase_flutter.dart';

typedef CommerceData = Map<String, dynamic>;

const commerceTypes = ['Barbería', 'Tienda', 'Servicios', 'Otro'];

class MarketplaceService {
  MarketplaceService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  static const pageSize = 25;
  final SupabaseClient _client;

  Future<List<CommerceData>> search({
    String query = '',
    String category = '',
    String zone = '',
    String type = '',
    int? rating,
    int offset = 0,
  }) async {
    final rows = await _client.rpc<List<dynamic>>(
      'buscar_comercios',
      params: {
        'consulta': query.trim(),
        'categoria_filtro': category.trim(),
        'zona_filtro': zone.trim(),
        'tipo_filtro': type,
        'calificacion_min': rating,
        'desplazamiento': offset,
      },
    );
    return rows.cast<CommerceData>();
  }

  Future<CommerceData?> detail(String id) async {
    final rows = await _client.rpc<List<dynamic>>(
      'buscar_comercios',
      params: {'comercio_filtro': id},
    );
    return rows.cast<CommerceData>().singleOrNull;
  }

  Future<List<CommerceData>> requests({required bool review}) async {
    var query = _client
        .from('solicitudes_comercio')
        .select(
          'id, comercio_id, nombre, descripcion, direccion, telefono, imagen, '
          'categoria, zona, tipo, horario, estado, observacion, revisada_en, visible, version',
        );
    if (review) {
      query = query.eq('estado', 'pendiente');
    } else {
      final user = _client.auth.currentUser;
      if (user == null) throw StateError('No hay una sesión iniciada.');
      query = query.eq('propietario_id', user.id);
    }
    return query.order('enviada_en', ascending: false);
  }

  Future<void> submit(CommerceData fields) async {
    await _client.from('solicitudes_comercio').insert(fields);
  }

  Future<void> update(String id, CommerceData fields) async {
    await _client.rpc<void>(
      'actualizar_comercio_propio',
      params: {'solicitud': id, 'cambios': fields},
    );
  }

  Future<void> review(String id, bool approved, String notes) async {
    await _client.rpc<void>(
      'revisar_solicitud_comercio',
      params: {'solicitud': id, 'aprobar': approved, 'detalle': notes},
    );
  }
}
