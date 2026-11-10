import 'package:flutter/material.dart';

import '../../../barberias/presentation/screens/barberias_screen.dart';
import '../../../barberias/presentation/screens/panel_propietario_screen.dart';
import '../../../citas/presentation/screens/reservar_cita_screen.dart';
import '../../../citas/presentation/screens/mis_citas_screen.dart';
import '../../../cart/screens/cart_screen.dart';
import '../../../orders/screens/orders_screen.dart';
import '../../../notifications/screens/notifications_screen.dart';
import '../../../products/screens/products_screen.dart';
import '../../../products/screens/inventory_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.email,
    required this.onSignOut,
  });

  final String? email;
  final Future<void> Function() onSignOut;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _signingOut = false;
  String? _error;

  Future<void> _openPage(Widget page) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  Future<void> _signOut() async {
    setState(() {
      _signingOut = true;
      _error = null;
    });

    try {
      await widget.onSignOut();
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'No pudimos cerrar la sesión. Inténtalo de nuevo.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _signingOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text(
          'CUT & GO',
          style: TextStyle(
            fontFamily: 'serif',
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            fontSize: 23,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Mi cuenta',
            onPressed: () => setState(() => _selectedIndex = 1),
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      body: _selectedIndex == 0 ? _buildHome() : _buildAccount(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Mi cuenta',
          ),
        ],
      ),
    );
  }

  Widget _buildHome() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.content_cut,
                color: Colors.white,
                size: 38,
              ),
              const SizedBox(height: 14),
              const Text(
                '¡Bienvenido a CUT & GO!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Encuentra barberías, reserva citas y descubre productos.',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Explora nuestros servicios',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        _ActionTile(
          icon: Icons.storefront,
          title: 'Explorar barberías',
          subtitle: 'Conoce las barberías disponibles',
          onTap: () => _openPage(const BarberiasScreen()),
        ),
        _ActionTile(
          icon: Icons.calendar_month,
          title: 'Reservar una cita',
          subtitle: 'Selecciona barbería, servicio y horario',
          onTap: () => _openPage(const ReservarCitaScreen()),
        ),
        _ActionTile(
          icon: Icons.event_note,
          title: 'Mis citas',
          subtitle: 'Consulta y administra tus reservas',
          onTap: () => _openPage(const MisCitasScreen()),
        ),
        const SizedBox(height: 20),
        Text(
          'Tienda y pedidos',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        _ActionTile(
          icon: Icons.shopping_bag_outlined,
          title: 'Productos',
          subtitle: 'Explora los productos disponibles',
          onTap: () => _openPage(const ProductsScreen()),
        ),
        _ActionTile(
          icon: Icons.shopping_cart_outlined,
          title: 'Mi carrito',
          subtitle: 'Revisa los productos que agregaste',
          onTap: () => _openPage(const CartScreen()),
        ),
        _ActionTile(
          icon: Icons.receipt_long,
          title: 'Mis pedidos',
          subtitle: 'Consulta el estado de tus pedidos',
          onTap: () => _openPage(const OrdersScreen()),
        ),
        _ActionTile(
          icon: Icons.notifications_outlined,
          title: 'Notificaciones',
          subtitle: 'Revisa tus novedades',
          onTap: () => _openPage(const NotificationsScreen()),
        ),
      ],
    );
  }

  Widget _buildAccount() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const CircleAvatar(
          radius: 38,
          child: Icon(Icons.person, size: 40),
        ),
        const SizedBox(height: 14),
        Text(
          'Mi cuenta',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(
          widget.email ?? 'Correo no disponible',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        Text(
          'Administración del comercio',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        _ActionTile(
          icon: Icons.store,
          title: 'Panel de propietario',
          subtitle: 'Administra tus barberías y servicios',
          onTap: () => _openPage(const PanelPropietarioScreen()),
        ),
        _ActionTile(
          icon: Icons.inventory_2_outlined,
          title: 'Inventario',
          subtitle: 'Administra los productos de tu comercio',
          onTap: () => _openPage(const InventoryScreen()),
        ),
        const SizedBox(height: 20),
        if (_error != null) ...[
          Text(
            _error!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 12),
        ],
        FilledButton.icon(
          onPressed: _signingOut ? null : _signOut,
          icon: _signingOut
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.logout),
          label: Text(
            _signingOut ? 'Cerrando sesión...' : 'Cerrar sesión',
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(icon),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
