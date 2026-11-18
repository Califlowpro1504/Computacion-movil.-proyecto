import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/auth/presentation/screens/login_screen.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/session_gate.dart';
import 'features/auth/presentation/screens/role_selection_screen.dart';
import 'features/home/presentation/screens/role_based_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://klutoeyuqrhtpdhblzxy.supabase.co', // ← tu Project URL
    publishableKey: 'sb_publishable_o7avjQLm3WXkL-R9wNT1VQ_sj0lVxH2', // ← pega aquí la key que copiaste
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  AccessRole? _selectedAccessRole;

  final _auth = Supabase.instance.client.auth;
  late final Stream<bool> _sessionChanges = _auth.onAuthStateChange
      .map((event) => event.session != null)
      .distinct();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CUT & GO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: SessionGate(
        sessionChanges: _sessionChanges,
        initiallySignedIn: _auth.currentSession != null,
        signedOutBuilder: (_) {
          final selectedRole = _selectedAccessRole;

          if (selectedRole == null) {
            return RoleSelectionScreen(
              onRoleSelected: (role) {
                setState(() => _selectedAccessRole = role);
              },
            );
          }

          return LoginScreen(
            key: ValueKey(selectedRole),
            accessRole: selectedRole,
            onBack: () {
              setState(() => _selectedAccessRole = null);
            },
          );
        },
        signedInBuilder: (_) => RoleBasedHomeScreen(
          email: _auth.currentUser?.email,
          onSignOut: () => _auth.signOut(scope: SignOutScope.local),
        ),
      ),
    );
  }
}
