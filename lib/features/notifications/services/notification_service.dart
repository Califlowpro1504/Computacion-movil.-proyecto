import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  final _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getNotifications() async {
    final data = await _client
        .from('notifications')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> markAsRead(String id) async {
    await _client.from('notifications').update({'is_read': true}).eq('id', id);
  }
}
