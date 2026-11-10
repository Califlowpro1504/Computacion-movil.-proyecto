import 'package:flutter/material.dart';
import '../services/product_service.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

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
              return ListTile(
                title: Text(p['name'] ?? ''),
                subtitle: Text(p['description'] ?? ''),
                trailing: Text('\$$price'),
              );
            },
          );
        },
      ),
    );
  }
}
