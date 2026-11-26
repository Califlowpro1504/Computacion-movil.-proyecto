import 'package:flutter/material.dart';

import '../../data/services/profile_service.dart';
import '../../../auth/presentation/validators/auth_validators.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.loadProfile,
    this.saveProfile,
    this.requestEmailChange,
  });

  final Future<void> Function(String, String, String)? saveProfile;
  final Future<void> Function(String)? requestEmailChange;

  final Future<Map<String, dynamic>?> Function()? loadProfile;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  Future<Map<String, dynamic>?> _loadProfile() {
    final loader = widget.loadProfile;

    if (loader != null) {
      return loader();
    }

    return ProfileService().obtenerMiPerfil();
  }

  void _retry() {
    setState(() {
      _profileFuture = _loadProfile();
    });
  }

  Future<void> _edit(Map<String, dynamic> profile) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          profile: profile,
          saveProfile: widget.saveProfile,
        ),
      ),
    );
    if (mounted && updated == true) _retry();
  }

  Future<void> _changeEmail(String current) async {
    final form = GlobalKey<FormState>();
    var email = '';
    var saving = false;
    String? error;
    final sent = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (dialog, update) => PopScope(
          canPop: !saving,
          child: AlertDialog(
            title: const Text('Cambiar correo'),
            scrollable: true,
            content: Form(
              key: form,
              child: TextFormField(
                enabled: !saving,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Nuevo correo',
                  errorText: error,
                ),
                onChanged: (value) {
                  email = value.trim();
                  if (error != null) update(() => error = null);
                },
                validator: (value) =>
                    AuthValidators.validarCorreo(value) ??
                    (email.toLowerCase() == current.toLowerCase()
                        ? 'Ingresa un correo diferente.'
                        : null),
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(dialog),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (!form.currentState!.validate()) return;
                        update(() => saving = true);
                        try {
                          final request =
                              widget.requestEmailChange ??
                              ProfileService().solicitarCambioCorreo;
                          await request(email);
                          if (dialog.mounted) Navigator.pop(dialog, true);
                        } catch (_) {
                          if (dialog.mounted) {
                            update(() {
                              saving = false;
                              error = 'No pudimos solicitar el cambio.';
                            });
                          }
                        }
                      },
                child: Text(saving ? 'Enviando…' : 'Enviar confirmación'),
              ),
            ],
          ),
        ),
      ),
    );
    if (mounted && sent == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Revisa tu correo actual y el nuevo para confirmar el cambio.',
          ),
        ),
      );
    }
  }

  Widget _message(String message) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _retry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _message(
                'No pudimos cargar tu perfil. Revisa tu conexión.',
              );
            }

            final profile = snapshot.data;

            if (profile == null) {
              return _message(
                'No encontramos tu perfil. Contacta al administrador.',
              );
            }

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      child: Icon(
                        Icons.person_outline,
                        size: 40,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Información personal',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Estos son los datos de tu cuenta.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    _ProfileField(label: 'Nombre', value: profile['nombre']),
                    _ProfileField(
                      label: 'Apellido',
                      value: profile['apellido'],
                    ),
                    _ProfileField(
                      label: 'Correo electrónico',
                      value: profile['correo'],
                    ),
                    _ProfileField(
                      label: 'Teléfono',
                      value: profile['telefono'],
                    ),
                    FilledButton(
                      onPressed: () => _edit(profile),
                      child: const Text('Editar perfil'),
                    ),
                    TextButton(
                      onPressed: () =>
                          _changeEmail(profile['correo'] as String? ?? ''),
                      child: const Text('Cambiar correo'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({required this.label, required this.value});

  final String label;
  final Object? value;

  @override
  Widget build(BuildContext context) {
    final text = value?.toString().trim();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              text == null || text.isEmpty ? 'Sin registrar' : text,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
