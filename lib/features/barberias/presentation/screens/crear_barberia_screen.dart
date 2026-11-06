import 'package:flutter/material.dart';

import '../../data/repositories/barberia_repository_impl.dart';
import '../../domain/entities/barberia.dart';

class CrearBarberiaScreen extends StatefulWidget {
  const CrearBarberiaScreen({super.key});

  @override
  State<CrearBarberiaScreen> createState() => _CrearBarberiaScreenState();
}

class _CrearBarberiaScreenState extends State<CrearBarberiaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _direccionController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _imagenController = TextEditingController();

  final _repository = BarberiaRepositoryImpl();

  bool _guardando = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    _imagenController.dispose();
    super.dispose();
  }

  Future<void> _guardarBarberia() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    try {
      final barberia = Barberia(
        id: '',
        nombre: _nombreController.text.trim(),
        direccion: _direccionController.text.trim(),
        telefono: _telefonoController.text.trim(),
        imagen: _imagenController.text.trim(),
        activa: true,
      );

      await _repository.crearBarberia(barberia);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Barbería registrada correctamente')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error al registrar: $e')));
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  Widget _campo({
    required String etiqueta,
    required TextEditingController controller,
    required IconData icono,
    String? Function(String?)? validator,
    TextInputType? tipo,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: tipo,
        decoration: InputDecoration(
          labelText: etiqueta,
          prefixIcon: Icon(icono),
          border: const OutlineInputBorder(),
        ),
        validator:
            validator ??
            (value) => value == null || value.trim().isEmpty
                ? 'Este campo es obligatorio'
                : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar barbería')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.store, size: 65),
              const SizedBox(height: 12),
              const Text(
                'Información de tu barbería',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              _campo(
                etiqueta: 'Nombre de la barbería',
                controller: _nombreController,
                icono: Icons.content_cut,
              ),

              _campo(
                etiqueta: 'Dirección',
                controller: _direccionController,
                icono: Icons.location_on,
              ),

              _campo(
                etiqueta: 'Teléfono',
                controller: _telefonoController,
                icono: Icons.phone,
                tipo: TextInputType.phone,
              ),

              _campo(
                etiqueta: 'URL de imagen (opcional)',
                controller: _imagenController,
                icono: Icons.image,
                validator: (_) => null,
              ),

              const SizedBox(height: 12),

              ElevatedButton(
                onPressed: _guardando ? null : _guardarBarberia,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _guardando
                    ? const CircularProgressIndicator()
                    : const Text('Registrar barbería'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
