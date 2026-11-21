import 'package:flutter/material.dart';
import '../../products/services/product_management_service.dart';
import '../services/merchant_order_service.dart';

class MerchantOrdersScreen extends StatefulWidget {
  const MerchantOrdersScreen({super.key});

  @override
  State<MerchantOrdersScreen> createState() => _MerchantOrdersScreenState();
}

class _MerchantOrdersScreenState extends State<MerchantOrdersScreen> {
  final _comercioService = ProductManagementService();
  final _service = MerchantOrderService();
  late Future<List<Map<String, dynamic>>?> _future;

  static const _labels = {
    'confirmado': 'Confirmar',
    'en_camino': 'Marcar en camino',
    'entregado': 'Marcar entregado',
    'cancelado': 'Cancelar',
  };

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>?> _load() async {
    final comercio = await _comercioService.getMyComercio();
    if (comercio == null) return null;
    return _service.getOrders(comercio['id'] as String);
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  List<String> _nextStatuses(String status) {
    switch (status) {
      case 'pendiente':
        return ['confirmado', 'cancelado'];
      case 'confirmado':
        return ['en_camino', 'cancelado'];
      case 'en_camino':
        return ['entregado'];
      default:
        return [];
    }
  }

  Future<void> _changeStatus(String orderId, String status) async {
    try {
      await _service.updateStatus(orderId, status);
      if (!mounted) return;
      _message('Pedido actualizado');
      _reload();
    } catch (e) {
      if (!mounted) return;
      _message('No se pudo actualizar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pedidos recibidos')),
      body: FutureBuilder<List<Map<String, dynamic>>?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final orders = snapshot.data;
          if (orders == null) {
            return const Center(
              child: Text('No tienes un comercio asociado a tu cuenta'),
            );
          }
          if (orders.isEmpty) {
            return const Center(child: Text('Aún no has recibido pedidos'));
          }
          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final id = order['id'] as String;
              final status = order['status'] as String;
              final total = (order['total'] as num).toStringAsFixed(0);
              final actions = _nextStatuses(status);
              return ExpansionTile(
                title: Text('Pedido ${id.substring(0, 8)}'),
                subtitle: Text('Estado: ${status.replaceAll('_', ' ')}'),
                trailing: Text(
                  '\$$total',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                children: [
                  _OrderItemsList(orderId: id, service: _service),
                  if (actions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: actions.map((next) {
                          final isCancel = next == 'cancelado';
                          final label = _labels[next] ?? next;
                          return isCancel
                              ? OutlinedButton(
                                  onPressed: () => _changeStatus(id, next),
                                  child: Text(label),
                                )
                              : ElevatedButton(
                                  onPressed: () => _changeStatus(id, next),
                                  child: Text(label),
                                );
                        }).toList(),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _OrderItemsList extends StatefulWidget {
  final String orderId;
  final MerchantOrderService service;

  const _OrderItemsList({required this.orderId, required this.service});

  @override
  State<_OrderItemsList> createState() => _OrderItemsListState();
}

class _OrderItemsListState extends State<_OrderItemsList> {
  late Future<List<Map<String, dynamic>>> _items;

  @override
  void initState() {
    super.initState();
    _items = widget.service.getOrderItems(widget.orderId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _items,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Error: ${snapshot.error}'),
          );
        }
        final items = snapshot.data ?? [];
        return Column(
          children: items.map((item) {
            final name = item['products']?['name'] ?? '';
            final qty = item['quantity'];
            final subtotal =
                ((item['subtotal'] as num?) ?? 0).toStringAsFixed(0);
            return ListTile(
              dense: true,
              title: Text(name),
              subtitle: Text('Cantidad: $qty'),
              trailing: Text('\$$subtotal'),
            );
          }).toList(),
        );
      },
    );
  }
}
