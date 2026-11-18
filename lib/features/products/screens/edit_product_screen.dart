import 'package:flutter/material.dart';
import '../services/product_management_service.dart';

class EditProductScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _service = ProductManagementService();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  late final TextEditingController _categoryController;
  late bool _active;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p['name'] ?? '');
    _descriptionController =
        TextEditingController(text: p['description'] ?? '');
    _priceController =
        TextEditingController(text: (p['price'] as num).toString());
    _stockController =
        TextEditingController(text: (p['stock'] as num).toString());
    _categoryController = TextEditingController(text: p['category'] ?? '');
    _active = p['is_active'] == true;
  }

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
      await _service.updateProduct(widget.product['id'] as String, {
        'name': name,
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'price': price,
        'stock': stock,
        'category': _categoryController.text.trim().isEmpty
            ? null
            : _categoryController.text.trim(),
        'is_active': _active,
      });
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
      appBar: AppBar(title: const Text('Editar producto')),
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
          SwitchListTile(
            title: const Text('Producto activo'),
            subtitle: const Text('Si lo desactivas, los clientes no lo verán'),
            value: _active,
            onChanged: (value) => setState(() => _active = value),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Guardando...' : 'Guardar cambios'),
          ),
        ],
      ),
    );
  }
}
