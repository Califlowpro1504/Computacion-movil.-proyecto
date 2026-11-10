import 'package:supabase_flutter/supabase_flutter.dart';

class ProductManagementService {
  final _client = Supabase.instance.client;

  /// Barbería (comercio) del usuario con sesión iniciada.
  Future<Map<String, dynamic>?> getMyComercio() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    return await _client
        .from('barberias')
        .select('id, nombre')
        .eq('propietario_id', userId)
        .limit(1)
        .maybeSingle();
  }

  Future<List<Map<String, dynamic>>> getProducts(String comercioId) async {
    final data = await _client
        .from('products')
        .select()
        .eq('comercio_id', comercioId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> createProduct({
    required String comercioId,
    required String name,
    String? description,
    required double price,
    required int stock,
    String? category,
  }) async {
    await _client.from('products').insert({
      'comercio_id': comercioId,
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'category': category,
    });
  }

  Future<void> updateProduct(String id, Map<String, dynamic> changes) async {
    await _client.from('products').update(changes).eq('id', id);
  }

  Future<void> setActive(String id, bool active) async {
    await updateProduct(id, {'is_active': active});
  }

  Future<void> updateStock(String id, int stock) async {
    await updateProduct(id, {'stock': stock});
  }
}
