import 'package:flutter/material.dart';

import '../../data/repositories/barberia_repository_impl.dart';
import '../../domain/entities/barberia.dart';

class EditarBarberiaScreen extends StatefulWidget {
  final Barberia barberia;

  const EditarBarberiaScreen({super.key, required this.barberia});

  @override
  State<EditarBarberiaScreen> createState() => _EditarBarberiaScreenState();
}

class _EditarBarberiaScreenState extends State<EditarBarberiaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _direccionController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _imagenController = TextEditingController();

  final _repository = BarberiaRepositoryImpl();

  bool _guardando = false;

  @override
  void initState() {
    super.initState();

    _nombreController.text = widget.barberia.nombre;
    _direccionController.text = widget.barberia.direccion;
    _telefonoController.text = widget.barberia.telefono;
    _imagenController.text = widget.barberia.imagen;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    _imagenController.dispose();
    super.dispose();
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    try {
      final barberiaActualizada = Barberia(
        id: widget.barberia.id,
        nombre: _nombreController.text.trim(),
        direccion: _direccionController.text.trim(),
        telefono: _telefonoController.text.trim(),
        imagen: _imagenController.text.trim(),
        activa: widget.barberia.activa,
      );

      await _repository.actualizarBarberia(barberiaActualizada);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Barbería actualizada correctamente')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron guardar los cambios: $e')),
      );
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
    TextInputType? tipo,
    String? Function(String?)? validator,
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
            (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Este campo es obligatorio';
              }
              return null;
            },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar barbería')),
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
                'Actualizar información',
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

              ElevatedButton.icon(
                onPressed: _guardando ? null : _guardarCambios,
                icon: const Icon(Icons.save),
                label: Text(_guardando ? 'Guardando...' : 'Guardar cambios'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
