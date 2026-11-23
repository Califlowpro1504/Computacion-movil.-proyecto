import 'package:flutter/material.dart';

import '../../data/services/profile_service.dart';
import '../../../auth/presentation/validators/auth_validators.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.profile, this.saveProfile});

  final Map<String, dynamic> profile;

  final Future<void> Function(String nombre, String apellido, String telefono)?
  saveProfile;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombreController;
  late final TextEditingController _apellidoController;
  late final TextEditingController _telefonoController;

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    _nombreController = TextEditingController(
      text: widget.profile['nombre']?.toString() ?? '',
    );
    _apellidoController = TextEditingController(
      text: widget.profile['apellido']?.toString() ?? '',
    );
    _telefonoController = TextEditingController(
      text: widget.profile['telefono']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final nombre = _nombreController.text.trim();
    final apellido = _apellidoController.text.trim();
    final telefono = _telefonoController.text.trim();

    try {
      final save = widget.saveProfile;

      if (save != null) {
        await save(nombre, apellido, telefono);
      } else {
        await ProfileService().actualizarMisDatos(
          nombre: nombre,
          apellido: apellido,
          telefono: telefono,
        );
      }

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'No pudimos guardar los cambios. Inténtalo nuevamente.';
      });
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(title: const Text('Editar perfil')),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Actualiza tus datos personales',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _nombreController,
                        enabled: !_saving,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: AuthValidators.validarNombre,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _apellidoController,
                        enabled: !_saving,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Apellido',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: AuthValidators.validarApellido,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _telefonoController,
                        enabled: !_saving,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono',
                          helperText: 'Entre 7 y 15 dígitos, sin espacios.',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        validator: AuthValidators.validarTelefono,
                      ),
                      const SizedBox(height: 24),
                      if (_error != null) ...[
                        Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      ElevatedButton(
                        onPressed: _saving ? null : _save,
                        child: Text(_saving ? 'Guardando…' : 'Guardar cambios'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _saving
                            ? null
                            : () => Navigator.of(context).pop(false),
                        child: const Text('Cancelar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
