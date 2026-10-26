import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

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
  int _selectedIndex = 0;

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
      appBar: AppBar(
        centerTitle: false,
        title: const Text('CUT & GO', style: TextStyle(
          fontFamily: 'serif', fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w700, letterSpacing: 1.5, fontSize: 23,
        )),
        actions: [
          IconButton(
            tooltip: 'Ver mi cuenta',
            onPressed: () => setState(() => _selectedIndex = 1),
            icon: const Icon(Icons.account_circle_outlined, color: AppTheme.accent),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: _selectedIndex == 0 ? _buildHome() : _buildAccount(),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Bienvenido a tu próximo estilo',
          style: TextStyle(color: AppTheme.muted, fontSize: 13)),
        const SizedBox(height: 8),
        const Text('Descubre lo local.', style: TextStyle(
          fontSize: 30, height: 1.2, fontWeight: FontWeight.w700,
        )),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
            gradient: const LinearGradient(
              colors: [Color(0xFF263C46), AppTheme.surface],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.content_cut, size: 36, color: AppTheme.accent),
              const SizedBox(height: 24),
              const Text('Tu estilo.\nTu comunidad.', style: TextStyle(
                fontFamily: 'serif', fontSize: 32, height: 1.15,
                fontWeight: FontWeight.w700, color: AppTheme.ivory,
              )),
              const SizedBox(height: 12),
              const Text('Comercios, productos y experiencias\nen un solo lugar.',
                style: TextStyle(color: AppTheme.muted, height: 1.6)),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: const [
                  _Tag(icon: Icons.auto_awesome_outlined, label: 'Estilo propio'),
                  _Tag(icon: Icons.storefront_outlined, label: 'Talento local'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const Text('Un mundo por descubrir', style: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w600,
        )),
        const SizedBox(height: 6),
        const Text('Próximamente en CUT & GO',
          style: TextStyle(color: AppTheme.muted, fontSize: 13)),
        const SizedBox(height: 16),
        const Wrap(
          spacing: 10, runSpacing: 10,
          children: [
            _Tag(icon: Icons.content_cut, label: 'Barberías'),
            _Tag(icon: Icons.spa_outlined, label: 'Belleza'),
            _Tag(icon: Icons.shopping_bag_outlined, label: 'Tiendas'),
            _Tag(icon: Icons.handyman_outlined, label: 'Servicios'),
          ],
        ),
        const SizedBox(height: 24),
        const _Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.storefront_outlined, color: AppTheme.accent, size: 28),
              SizedBox(height: 12),
              Text('Estamos preparando el catálogo', style: TextStyle(
                fontWeight: FontWeight.w600, fontSize: 16,
              )),
              SizedBox(height: 8),
              Text('Aquí descubrirás comercios y sus novedades cuando estén disponibles.',
                style: TextStyle(color: AppTheme.muted, height: 1.6)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Row(children: [
          Icon(Icons.verified_user_outlined, size: 16, color: AppTheme.accent),
          SizedBox(width: 8),
          Flexible(child: Text('Sesión iniciada',
            style: TextStyle(color: AppTheme.muted, fontSize: 12))),
        ]),
      ],
    );
  }

  Widget _buildAccount() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Mi cuenta', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text('Tu espacio en CUT & GO', style: TextStyle(color: AppTheme.muted)),
        const SizedBox(height: 24),
        _Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: CircleAvatar(
                  radius: 28, backgroundColor: AppTheme.elevated,
                  child: Icon(Icons.person_outline, size: 30, color: AppTheme.accent),
                ),
              ),
              const SizedBox(height: 18),
              const Text('Sesión iniciada',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
              if (widget.email != null) ...[
                const SizedBox(height: 8),
                Text(widget.email!, style: const TextStyle(color: AppTheme.muted)),
              ],
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              if (_error != null) ...[
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                const SizedBox(height: 16),
              ],
              ElevatedButton.icon(
                onPressed: _signingOut ? null : _signOut,
                icon: _signingOut
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppTheme.background,
                        ))
                    : const Icon(Icons.logout),
                label: Text(_signingOut ? 'Cerrando sesión…' : 'Cerrar sesión'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.elevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppTheme.accent),
          const SizedBox(width: 8),
          Flexible(child: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.ivory))),
        ],
      ),
    );
  }
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: child,
    );
  }
}
