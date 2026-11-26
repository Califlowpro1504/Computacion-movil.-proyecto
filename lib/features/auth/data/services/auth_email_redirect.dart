import 'package:flutter/foundation.dart';

String get authEmailRedirect =>
    kIsWeb ? '${Uri.base.origin}${Uri.base.path}' : 'cutandgo://auth/callback';
