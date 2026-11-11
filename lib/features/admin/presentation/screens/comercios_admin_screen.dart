import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ComerciosAdminScreen extends StatefulWidget {
  const ComerciosAdminScreen({super.key});

  @override
  State<ComerciosAdminScreen> createState() => _ComerciosAdminScreenState();
}

class _ComerciosAdminScreenState extends State<ComerciosAdminScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _busquedaController = TextEditingController();

  late Future<List<Map<String, dynamic>>> _comerciosFuture;

  String _filtroEstado = 'Todos';
  String _busqueda = '';

  final Set<String> _actualizandoIds = {};

  @override
  void initState() {
    super.initState();
    _comerciosFuture = _cargarComercios();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _cargarComercios() async {
    final barberias = await _supabase
        .from('barberias')
        .select(
          'id, nombre, direccion, telefono, imagen, activa, '
          'propietario_id, created_at',
        )
        .order('created_at', ascending: false);

    final perfiles = await _supabase
        .from('profiles')
        .select('id, nombre, apellido, telefono');

    debugPrint('TOTAL PERFILES: ${perfiles.length}');
    debugPrint('TOTAL BARBERIAS: ${barberias.length}');

    final perfilesPorId = <String, Map<String, dynamic>>{};

    for (final perfil in perfiles) {
      perfilesPorId[perfil['id'].toString()] = Map<String, dynamic>.from(
        perfil,
      );
    }

    final comerciosRelacionados = barberias.map<Map<String, dynamic>>((
      barberia,
    ) {
      final comercio = Map<String, dynamic>.from(barberia);

      final propietarioId = comercio['propietario_id']?.toString() ?? '';

      comercio['propietario'] = perfilesPorId[propietarioId];

      debugPrint(
        'COMERCIO: ${comercio['nombre']} | '
        'PROPIETARIO: ${_nombrePropietario(comercio['propietario'] as Map<String, dynamic>?)}',
      );

      return comercio;
    }).toList();

    debugPrint('TOTAL COMERCIOS RELACIONADOS: ${comerciosRelacionados.length}');

    return comerciosRelacionados;
  }

  Future<void> _recargar() async {
    final nuevaCarga = _cargarComercios();

    setState(() {
      _comerciosFuture = nuevaCarga;
    });

    await nuevaCarga;
  }

  // Cambiar el estado de un establecimiento.
  Future<void> _cambiarEstado(
    Map<String, dynamic> comercio,
    bool nuevoEstado,
  ) async {
    final comercioId = comercio['id']?.toString() ?? '';

    if (comercioId.isEmpty || _actualizandoIds.contains(comercioId)) {
      return;
    }

    final nombre = _texto(comercio['nombre']);

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(nuevoEstado ? 'Activar comercio' : 'Inactivar comercio'),
          content: Text(
            nuevoEstado
                ? '¿Deseas activar "$nombre"? El establecimiento volverá a estar activo.'
                : '¿Deseas inactivar "$nombre"? El establecimiento dejará de estar activo.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: Text(nuevoEstado ? 'Activar' : 'Inactivar'),
            ),
          ],
        );
      },
    );

    if (confirmado != true || !mounted) {
      return;
    }

    setState(() {
      _actualizandoIds.add(comercioId);
    });

    try {
      final resultado = await _supabase
          .from('barberias')
          .update({'activa': nuevoEstado})
          .eq('id', comercioId)
          .select('id')
          .maybeSingle();

      if (resultado == null) {
        throw Exception(
          'No se pudo actualizar el establecimiento. '
          'Verifica los permisos administrativos.',
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nuevoEstado
                ? 'Comercio activado correctamente.'
                : 'Comercio inactivado correctamente.',
          ),
        ),
      );

      await _recargar();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cambiar el estado: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _actualizandoIds.remove(comercioId);
        });
      }
    }
  }

  String _texto(dynamic valor) {
    if (valor == null || valor.toString().trim().isEmpty) {
      return 'No registrado';
    }

    return valor.toString();
  }

  String _nombrePropietario(Map<String, dynamic>? perfil) {
    if (perfil == null) {
      return 'Perfil no encontrado';
    }

    final nombre = perfil['nombre']?.toString() ?? '';
    final apellido = perfil['apellido']?.toString() ?? '';

    final completo = '$nombre $apellido'.trim();

    return completo.isEmpty ? 'Nombre no registrado' : completo;
  }

  List<Map<String, dynamic>> _filtrarComercios(
    List<Map<String, dynamic>> comercios,
  ) {
    final consulta = _busqueda.trim().toLowerCase();

    return comercios.where((comercio) {
      final propietario = comercio['propietario'] as Map<String, dynamic>?;

      final nombre = _texto(comercio['nombre']).toLowerCase();
      final direccion = _texto(comercio['direccion']).toLowerCase();
      final telefono = _texto(comercio['telefono']).toLowerCase();
      final nombrePropietario = _nombrePropietario(propietario).toLowerCase();

      final coincideBusqueda =
          consulta.isEmpty ||
          nombre.contains(consulta) ||
          direccion.contains(consulta) ||
          telefono.contains(consulta) ||
          nombrePropietario.contains(consulta);

      final activo = comercio['activa'] == true;

      final coincideEstado = switch (_filtroEstado) {
        'Activos' => activo,
        'Inactivos' => !activo,
        _ => true,
      };

      return coincideBusqueda && coincideEstado;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de comercios'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _recargar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _comerciosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _construirError(snapshot.error);
          }

          final comercios = snapshot.data ?? [];
          final filtrados = _filtrarComercios(comercios);

          debugPrint('COMERCIOS EN PANTALLA: ${comercios.length}');
          debugPrint('COMERCIOS FILTRADOS: ${filtrados.length}');

          return RefreshIndicator(
            onRefresh: _recargar,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Establecimientos registrados',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Consulta la información de los comercios y sus propietarios.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),

                _construirResumen(comercios),

                const SizedBox(height: 20),

                TextField(
                  controller: _busquedaController,
                  onChanged: (valor) {
                    setState(() {
                      _busqueda = valor;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Buscar comercio o propietario...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _busqueda.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _busquedaController.clear();
                              setState(() {
                                _busqueda = '';
                              });
                            },
                            icon: const Icon(Icons.close),
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Wrap(
                  spacing: 8,
                  children: ['Todos', 'Activos', 'Inactivos'].map((filtro) {
                    return ChoiceChip(
                      label: Text(filtro),
                      selected: _filtroEstado == filtro,
                      onSelected: (_) {
                        setState(() {
                          _filtroEstado = filtro;
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 18),

                if (comercios.isEmpty)
                  _construirVacio(
                    'Todavía no hay establecimientos registrados.',
                  )
                else if (filtrados.isEmpty)
                  _construirVacio(
                    'No se encontraron establecimientos con esos filtros.',
                  )
                else ...[
                  Text(
                    '${filtrados.length} establecimientos encontrados',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...filtrados.map(_construirTarjeta),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _construirResumen(List<Map<String, dynamic>> comercios) {
    final activos = comercios
        .where((comercio) => comercio['activa'] == true)
        .length;

    final inactivos = comercios.length - activos;

    return Row(
      children: [
        Expanded(
          child: _tarjetaResumen(
            'Total',
            comercios.length,
            Icons.store_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _tarjetaResumen(
            'Activos',
            activos,
            Icons.check_circle_outline,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _tarjetaResumen(
            'Inactivos',
            inactivos,
            Icons.pause_circle_outline,
          ),
        ),
      ],
    );
  }

  Widget _tarjetaResumen(String titulo, int cantidad, IconData icono) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        child: Column(
          children: [
            Icon(icono, size: 25),
            const SizedBox(height: 8),
            Text(
              '$cantidad',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(titulo, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _construirTarjeta(Map<String, dynamic> comercio) {
    final theme = Theme.of(context);
    final activo = comercio['activa'] == true;

    final propietario = comercio['propietario'] as Map<String, dynamic>?;

    final imagen = comercio['imagen']?.toString() ?? '';

    final comercioId = comercio['id']?.toString() ?? '';
    final actualizando = _actualizandoIds.contains(comercioId);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: imagen.isNotEmpty
                      ? Image.network(
                          imagen,
                          width: 76,
                          height: 76,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _imagenPredeterminada(),
                        )
                      : _imagenPredeterminada(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _texto(comercio['nombre']),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            activo ? Icons.check_circle : Icons.cancel,
                            size: 16,
                            color: activo ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            activo ? 'Activo' : 'Inactivo',
                            style: TextStyle(
                              color: activo ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            _dato(
              Icons.person_outline,
              'Propietario',
              _nombrePropietario(propietario),
            ),
            _dato(
              Icons.phone_outlined,
              'Teléfono del establecimiento',
              _texto(comercio['telefono']),
            ),
            _dato(
              Icons.location_on_outlined,
              'Dirección',
              _texto(comercio['direccion']),
            ),
            _dato(
              Icons.phone_android_outlined,
              'Teléfono del propietario',
              _texto(propietario?['telefono']),
            ),

            const Divider(height: 24),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Estado del establecimiento',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activo ? 'Actualmente activo' : 'Actualmente inactivo',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (actualizando)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Switch(
                    value: activo,
                    onChanged: (nuevoEstado) {
                      _cambiarEstado(comercio, nuevoEstado);
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagenPredeterminada() {
    return Container(
      width: 76,
      height: 76,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Icon(Icons.store, size: 35),
    );
  }

  Widget _dato(IconData icono, String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: Theme.of(context).textTheme.bodySmall),
                Text(valor, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirVacio(String mensaje) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 45),
      child: Column(
        children: [
          const Icon(Icons.store_outlined, size: 55),
          const SizedBox(height: 12),
          Text(mensaje, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _construirError(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            const Text(
              'No fue posible cargar los comercios.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(error.toString(), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _recargar,
              icon: const Icon(Icons.refresh),
              label: const Text('Intentar nuevamente'),
            ),
          ],
        ),
      ),
    );
  }
}
