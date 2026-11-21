import 'package:supabase_flutter/supabase_flutter.dart';

class MerchantOrderService {
  final _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getOrders(String comercioId) async {
    final data = await _client
        .from('orders')
        .select()
        .eq('comercio_id', comercioId)
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

  Future<void> updateStatus(String orderId, String status) async {
    await _client.rpc('update_order_status', params: {
      'p_order': orderId,
      'p_status': status,
    });
  }
}
