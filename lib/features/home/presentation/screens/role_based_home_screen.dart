import 'package:flutter/material.dart';

import 'package:computacion_movil_proyecto/features/admin/presentation/screens/panel_administracion.dart';

import '../../../auth/data/repositories/auth_repository_impl.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../barberias/presentation/screens/panel_propietario_screen.dart';
import 'home_screen.dart';

class RoleBasedHomeScreen extends StatefulWidget {
  const RoleBasedHomeScreen({
    super.key,
    required this.email,
    required this.onSignOut,
  });

  final String? email;
  final Future<void> Function() onSignOut;

  @override
  State<RoleBasedHomeScreen> createState() => _RoleBasedHomeScreenState();
}

class _RoleBasedHomeScreenState extends State<RoleBasedHomeScreen> {
  final _repository = AuthRepositoryImpl();

  late Future<AppUser?> _perfilFuture;

  @override
  void initState() {
    super.initState();
    _perfilFuture = _repository.usuarioActual;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser?>(
      future: _perfilFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _mensajeError();
        }

        final perfil = snapshot.data!;
        final rol = perfil.rol.trim().toLowerCase();

        // Cuenta propietaria con permisos adicionales de administrador.
        if (perfil.esAdmin && rol == 'propietario') {
          return _panelAccesos();
        }

        switch (rol) {
          case 'cliente':
            return HomeScreen(email: widget.email, onSignOut: widget.onSignOut);

          case 'propietario':
            return _panelPropietario();

          case 'barbero':
            return _panelPendiente(
              titulo: 'Panel del barbero',
              mensaje: 'AquÃ­ podrÃ¡s consultar tus citas asignadas.',
              icono: Icons.content_cut,
            );

          case 'admin':
            return _panelAdministrador();

          default:
            return _mensajeError();
        }
      },
    );
  }

  Widget _panelAccesos() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CUT & GO - AdministraciÃ³n'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesiÃ³n',
            onPressed: () => widget.onSignOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.admin_panel_settings, size: 70),
            const SizedBox(height: 12),
            Text(
              'Panel de administraciÃ³n',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Selecciona el espacio al que deseas ingresar.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Card(
              child: ListTile(
                leading: const Icon(Icons.store, size: 35),
                title: const Text('Panel de propietario'),
                subtitle: const Text(
                  'Gestionar barberÃ­as, servicios y barberos.',
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => _panelPropietario()),
                  );
                },
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.admin_panel_settings, size: 35),
                title: const Text('Panel de administrador'),
                subtitle: const Text('AdministraciÃ³n general de CUT & GO.'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => _panelAdministrador()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _panelPropietario() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel del propietario'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesiÃ³n',
            onPressed: () => widget.onSignOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: const PanelPropietarioScreen(),
    );
  }

  Widget _panelAdministrador() {
    return PanelAdministradorScreen(onSignOut: widget.onSignOut);
  }

  Widget _panelPendiente({
    required String titulo,
    required String mensaje,
    required IconData icono,
  }) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesiÃ³n',
            onPressed: () => widget.onSignOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icono, size: 60),
              const SizedBox(height: 16),
              Text(titulo, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(mensaje, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mensajeError() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              const Text(
                'No se pudo verificar tu perfil.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => widget.onSignOut(),
                child: const Text('Cerrar sesiÃ³n'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
