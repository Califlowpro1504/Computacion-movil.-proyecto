import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../citas/presentation/screens/administracion_citas_screen.dart';
import 'usuarios_admin_screen.dart';
import 'comercios_admin_screen.dart';

class PanelAdministradorScreen extends StatefulWidget {
  const PanelAdministradorScreen({super.key, required this.onSignOut});

  final Future<void> Function() onSignOut;

  @override
  State<PanelAdministradorScreen> createState() =>
      _PanelAdministradorScreenState();
}

class _PanelAdministradorScreenState extends State<PanelAdministradorScreen> {
  int _selectedIndex = 0;

  late final SupabaseClient _supabase;

  late final Future<int> _usuariosFuture;
  late final Future<int> _comerciosFuture;
  late final Future<int> _barberiasFuture;
  late final Future<int> _citasFuture;

  final List<_AdminSection> _sections = const [
    _AdminSection('Resumen', Icons.dashboard_outlined),
    _AdminSection('Usuarios', Icons.people_outline),
    _AdminSection('Comercios', Icons.store_outlined),
    _AdminSection('Barber�as', Icons.content_cut),
    _AdminSection('Citas', Icons.calendar_month_outlined),
    _AdminSection('Reportes', Icons.bar_chart_outlined),
    _AdminSection('Configuraci�n', Icons.settings_outlined),
  ];

  @override
  void initState() {
    super.initState();

    _supabase = Supabase.instance.client;

    _usuariosFuture = _contarRegistros('profiles');

    // Actualmente los comercios est�n representados
    // por los registros de la tabla barberias.
    _barberiasFuture = _contarRegistros('barberias');
    _comerciosFuture = _barberiasFuture;

    _citasFuture = _contarRegistros('citas');
  }

  Future<int> _contarRegistros(String tabla) async {
    final registros = await _supabase.from(tabla).select('id');
    return registros.length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CUT & GO | Administraci�n'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesi�n',
            onPressed: () => widget.onSignOut(),
            icon: const Icon(Icons.logout),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _buildDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: _buildContent(theme),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 45, 20, 25),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  child: Icon(Icons.admin_panel_settings, size: 32),
                ),
                SizedBox(height: 14),
                Text(
                  'CUT & GO',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text('Panel de administraci�n general'),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: _sections.length,
              itemBuilder: (context, index) {
                final section = _sections[index];

                return ListTile(
                  selected: _selectedIndex == index,
                  leading: Icon(section.icon),
                  title: Text(section.title),
                  onTap: () {
                    Navigator.pop(context);

                    if (index == 1) {
                      _abrirUsuarios();
                      return;
                    }

                    if (index == 2) {
                      _abrirComercios();
                      return;
                    }

                    if (index == 4) {
                      _abrirCitas();
                      return;
                    }

                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                );
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar sesi�n'),
            onTap: () {
              Navigator.pop(context);
              widget.onSignOut();
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard(theme);

      case 1:
        return _buildModule(
          'Gesti�n de usuarios',
          'Consulta y administra las cuentas registradas en CUT & GO.',
          Icons.people_outline,
          [
            'Consultar usuarios',
            'Revisar roles y permisos',
            'Supervisar el estado de las cuentas',
          ],
        );

      case 2:
        return _buildModule(
          'Gesti�n de comercios',
          'Supervisa los comercios registrados en la plataforma.',
          Icons.store_outlined,
          [
            'Consultar comercios',
            'Revisar informaci�n de los establecimientos',
            'Supervisar su estado',
          ],
        );

      case 3:
        return _buildModule(
          'Gesti�n de barber�as',
          'Administra y supervisa las barber�as registradas.',
          Icons.content_cut,
          [
            'Consultar barber�as',
            'Revisar propietarios',
            'Supervisar establecimientos',
          ],
        );

      case 5:
        return _buildModule(
          'Reportes y estad�sticas',
          'Consulta indicadores generales de la plataforma.',
          Icons.bar_chart_outlined,
          [
            'Actividad de usuarios',
            'Estad�sticas de comercios',
            'Resumen de citas y pedidos',
          ],
        );

      case 6:
        return _buildModule(
          'Configuraci�n general',
          'Administra los par�metros generales de CUT & GO.',
          Icons.settings_outlined,
          [
            'Informaci�n de la plataforma',
            'Par�metros generales',
            'Configuraci�n administrativa',
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDashboard(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Panel de administraci�n',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Bienvenido al centro de control de CUT & GO.',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        Text(
          'Resumen de la plataforma',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 850
                ? 4
                : constraints.maxWidth >= 500
                ? 2
                : 1;

            final cards = [
              _StatItem('Usuarios', Icons.people_outline, _usuariosFuture),
              _StatItem('Comercios', Icons.store_outlined, _comerciosFuture),
              _StatItem('Barber�as', Icons.content_cut, _barberiasFuture),
              _StatItem('Citas', Icons.calendar_month_outlined, _citasFuture),
            ];

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: columns == 1 ? 3.0 : 1.35,
              ),
              itemCount: cards.length,
              itemBuilder: (context, index) {
                final item = cards[index];

                return Card(
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item.icon,
                          size: 28,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 10),
                        Text(item.title, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 5),
                        _buildStatValue(item.count, theme),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 28),
        Text(
          'Accesos administrativos',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _quickAccess(
          'Usuarios',
          'Consultar y supervisar cuentas.',
          Icons.people_outline,
          1,
        ),
        _quickAccess(
          'Comercios',
          'Supervisar establecimientos.',
          Icons.store_outlined,
          2,
        ),
        _quickAccess(
          'Barber�as',
          'Consultar barber�as registradas.',
          Icons.content_cut,
          3,
        ),
        _quickAccess(
          'Citas',
          'Consultar todas las citas registradas.',
          Icons.calendar_month_outlined,
          4,
        ),
        _quickAccess(
          'Reportes',
          'Consultar indicadores generales.',
          Icons.bar_chart_outlined,
          5,
        ),
      ],
    );
  }

  Widget _buildStatValue(Future<int> future, ThemeData theme) {
    return FutureBuilder<int>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        if (snapshot.hasError) {
          return Text('No disponible', style: theme.textTheme.bodySmall);
        }

        return Text(
          '${snapshot.data ?? 0} registros',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        );
      },
    );
  }

  Future<void> _abrirUsuarios() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UsuariosAdminScreen()),
    );
  }

  Future<void> _abrirComercios() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ComerciosAdminScreen()),
    );
  }

  Future<void> _abrirCitas() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdministracionCitasScreen(),
      ),
    );
  }

  Widget _quickAccess(String title, String subtitle, IconData icon, int index) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          if (index == 1) {
            _abrirUsuarios();
            return;
          }

          if (index == 2) {
            _abrirComercios();
            return;
          }

          if (index == 4) {
            _abrirCitas();
            return;
          }

          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildModule(
    String title,
    String description,
    IconData icon,
    List<String> features,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 45, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(description),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Funciones previstas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...features.map(
                  (feature) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.check_circle_outline),
                    title: Text(feature),
                  ),
                ),
                const Divider(),
                const Text(
                  'M�dulo visual. Pendiente de conexi�n con Supabase.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AdminSection {
  const _AdminSection(this.title, this.icon);

  final String title;
  final IconData icon;
}

class _StatItem {
  const _StatItem(this.title, this.icon, this.count);

  final String title;
  final IconData icon;
  final Future<int> count;
}
