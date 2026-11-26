import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/auth/presentation/screens/login_screen.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/session_gate.dart';
import 'features/auth/presentation/screens/password_recovery_screen.dart';
import 'features/commerce_management/presentation/commerce_requests_screen.dart';
import 'features/marketplace/data/marketplace_service.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/auth/presentation/screens/role_selection_screen.dart';
import 'features/auth/data/services/auth_profile_service.dart';
import 'features/auth/presentation/screens/profile_access_gate.dart';

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
  final _profileService = AuthProfileService();
  final _marketplace = MarketplaceService();
  late final StreamSubscription<AuthState> _events;
  String? _recoveryUserId;
  String? _sessionUserId;
  bool _authLinkError = false;

  @override
  void initState() {
    super.initState();
    _sessionUserId = _auth.currentUser?.id;
    _events = _auth.onAuthStateChange.listen(
      (state) {
        final id = _auth.currentUser?.id;
        final recovered =
            state.event == AuthChangeEvent.passwordRecovery &&
            state.session?.user.id == id;
        final recoveryId = recovered
            ? id
            : _recoveryUserId == id
            ? _recoveryUserId
            : null;
        if (_sessionUserId == id && _recoveryUserId == recoveryId) return;
        setState(() {
          _sessionUserId = id;
          _recoveryUserId = recoveryId;
          _authLinkError = false;
        });
      },
      onError: (Object error, StackTrace stackTrace) {
        if (error is AuthException && _auth.currentSession == null) {
          setState(() => _authLinkError = true);
        }
      },
    );
  }

  @override
  void dispose() {
    unawaited(_events.cancel());
    super.dispose();
  }

  Future<void> _signOut() => _auth.signOut(scope: SignOutScope.local);

  Future<void> _resetPassword(String password) async {
    if (_recoveryUserId == null || _auth.currentUser?.id != _recoveryUserId) {
      throw StateError('La sesión de recuperación ya no es válida.');
    }
    await _auth.updateUser(UserAttributes(password: password));
    await _auth.signOut(scope: SignOutScope.global);
  }

  late final Stream<bool> _sessionChanges = _auth.onAuthStateChange
      .handleError((Object _) {})
      .map((_) => _auth.currentSession != null)
      .distinct();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      key: ValueKey((_sessionUserId, _recoveryUserId)),
      title: 'CUT & GO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: _recoveryUserId != null
          ? PasswordRecoveryScreen.reset(
              onSubmit: _resetPassword,
              onCancel: _signOut,
            )
          : SessionGate(
              sessionChanges: _sessionChanges,
              initiallySignedIn: _auth.currentSession != null,
              signedOutBuilder: (_) {
                if (_authLinkError) {
                  return Scaffold(
                    body: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'No pudimos abrir el enlace. Puedes solicitar uno nuevo desde el acceso.',
                            ),
                            TextButton(
                              onPressed: () =>
                                  setState(() => _authLinkError = false),
                              child: const Text('Volver al acceso'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
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
              signedInBuilder: (_) => ProfileAccessGate(
                key: ValueKey(_auth.currentUser?.id),
                userId: _auth.currentUser?.id,
                selectedRole: _selectedAccessRole,
                loadProfile: _profileService.obtenerPerfilDeAcceso,
                onSignOut: _signOut,
                adminBuilder: (_) => CommerceRequestsScreen.review(
                  service: _marketplace,
                  onSignOut: _signOut,
                ),
                authorizedBuilder: (_) => HomeScreen(
                  email: _auth.currentUser?.email,
                  onSignOut: _signOut,
                  marketplace: _marketplace,
                ),
              ),
            ),
    );
  }
}
