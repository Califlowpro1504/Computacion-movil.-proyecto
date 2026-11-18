import 'package:flutter/material.dart';
import '../services/product_management_service.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _service = ProductManagementService();
  late Future<Map<String, dynamic>?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>?> _load() async {
    final comercio = await _service.getMyComercio();
    if (comercio == null) return null;
    final products = await _service.getProducts(comercio['id'] as String);
    return {'comercio': comercio, 'products': products};
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _changeStock(Map<String, dynamic> product, int delta) async {
    final current = (product['stock'] as num).toInt();
    final next = current + delta;
    if (next < 0) return;
    try {
      await _service.updateStock(product['id'] as String, next);
      _reload();
    } catch (e) {
      _message('No se pudo actualizar el stock: $e');
    }
  }

  Future<void> _openAdd(String comercioId) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddProductScreen(comercioId: comercioId),
      ),
    );
    if (saved == true) _reload();
  }

  Future<void> _openEdit(Map<String, dynamic> product) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProductScreen(product: product),
      ),
    );
    if (saved == true) _reload();
  }

  Widget _body(AsyncSnapshot<Map<String, dynamic>?> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snapshot.hasError) {
      return Center(child: Text('Error: ${snapshot.error}'));
    }
    final data = snapshot.data;
    if (data == null) {
      return const Center(
        child: Text('No tienes un comercio asociado a tu cuenta'),
      );
    }
    final products = List<Map<String, dynamic>>.from(data['products'] as List);
    if (products.isEmpty) {
      return const Center(
        child: Text('Aún no tienes productos. Toca + para agregar uno.'),
      );
    }
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        final p = products[index];
        final stock = (p['stock'] as num).toInt();
        final active = p['is_active'] == true;
        return ListTile(
          title: Text(
            p['name'] ?? '',
            style: TextStyle(color: active ? null : Colors.grey),
          ),
          subtitle: Text(
            'Stock: $stock · ${active ? 'Activo' : 'Inactivo'}',
          ),
          onTap: () => _openEdit(p),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: stock > 0 ? () => _changeStock(p, -1) : null,
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _changeStock(p, 1),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final comercioId = data == null
            ? null
            : (data['comercio'] as Map<String, dynamic>)['id'] as String;
        return Scaffold(
          appBar: AppBar(title: const Text('Inventario')),
          floatingActionButton: comercioId == null
              ? null
              : FloatingActionButton(
                  onPressed: () => _openAdd(comercioId),
                  child: const Icon(Icons.add),
                ),
          body: _body(snapshot),
        );
      },
    );
  }
}
