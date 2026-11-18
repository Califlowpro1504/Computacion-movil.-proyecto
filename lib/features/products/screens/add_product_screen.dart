import 'package:flutter/material.dart';
import '../services/product_management_service.dart';

class AddProductScreen extends StatefulWidget {
  final String comercioId;

  const AddProductScreen({super.key, required this.comercioId});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _service = ProductManagementService();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _categoryController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.trim());
    final stock = int.tryParse(_stockController.text.trim());

    if (name.isEmpty) {
      _message('El nombre es obligatorio');
      return;
    }
    if (price == null || price < 0) {
      _message('Ingresa un precio válido');
      return;
    }
    if (stock == null || stock < 0) {
      _message('Ingresa un stock válido');
      return;
    }

    setState(() => _saving = true);
    try {
      await _service.createProduct(
        comercioId: widget.comercioId,
        name: name,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        price: price,
        stock: stock,
        category: _categoryController.text.trim().isEmpty
            ? null
            : _categoryController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _message('No se pudo guardar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar producto')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Nombre'),
          ),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(labelText: 'Descripción'),
            maxLines: 2,
          ),
          TextField(
            controller: _priceController,
            decoration: const InputDecoration(labelText: 'Precio (COP)'),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: _stockController,
            decoration: const InputDecoration(labelText: 'Stock disponible'),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: _categoryController,
            decoration: const InputDecoration(labelText: 'Categoría'),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Guardando...' : 'Guardar producto'),
          ),
        ],
      ),
    );
  }
}
