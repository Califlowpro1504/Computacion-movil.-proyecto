import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/auth_panel.dart';

enum AccessRole { cliente, propietario, barbero, administrador }

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key, required this.onRoleSelected});

  final ValueChanged<AccessRole> onRoleSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthHeading(
              title: '¿Cómo deseas ingresar?',
              subtitle: 'Elige el acceso correspondiente a tu cuenta.',
            ),
            _RoleCard(
              icon: Icons.person_outline,
              title: 'Cliente',
              description: 'Descubre comercios, productos y servicios.',
              onTap: () => onRoleSelected(AccessRole.cliente),
            ),
            const SizedBox(height: 12),
            _RoleCard(
              icon: Icons.storefront_outlined,
              title: 'Propietario',
              description: 'Administra tu barbería y tus servicios.',
              onTap: () => onRoleSelected(AccessRole.propietario),
            ),
            const SizedBox(height: 12),
            _RoleCard(
              icon: Icons.content_cut,
              title: 'Barbero',
              description: 'Accede a tu espacio de trabajo y tus citas.',
              onTap: () => onRoleSelected(AccessRole.barbero),
            ),
            const SizedBox(height: 12),
            _RoleCard(
              icon: Icons.admin_panel_settings_outlined,
              title: 'Administrador',
              description: 'Accede a la administración de la plataforma.',
              onTap: () => onRoleSelected(AccessRole.administrador),
            ),
            const SizedBox(height: 24),
            const Text(
              'El acceso se verificará con los permisos de tu cuenta.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.muted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.elevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.accent, size: 30),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.ivory,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppTheme.muted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppTheme.accent),
            ],
          ),
        ),
      ),
    );
  }
}
