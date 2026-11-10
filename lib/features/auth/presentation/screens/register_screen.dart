import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/auth_panel.dart';
import '../validators/auth_validators.dart';
import '../../data/repositories/auth_repository_impl.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _confirmacionKey = GlobalKey<FormFieldState<String>>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _correoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmacionController = TextEditingController();

  final _authRepository = AuthRepositoryImpl();

  bool _obscurePassword = true;
  bool _obscureConfirmacion = true;
  bool _terminosAceptados = false;
  bool _cargando = false;
  String? _errorTerminos;

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    _confirmacionController.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    setState(() => _errorTerminos = AuthValidators.validarTerminos(_terminosAceptados));

    final formValido = _formKey.currentState!.validate();
    if (!formValido || _errorTerminos != null) return;

    setState(() => _cargando = true);

    try {
      await _authRepository.register(
        nombre: _nombreController.text.trim(),
        apellido: _apellidoController.text.trim(),
        correo: _correoController.text.trim(),
        telefono: _telefonoController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tu cuenta ha sido creada correctamente.')),
      );
      Navigator.of(context).pop(); // vuelve al login
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: AuthPanel(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AuthHeading(
                  title: 'Crea tu cuenta',
                  subtitle: 'Un nuevo capítulo para tu estilo.',
                ),
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: AuthValidators.validarNombre,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _apellidoController,
                  decoration: const InputDecoration(
                    labelText: 'Apellido',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: AuthValidators.validarApellido,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _correoController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.alternate_email),
                  ),
                  validator: AuthValidators.validarCorreo,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _telefonoController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Número de teléfono',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: AuthValidators.validarTelefono,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  autocorrect: false,
                  enableSuggestions: false,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  onChanged: (_) {
                    if (_confirmacionController.text.isNotEmpty) {
                      _confirmacionKey.currentState?.validate();
                    }
                  },
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    helperText: 'Mínimo 12 caracteres. Puedes usar una frase con espacios.\nEvita contraseñas comunes o caracteres repetidos.',
                    helperMaxLines: 3,
                    errorMaxLines: 3,
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword ? 'Mostrar contraseña' : 'Ocultar contraseña',
                      icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: AuthValidators.validarPassword,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  key: _confirmacionKey,
                  controller: _confirmacionController,
                  autocorrect: false,
                  enableSuggestions: false,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  obscureText: _obscureConfirmacion,
                  decoration: InputDecoration(
                    labelText: 'Confirmar contraseña',
                    prefixIcon: const Icon(Icons.verified_user_outlined),
                    suffixIcon: IconButton(
                      tooltip: _obscureConfirmacion ? 'Mostrar confirmación' : 'Ocultar confirmación',
                      icon: Icon(_obscureConfirmacion ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscureConfirmacion = !_obscureConfirmacion),
                    ),
                  ),
                  validator: (value) => AuthValidators.validarConfirmacion(
                    _passwordController.text,
                    value,
                  ),
                ),
                const SizedBox(height: 16),

                CheckboxListTile(
                  value: _terminosAceptados,
                  onChanged: (value) {
                    setState(() {
                      _terminosAceptados = value ?? false;
                      _errorTerminos = null;
                    });
                  },
                  title: const Text('Acepto los términos y condiciones'),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                if (_errorTerminos != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(
                      _errorTerminos!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _cargando ? null : _registrar,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _cargando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.background),
                        )
                      : const Text('Crear cuenta'),
                ),
                const SizedBox(height: 12),

                TextButton(
                  onPressed: _cargando ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
        ),
      ),
    );
  }
}