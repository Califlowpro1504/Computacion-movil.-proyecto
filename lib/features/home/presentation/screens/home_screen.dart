import 'package:flutter/material.dart';
import '../../../../core/widgets/auth_panel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.email, required this.onSignOut});

  final String? email;
  final Future<void> Function() onSignOut;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _signingOut = false;
  String? _error;

  Future<void> _signOut() async {
    setState(() {
      _signingOut = true;
      _error = null;
    });
    try {
      await widget.onSignOut();
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No pudimos cerrar la sesión. Inténtalo de nuevo.');
      }
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthPanel(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthHeading(
              title: 'Este es tu espacio',
              subtitle: 'Bienvenido a CUT & GO.',
            ),
            const Icon(Icons.verified_user_outlined, size: 40),
            const SizedBox(height: 16),
            const Text('Sesión iniciada', textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            if (widget.email != null) ...[
              const SizedBox(height: 8),
              Text(widget.email!, textAlign: TextAlign.center),
            ],
            const SizedBox(height: 24),
            const Text(
              'Pronto podrás explorar comercios, descubrir productos y reservar tu próxima cita.',
              textAlign: TextAlign.center,
              style: TextStyle(height: 1.6),
            ),
            const SizedBox(height: 32),
            if (_error != null) ...[
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              const SizedBox(height: 16),
            ],
            ElevatedButton.icon(
              onPressed: _signingOut ? null : _signOut,
              icon: _signingOut
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.logout),
              label: Text(_signingOut ? 'Cerrando sesión…' : 'Cerrar sesión'),
            ),
          ],
        ),
      ),
    );
  }
}
