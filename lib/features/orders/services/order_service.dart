import 'package:supabase_flutter/supabase_flutter.dart';

class OrderService {
  final _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getMyOrders() async {
    final data = await _client
        .from('orders')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getOrderItems(String orderId) async {
    final data = await _client
        .from('order_items')
        .select('quantity, unit_price, subtotal, products(name)')
        .eq('order_id', orderId);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> cancelOrder(String orderId) async {
    await _client.rpc('cancel_order', params: {'p_order': orderId});
  }

  Future<bool> hasRated(String orderId) async {
    final data = await _client
        .from('ratings')
        .select('id')
        .eq('order_id', orderId)
        .maybeSingle();
    return data != null;
  }

  Future<void> rateOrder({
    required String orderId,
    required String comercioId,
    required int score,
    String? comment,
  }) async {
    await _client.from('ratings').insert({
      'user_id': _client.auth.currentUser!.id,
      'order_id': orderId,
      'comercio_id': comercioId,
      'score': score,
      'comment': comment,
    });
  }
}
