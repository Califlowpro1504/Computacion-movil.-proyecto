import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/widgets/auth_panel.dart';
import '../../marketplace/data/marketplace_service.dart';

const _fields = [
  ('nombre', 'Nombre', 100),
  ('descripcion', 'Descripción', 2000),
  ('direccion', 'Dirección', 200),
  ('telefono', 'Teléfono', 15),
  ('imagen', 'URL del logo (HTTPS, opcional)', 500),
  ('categoria', 'Categoría', 80),
  ('zona', 'Barrio o zona', 80),
  ('horario', 'Horario', 250),
];

class CommerceRequestsScreen extends StatefulWidget {
  const CommerceRequestsScreen({super.key, required this.service})
    : review = false,
      onSignOut = null;

  const CommerceRequestsScreen.review({
    super.key,
    required this.service,
    this.onSignOut,
  }) : review = true;

  final bool review;
  final MarketplaceService service;
  final Future<void> Function()? onSignOut;

  @override
  State<CommerceRequestsScreen> createState() => _CommerceRequestsScreenState();
}

class _CommerceRequestsScreenState extends State<CommerceRequestsScreen> {
  bool get _review => widget.review;
  late Future<List<CommerceData>> _requests = widget.service.requests(
    review: _review,
  );
  bool _closing = false;

  void _reload() =>
      setState(() => _requests = widget.service.requests(review: _review));

  Future<void> _open({CommerceData? request}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _review
            ? _ReviewRequest(service: widget.service, request: request!)
            : _CommerceForm(service: widget.service, request: request),
      ),
    );
    if (mounted && changed == true) _reload();
  }

  Future<void> _signOut() async {
    setState(() => _closing = true);
    try {
      await widget.onSignOut!();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No pudimos cerrar la sesión. Reintenta.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _closing = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_review ? 'Revisar solicitudes' : 'Mis comercios'),
      actions: [
        if (widget.onSignOut != null)
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: _closing ? null : _signOut,
            icon: const Icon(Icons.logout),
          ),
        IconButton(
          tooltip: 'Actualizar',
          onPressed: _reload,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: FutureBuilder(
      future: _requests,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('No pudimos cargar las solicitudes.'),
                TextButton(onPressed: _reload, child: const Text('Reintentar')),
              ],
            ),
          );
        }
        final rows = snapshot.requireData;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!_review)
              FilledButton.icon(
                onPressed: () => _open(),
                icon: const Icon(Icons.add),
                label: const Text('Registrar mi comercio'),
              ),
            if (rows.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _review
                      ? 'No hay solicitudes pendientes.'
                      : 'Todavía no tienes solicitudes.',
                ),
              ),
            for (final row in rows)
              Card(
                child: ListTile(
                  title: Text(row['nombre'] as String),
                  subtitle: Text(
                    [
                      row['estado'],
                      row['observacion'],
                      if (row['revisada_en'] case final String reviewed)
                        'Revisada el ${MaterialLocalizations.of(context).formatCompactDate(DateTime.parse(reviewed).toLocal())}',
                      if (row['estado'] == 'aprobada' &&
                          row['comercio_id'] == null)
                        'Comercio no disponible',
                    ].whereType<String>().join('\n'),
                  ),
                  trailing: _review || row['comercio_id'] != null
                      ? const Icon(Icons.chevron_right)
                      : null,
                  onTap: _review || row['comercio_id'] != null
                      ? () => _open(request: row)
                      : null,
                ),
              ),
          ],
        );
      },
    ),
  );
}

class _CommerceForm extends StatefulWidget {
  const _CommerceForm({required this.service, required this.request});

  final MarketplaceService service;
  final CommerceData? request;

  @override
  State<_CommerceForm> createState() => _CommerceFormState();
}

