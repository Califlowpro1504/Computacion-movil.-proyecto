
import 'package:flutter/material.dart';
import '../cart/screens/cart_screen.dart';
import '../notifications/screens/notifications_screen.dart';
import '../orders/screens/merchant_orders_screen.dart';
import '../orders/screens/orders_screen.dart';
import '../products/screens/inventory_screen.dart';
import '../products/screens/products_screen.dart';
import '../products/services/product_management_service.dart';

class ShoppingMenuScreen extends StatefulWidget {
  const ShoppingMenuScreen({super.key});

  @override
  State<ShoppingMenuScreen> createState() => _ShoppingMenuScreenState();
}

class _ShoppingMenuScreenState extends State<ShoppingMenuScreen> {
  late Future<Map<String, dynamic>?> _comercio;

  @override
  void initState() {
    super.initState();
    _comercio = ProductManagementService().getMyComercio();
  }

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Widget _option(IconData icon, String label, Widget screen) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton.icon(
        onPressed: () => _open(screen),
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compras')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _option(Icons.storefront, 'Productos', const ProductsScreen()),
          _option(Icons.shopping_cart, 'Mi carrito', const CartScreen()),
          _option(Icons.receipt_long, 'Mis pedidos', const OrdersScreen()),
          _option(Icons.notifications, 'Notificaciones',
              const NotificationsScreen()),
          FutureBuilder<Map<String, dynamic>?>(
            future: _comercio,
            builder: (context, snapshot) {
              if (snapshot.data == null) return const SizedBox.shrink();
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(height: 32),
                  Text(
                    'Mi comercio',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _option(Icons.inventory_2, 'Inventario',
                      const InventoryScreen()),
                  _option(Icons.local_shipping, 'Pedidos recibidos',
                      const MerchantOrdersScreen()),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
