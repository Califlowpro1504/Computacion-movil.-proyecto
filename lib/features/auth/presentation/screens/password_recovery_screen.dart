import 'package:flutter/material.dart';

import '../../../../core/widgets/auth_panel.dart';
import '../validators/auth_validators.dart';

class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen.request({
    super.key,
    required this.onSubmit,
    this.initialEmail = '',
  }) : onCancel = null;

  const PasswordRecoveryScreen.reset({
    super.key,
    required this.onSubmit,
    required this.onCancel,
  }) : initialEmail = '';

  final Future<void> Function(String) onSubmit;
  final Future<void> Function()? onCancel;
  final String initialEmail;

  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final _form = GlobalKey<FormState>();
  late final _value = TextEditingController(text: widget.initialEmail);
  bool _busy = false;
  String? _message;

  bool get _reset => widget.onCancel != null;

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action, {String? success}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await action();
      if (mounted) setState(() => _message = success);
    } catch (_) {
      if (mounted) {
        setState(
          () => _message =
              'No pudimos completar la operación. Inténtalo de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    _run(
      () => widget.onSubmit(_reset ? _value.text : _value.text.trim()),
      success: _reset ? null : 'Si la cuenta existe, recibirás un enlace. Ábrelo desde el mismo dispositivo y navegador donde lo solicitaste.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_reset ? 'Nueva contraseña' : 'Recuperar contraseña'),
        ),
        body: AuthPanel(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _value,
                  enabled: !_busy,
                  keyboardType: _reset
                      ? TextInputType.visiblePassword
                      : TextInputType.emailAddress,
                  obscureText: _reset,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText: _reset
                        ? 'Nueva contraseña'
                        : 'Correo electrónico',
                  ),
                  validator: _reset
                      ? AuthValidators.validarPassword
                      : AuthValidators.validarCorreo,
                ),
                if (_reset) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    enabled: !_busy,
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(
                      labelText: 'Confirma tu contraseña',
                    ),
                    validator: (value) =>
                        AuthValidators.validarConfirmacion(_value.text, value),
                  ),
                ],
                const SizedBox(height: 16),
                if (_message case final message?)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Semantics(liveRegion: true, child: Text(message)),
                  ),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: Text(
                    _busy
                        ? 'Procesando…'
                        : _reset
                        ? 'Guardar contraseña'
                        : 'Enviar enlace',
                  ),
                ),
                if (widget.onCancel case final cancel?)
                  TextButton(
                    onPressed: _busy ? null : () => _run(cancel),
                    child: const Text('Cancelar y cerrar sesión'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
