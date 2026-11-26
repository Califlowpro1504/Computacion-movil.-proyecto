import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../commerce_management/presentation/commerce_requests_screen.dart';
import '../../../marketplace/data/marketplace_service.dart';
import '../../../marketplace/presentation/marketplace_catalog.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.email,
    required this.onSignOut,
    this.marketplace,
  });

  final MarketplaceService? marketplace;
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
        setState(
          () => _error = 'No pudimos cerrar la sesión. Inténtalo de nuevo.',
        );
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
            tooltip: 'Ver mi cuenta',
            onPressed: () => setState(() => _selectedIndex = 1),
            icon: const Icon(
              Icons.account_circle_outlined,
              color: AppTheme.accent,
            ),
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
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
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
        const Text(
          'Bienvenido a tu próximo estilo',
          style: TextStyle(color: AppTheme.muted, fontSize: 13),
        ),
        const SizedBox(height: 8),
        const Text(
          'Descubre lo local.',
          style: TextStyle(
            fontSize: 30,
            height: 1.2,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (widget.marketplace case final service?)
          MarketplaceCatalog(service: service),
        const SizedBox(height: 24),
        const Row(
          children: [
            Icon(
              Icons.verified_user_outlined,
              size: 16,
              color: AppTheme.accent,
            ),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Sesión iniciada',
                style: TextStyle(color: AppTheme.muted, fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAccount() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Mi cuenta',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tu espacio en CUT & GO',
          style: TextStyle(color: AppTheme.muted),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
            );
          },
          icon: const Icon(Icons.person_outline),
          label: const Text('Ver mi perfil'),
        ),
        if (widget.marketplace case final service?)
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CommerceRequestsScreen(service: service),
              ),
            ),
            icon: const Icon(Icons.storefront_outlined),
            label: const Text('Mis comercios'),
          ),
        const SizedBox(height: 24),
        _Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.elevated,
                  child: Icon(
                    Icons.person_outline,
                    size: 30,
                    color: AppTheme.accent,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Sesión iniciada',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
              ),
              if (widget.email != null) ...[
                const SizedBox(height: 8),
                Text(
                  widget.email!,
                  style: const TextStyle(color: AppTheme.muted),
                ),
              ],
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              if (_error != null) ...[
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 16),
              ],
              ElevatedButton.icon(
                onPressed: _signingOut ? null : _signOut,
                icon: _signingOut
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.background,
                        ),
                      )
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
