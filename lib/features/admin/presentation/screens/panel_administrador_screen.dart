import 'package:flutter/material.dart';

class PanelAdministradorScreen extends StatefulWidget {
  const PanelAdministradorScreen({super.key, required this.onSignOut});

  final Future<void> Function() onSignOut;

  @override
  State<PanelAdministradorScreen> createState() =>
      _PanelAdministradorScreenState();
}

class _PanelAdministradorScreenState extends State<PanelAdministradorScreen> {
  int _selectedIndex = 0;

  final List<_AdminSection> _sections = const [
    _AdminSection('Resumen', Icons.dashboard_outlined),
    _AdminSection('Usuarios', Icons.people_outline),
    _AdminSection('Comercios', Icons.store_outlined),
    _AdminSection('Barberías', Icons.content_cut),
    _AdminSection('Reportes', Icons.bar_chart_outlined),
    _AdminSection('Configuración', Icons.settings_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CUT & GO | Administración'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
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
                Text('Panel de administración general'),
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
                    setState(() => _selectedIndex = index);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar sesión'),
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
          'Gestión de usuarios',
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
          'Gestión de comercios',
          'Supervisa los comercios registrados en la plataforma.',
          Icons.store_outlined,
          [
            'Consultar comercios',
            'Revisar información de los establecimientos',
            'Supervisar su estado',
          ],
        );
      case 3:
        return _buildModule(
          'Gestión de barberías',
          'Administra y supervisa las barberías registradas.',
          Icons.content_cut,
          [
            'Consultar barberías',
            'Revisar propietarios',
            'Supervisar establecimientos',
          ],
        );
      case 4:
        return _buildModule(
          'Reportes y estadísticas',
          'Consulta indicadores generales de la plataforma.',
          Icons.bar_chart_outlined,
          [
            'Actividad de usuarios',
            'Estadísticas de comercios',
            'Resumen de citas y pedidos',
          ],
        );
      case 5:
        return _buildModule(
          'Configuración general',
          'Administra los parámetros generales de CUT & GO.',
          Icons.settings_outlined,
          [
            'Información de la plataforma',
            'Parámetros generales',
            'Configuración administrativa',
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
          'Panel de administración',
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
              _StatItem('Usuarios', Icons.people_outline),
              _StatItem('Comercios', Icons.store_outlined),
              _StatItem('Barberías', Icons.content_cut),
              _StatItem('Citas', Icons.calendar_month_outlined),
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
                        Text(
                          'Pendiente de conexión',
                          style: theme.textTheme.bodySmall,
                        ),
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
          'Barberías',
          'Consultar barberías registradas.',
          Icons.content_cut,
          3,
        ),
        _quickAccess(
          'Reportes',
          'Consultar indicadores generales.',
          Icons.bar_chart_outlined,
          4,
        ),
      ],
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
          setState(() => _selectedIndex = index);
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
                  'Módulo visual. Pendiente de conexión con Supabase.',
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
  const _StatItem(this.title, this.icon);

  final String title;
  final IconData icon;
}