class _CommerceFormState extends State<_CommerceForm> {
  final _form = GlobalKey<FormState>();
  late final _controllers = {
    for (final (key, _, _) in _fields)
      key: TextEditingController(text: widget.request?[key] as String?),
  };
  late String _type = widget.request?['tipo'] as String? ?? commerceTypes.first;
  late bool _visible = widget.request?['visible'] as bool? ?? true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _validate(String field, String? text) {
    final value = text?.trim() ?? '';
    if (field == 'imagen') {
      if (value.isEmpty) return null;
      final uri = Uri.tryParse(value);
      if (uri == null ||
          uri.scheme != 'https' ||
          uri.host.isEmpty ||
          uri.userInfo.isNotEmpty ||
          RegExp(r'\s').hasMatch(value)) {
        return 'Ingresa una URL HTTPS válida.';
      }
    }
    if (value.isEmpty) return 'Completa este campo.';
    if (field == 'telefono' && !RegExp(r'^[0-9]{7,15}$').hasMatch(value)) {
      return 'Ingresa de 7 a 15 dígitos.';
    }
    return null;
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final fields = <String, dynamic>{
      for (final entry in _controllers.entries)
        entry.key: entry.value.text.trim(),
      'tipo': _type,
    };
    if (fields['imagen'] == '') fields['imagen'] = null;
    try {
      final request = widget.request;
      if (request == null) {
        await widget.service.submit(fields);
      } else {
        await widget.service.update(request['id'] as String, {
          ...fields,
          'visible': _visible,
          'version': request['version'],
        });
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            request == null
                ? 'Solicitud enviada para revisión.'
                : 'Cambios guardados.',
          ),
        ),
      );
      Navigator.pop(context, true);
    } on PostgrestException catch (error) {
      if (mounted) {
        setState(
          () => _error = switch (error.code) {
            '23505' => 'Ya tienes una solicitud pendiente con ese nombre.',
            '40001' => 'El comercio cambió. Vuelve a la lista y actualízala antes de editar.',
            _ => 'No pudimos guardar. Revisa los datos e inténtalo de nuevo.',
          },
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'No pudimos guardar. Comprueba la conexión e inténtalo de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          widget.request == null ? 'Registrar comercio' : 'Editar comercio',
        ),
      ),
      body: AuthPanel(
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (key, label, length) in _fields)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextFormField(
                    controller: _controllers[key],
                    enabled: !_saving,
                    decoration: InputDecoration(labelText: label),
                    maxLength: length,
                    maxLines: key == 'descripcion' ? 3 : 1,
                    keyboardType: switch (key) {
                      'telefono' => TextInputType.phone,
                      'imagen' => TextInputType.url,
                      _ => TextInputType.text,
                    },
                    validator: (value) => _validate(key, value),
                  ),
                ),
              DropdownButtonFormField<String>(
                initialValue: _type,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Tipo de comercio',
                ),
                items: commerceTypes
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
                onChanged: _saving ? null : (value) => _type = value!,
              ),
              if (widget.request != null)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Visible en el marketplace'),
                  value: _visible,
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _visible = value),
                ),
              const SizedBox(height: 16),
              if (_error case final error?) Text(error),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Guardando…' : 'Guardar'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ReviewRequest extends StatefulWidget {
  const _ReviewRequest({required this.service, required this.request});
  final MarketplaceService service;
  final CommerceData request;

  @override
  State<_ReviewRequest> createState() => _ReviewRequestState();
}

class _ReviewRequestState extends State<_ReviewRequest> {
  final _notes = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save(bool approved) async {
    if (_saving) return;
    if (!approved && _notes.text.trim().isEmpty) {
      setState(() => _error = 'Indica el motivo del rechazo.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.service.review(
        widget.request['id'] as String,
        approved,
        _notes.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } on PostgrestException catch (error) {
      if (!mounted) return;
      setState(
        () => _error = switch (error.code) {
          '55000' => 'La solicitud cambió o la cuenta solicitante está inactiva. Actualiza la lista.',
          '42501' => 'Tu cuenta no tiene permiso para revisar esta solicitud.',
          _ => 'No pudimos guardar la revisión. Inténtalo de nuevo.',
        },
      );
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'No pudimos guardar la revisión. Inténtalo de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: Scaffold(
      appBar: AppBar(title: Text(widget.request['nombre'] as String)),
      body: AuthPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (key, label, _) in _fields)
              if (widget.request[key] case final String value)
                ListTile(title: Text(label), subtitle: Text(value)),
            ListTile(
              title: const Text('Tipo'),
              subtitle: Text(widget.request['tipo'] as String),
            ),
            TextField(
              controller: _notes,
              maxLength: 1000,
              maxLines: 3,
              enabled: !_saving,
              decoration: const InputDecoration(labelText: 'Observación'),
            ),
            if (_error case final error?) Text(error),
            Wrap(
              spacing: 10,
              children: [
                FilledButton(
                  onPressed: _saving ? null : () => _save(true),
                  child: const Text('Aprobar'),
                ),
                OutlinedButton(
                  onPressed: _saving ? null : () => _save(false),
                  child: const Text('Rechazar'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
