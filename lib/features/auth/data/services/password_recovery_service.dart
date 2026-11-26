import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_email_redirect.dart';

Future<void> requestPasswordRecovery(String email) async {
  try {
    await Supabase.instance.client.auth.resetPasswordForEmail(
      email,
      redirectTo: authEmailRedirect,
    );
  } on AuthException catch (error) {
    // Use the same confirmation for missing accounts.
    if (error.code != 'user_not_found') rethrow;
  }
}
