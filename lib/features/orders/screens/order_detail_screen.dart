import 'package:flutter/material.dart';
import '../services/order_service.dart';

class OrderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _service = OrderService();
  late Future<List<Map<String, dynamic>>> _items;
  late String _status;
  bool _rated = false;

  @override
  void initState() {
    super.initState();
    _status = widget.order['status'] as String;
    _items = _service.getOrderItems(widget.order['id'] as String);
    _checkRated();
  }

  Future<void> _checkRated() async {
    final rated = await _service.hasRated(widget.order['id'] as String);
    if (mounted) setState(() => _rated = rated);
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _cancel() async {
    try {
      await _service.cancelOrder(widget.order['id'] as String);
      if (!mounted) return;
      setState(() => _status = 'cancelado');
      _message('Pedido cancelado');
    } catch (e) {
      if (!mounted) return;
      _message('No se pudo cancelar: $e');
    }
  }

  Future<void> _rate() async {
    int score = 5;
    final commentController = TextEditingController();

    final send = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Califica al comercio'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return IconButton(
                    icon: Icon(i < score ? Icons.star : Icons.star_border),
                    onPressed: () => setLocal(() => score = i + 1),
                  );
                }),
              ),
              TextField(
                controller: commentController,
                decoration:
                    const InputDecoration(hintText: 'Comentario (opcional)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Enviar'),
            ),
          ],
        ),
      ),
    );

    if (send != true) return;

    try {
      await _service.rateOrder(
        orderId: widget.order['id'] as String,
        comercioId: widget.order['comercio_id'] as String,
        score: score,
        comment: commentController.text.trim().isEmpty
            ? null
            : commentController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _rated = true);
      _message('¡Gracias por tu calificación!');
    } catch (e) {
      if (!mounted) return;
      _message('No se pudo calificar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = (widget.order['total'] as num).toStringAsFixed(0);
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del pedido')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Estado: $_status'),
                Text('Total: \$$total',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _items,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final items = snapshot.data ?? [];
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final name = item['products']?['name'] ?? '';
                    final qty = item['quantity'];
                    final subtotal =
                        ((item['subtotal'] as num?) ?? 0).toStringAsFixed(0);
                    return ListTile(
                      title: Text(name),
                      subtitle: Text('Cantidad: $qty'),
                      trailing: Text('\$$subtotal'),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (_status == 'pendiente')
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _cancel,
                      child: const Text('Cancelar pedido'),
                    ),
                  ),
                if (_status == 'entregado' && !_rated)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _rate,
                      child: const Text('Calificar comercio'),
                    ),
                  ),
                if (_status == 'entregado' && _rated)
                  const Text('Ya calificaste este pedido'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
