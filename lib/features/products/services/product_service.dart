import 'package:supabase_flutter/supabase_flutter.dart';

class ProductService {
  final _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getProducts() async {
    final data = await _client
        .from('products')
        .select()
        .eq('is_active', true)
        .order('created_at');

    return List<Map<String, dynamic>>.from(data);
  }
}
