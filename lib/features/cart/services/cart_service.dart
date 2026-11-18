import 'package:supabase_flutter/supabase_flutter.dart';

class CartService {
  final _client = Supabase.instance.client;

  Future<String> _activeCartId() async {
    final userId = _client.auth.currentUser!.id;
    final existing = await _client
        .from('carts')
        .select('id')
        .eq('user_id', userId)
        .eq('status', 'activo')
        .maybeSingle();
    if (existing != null) return existing['id'] as String;

    final created = await _client
        .from('carts')
        .insert({'user_id': userId})
        .select('id')
        .single();
    return created['id'] as String;
  }

  Future<void> addToCart(String productId, {int quantity = 1}) async {
    final cartId = await _activeCartId();
    final existing = await _client
        .from('cart_items')
        .select('id, quantity')
        .eq('cart_id', cartId)
        .eq('product_id', productId)
        .maybeSingle();

    if (existing != null) {
      await _client
          .from('cart_items')
          .update({'quantity': (existing['quantity'] as int) + quantity})
          .eq('id', existing['id']);
    } else {
      await _client.from('cart_items').insert({
        'cart_id': cartId,
        'product_id': productId,
        'quantity': quantity,
      });
    }
  }

  Future<List<Map<String, dynamic>>> getItems() async {
    final cartId = await _activeCartId();
    final data = await _client
        .from('cart_items')
        .select('id, quantity, unit_price, products(name)')
        .eq('cart_id', cartId);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> updateQuantity(String itemId, int quantity) async {
    if (quantity <= 0) {
      await removeItem(itemId);
      return;
    }
    await _client
        .from('cart_items')
        .update({'quantity': quantity})
        .eq('id', itemId);
  }

  Future<void> removeItem(String itemId) async {
    await _client.from('cart_items').delete().eq('id', itemId);
  }

  Future<void> confirmOrder() async {
    await _client.rpc('create_order_from_cart');
  }
}
