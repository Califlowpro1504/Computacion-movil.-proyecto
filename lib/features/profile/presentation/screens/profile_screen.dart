
import 'package:flutter/material.dart';

import '../../data/services/profile_service.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();

  late Future<Map<String, dynamic>?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _profileService.obtenerMiPerfil();
  }

  Future<void> _reloadProfile() async {
    setState(() {
      _profileFuture = _profileService.obtenerMiPerfil();
    });
  }

  Future<void> _editProfile(Map<String, dynamic> profile) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(profile: profile),
      ),
    );

    if (updated == true && mounted) {
      await _reloadProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return _buildMessage(
              'No fue posible cargar tu perfil.',
              onRetry: _reloadProfile,
            );
          }

          final profile = snapshot.data;

          if (profile == null) {
            return _buildMessage(
              'No se encontró la información de tu perfil.',
              onRetry: _reloadProfile,
            );
          }

          return RefreshIndicator(
            onRefresh: _reloadProfile,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const SizedBox(height: 20),
                const CircleAvatar(
                  radius: 45,
                  child: Icon(Icons.person, size: 48),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    '${profile['nombre'] ?? ''} ${profile['apellido'] ?? ''}',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 28),
                _ProfileField(
                  label: 'Nombre',
                  value: profile['nombre'],
                  icon: Icons.person_outline,
                ),
                _ProfileField(
                  label: 'Apellido',
                  value: profile['apellido'],
                  icon: Icons.person_outline,
                ),
                _ProfileField(
                  label: 'Correo electrónico',
                  value: profile['correo'],
                  icon: Icons.email_outlined,
                ),
                _ProfileField(
                  label: 'Teléfono',
                  value: profile['telefono'],
                  icon: Icons.phone_outlined,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => _editProfile(profile),
                  icon: const Icon(Icons.edit),
                  label: const Text('Editar perfil'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessage(String message, {required VoidCallback onRetry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, size: 42),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final dynamic value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        subtitle: Text(
          value?.toString().trim().isNotEmpty == true
              ? value.toString()
              : 'No registrado',
        ),
      ),
    );
  }
}
