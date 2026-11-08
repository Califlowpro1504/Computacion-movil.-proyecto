import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/product_service.dart';
import '../../cart/services/cart_service.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  Future<void> _addToCart(
      BuildContext context, Map<String, dynamic> product) async {
    final messenger = ScaffoldMessenger.of(context);

    if (Supabase.instance.client.auth.currentUser == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Inicia sesión para agregar productos al carrito'),
        ),
      );
      return;
    }

    try {
      await CartService().addToCart(product['id'] as String);
      messenger.showSnackBar(
        SnackBar(content: Text('${product['name']} agregado al carrito')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('No se pudo agregar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Productos')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: ProductService().getProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final products = snapshot.data ?? [];
          if (products.isEmpty) {
            return const Center(child: Text('No hay productos'));
          }
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, i) {
              final p = products[i];
              final price = (p['price'] as num).toStringAsFixed(0);
              final stock = (p['stock'] as num?) ?? 0;
              return ListTile(
                title: Text(p['name'] ?? ''),
                subtitle: Text(
                  stock > 0
                      ? (p['description'] ?? '')
                      : 'Agotado',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('\$$price'),
                    IconButton(
                      icon: const Icon(Icons.add_shopping_cart),
                      onPressed:
                          stock > 0 ? () => _addToCart(context, p) : null,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
