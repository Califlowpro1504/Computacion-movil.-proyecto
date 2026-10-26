import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/session_gate.dart';
import 'features/home/presentation/screens/home_screen.dart';

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
        signedOutBuilder: (_) => const LoginScreen(),
        signedInBuilder: (_) => HomeScreen(
          email: _auth.currentUser?.email,
          onSignOut: () => _auth.signOut(scope: SignOutScope.local),
        ),
      ),
    );
  }
}