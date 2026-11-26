import 'package:flutter/material.dart';

import '../../../../core/widgets/auth_panel.dart';
import 'role_selection_screen.dart';

class ProfileAccessGate extends StatefulWidget {
  const ProfileAccessGate({
    super.key,
    required this.userId,
    required this.selectedRole,
    required this.loadProfile,
    required this.onSignOut,
    required this.authorizedBuilder,
  });

  final String? userId;
  final AccessRole? selectedRole;
  final Future<Map<String, dynamic>?> Function() loadProfile;
  final Future<void> Function() onSignOut;
  final WidgetBuilder authorizedBuilder;

  @override
  State<ProfileAccessGate> createState() => _ProfileAccessGateState();
}

class _ProfileAccessGateState extends State<ProfileAccessGate> {
  late Future<Map<String, dynamic>?> _profileFuture;
  bool _closing = false;
  String? _actionError;

  @override
  void initState() {
    super.initState();
    _profileFuture = widget.loadProfile();
  }

  void _retry() {
    setState(() {
      _actionError = null;
      _profileFuture = widget.loadProfile();
    });
  }

  Future<void> _signOut() async {
    setState(() {
      _closing = true;
      _actionError = null;
    });

    try {
      await widget.onSignOut();
    } catch (_) {
      if (mounted) {
        setState(() {
          _actionError = 'No pudimos cerrar la sesión. Inténtalo de nuevo.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _closing = false);
      }
    }
  }

  String? _validateProfile(Map<String, dynamic>? profile) {
    if (widget.userId == null ||
        profile == null ||
        profile['id'] != widget.userId) {
      return 'No encontramos un perfil válido para esta sesión.';
    }

    if (profile['activo'] != true) {
      return 'Tu cuenta no está activa. Contacta al administrador.';
    }

    if (profile['rol'] != 'cliente') {
      return 'Este rol todavía no tiene un acceso configurado.';
    }

    if (widget.selectedRole != null &&
        widget.selectedRole != AccessRole.cliente) {
      return 'Tu cuenta es Cliente. Regresa al acceso y selecciona Cliente.';
    }

    return null;
  }

  Widget _blocked(String message) {
    return Scaffold(
      body: AuthPanel(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.lock_outline, size: 40),
            const SizedBox(height: 20),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            if (_actionError != null) ...[
              Text(
                _actionError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 16),
            ],
            ElevatedButton(
              onPressed: _closing ? null : _signOut,
              child: Text(_closing ? 'Cerrando sesión…' : 'Volver al acceso'),
            ),
            TextButton(
              onPressed: _closing ? null : _retry,
              child: const Text('Reintentar comprobación'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return _blocked(
            'No pudimos verificar tu acceso. Revisa tu conexión e inténtalo nuevamente.',
          );
        }

        final error = _validateProfile(snapshot.data);

        if (error != null) {
          return _blocked(error);
        }

        return widget.authorizedBuilder(context);
      },
    );
  }
}
