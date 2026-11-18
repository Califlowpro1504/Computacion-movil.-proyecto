import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BarberiasAdminScreen extends StatefulWidget {
  const BarberiasAdminScreen({super.key});

  @override
  State<BarberiasAdminScreen> createState() => _BarberiasAdminScreenState();
}

class _BarberiasAdminScreenState extends State<BarberiasAdminScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _busquedaController = TextEditingController();

  late Future<List<Map<String, dynamic>>> _barberiasFuture;

  String _filtroEstado = 'Todos';
  String _busqueda = '';

  final Set<String> _actualizandoIds = {};

  @override
  void initState() {
    super.initState();
    _barberiasFuture = _cargarBarberias();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _cargarBarberias() async {
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

    final perfilesPorId = <String, Map<String, dynamic>>{};

    for (final perfil in perfiles) {
      perfilesPorId[perfil['id'].toString()] = Map<String, dynamic>.from(
        perfil,
      );
    }

    return barberias.map<Map<String, dynamic>>((barberia) {
      final resultado = Map<String, dynamic>.from(barberia);

      final propietarioId = resultado['propietario_id']?.toString() ?? '';

      resultado['propietario'] = perfilesPorId[propietarioId];

      return resultado;
    }).toList();
  }

  Future<void> _recargar() async {
    final nuevaCarga = _cargarBarberias();

    setState(() {
      _barberiasFuture = nuevaCarga;
    });

    await nuevaCarga;
  }

  Future<void> _cambiarEstado(
    Map<String, dynamic> barberia,
    bool nuevoEstado,
  ) async {
    final id = barberia['id']?.toString() ?? '';

    if (id.isEmpty || _actualizandoIds.contains(id)) {
      return;
    }

    final nombre = _texto(barberia['nombre']);

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(nuevoEstado ? 'Activar barbería' : 'Inactivar barbería'),
          content: Text(
            nuevoEstado
                ? '¿Deseas activar "$nombre"?'
                : '¿Deseas inactivar "$nombre"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(nuevoEstado ? 'Activar' : 'Inactivar'),
            ),
          ],
        );
      },
    );

    if (confirmado != true || !mounted) return;

    setState(() {
      _actualizandoIds.add(id);
    });

    try {
      final resultado = await _supabase
          .from('barberias')
          .update({'activa': nuevoEstado})
          .eq('id', id)
          .select('id')
          .maybeSingle();

      if (resultado == null) {
        throw Exception(
          'No se pudo actualizar la barbería. '
          'Verifica los permisos administrativos.',
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nuevoEstado
                ? 'Barbería activada correctamente.'
                : 'Barbería inactivada correctamente.',
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
          _actualizandoIds.remove(id);
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
    if (perfil == null) return 'Perfil no encontrado';

    final nombre = perfil['nombre']?.toString() ?? '';
    final apellido = perfil['apellido']?.toString() ?? '';

    final completo = '$nombre $apellido'.trim();

    return completo.isEmpty ? 'Nombre no registrado' : completo;
  }

  List<Map<String, dynamic>> _filtrarBarberias(
    List<Map<String, dynamic>> barberias,
  ) {
    final consulta = _busqueda.trim().toLowerCase();

    return barberias.where((barberia) {
      final propietario = barberia['propietario'] as Map<String, dynamic>?;

      final nombre = _texto(barberia['nombre']).toLowerCase();
      final direccion = _texto(barberia['direccion']).toLowerCase();
      final telefono = _texto(barberia['telefono']).toLowerCase();
      final nombrePropietario = _nombrePropietario(propietario).toLowerCase();

      final coincideBusqueda =
          consulta.isEmpty ||
          nombre.contains(consulta) ||
          direccion.contains(consulta) ||
          telefono.contains(consulta) ||
          nombrePropietario.contains(consulta);

      final activa = barberia['activa'] == true;

      final coincideEstado = switch (_filtroEstado) {
        'Activas' => activa,
        'Inactivas' => !activa,
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
        title: const Text('Gestión de barberías'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _recargar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _barberiasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _construirError(snapshot.error);
          }

          final barberias = snapshot.data ?? [];
          final filtradas = _filtrarBarberias(barberias);

          return RefreshIndicator(
            onRefresh: _recargar,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Barberías registradas',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Consulta los establecimientos y supervisa '
                  'la información de sus propietarios.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),

                _construirResumen(barberias),

                const SizedBox(height: 20),

                TextField(
                  controller: _busquedaController,
                  onChanged: (valor) {
                    setState(() {
                      _busqueda = valor;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Buscar barbería o propietario...',
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
                  children: ['Todos', 'Activas', 'Inactivas'].map((filtro) {
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

                if (barberias.isEmpty)
                  _construirVacio('Todavía no hay barberías registradas.')
                else if (filtradas.isEmpty)
                  _construirVacio(
                    'No se encontraron barberías con esos filtros.',
                  )
                else ...[
                  Text(
                    '${filtradas.length} barberías encontradas',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...filtradas.map(_construirTarjeta),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _construirResumen(List<Map<String, dynamic>> barberias) {
    final activas = barberias.where((b) => b['activa'] == true).length;

    final inactivas = barberias.length - activas;

    return Row(
      children: [
        Expanded(
          child: _tarjetaResumen('Total', barberias.length, Icons.content_cut),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _tarjetaResumen(
            'Activas',
            activas,
            Icons.check_circle_outline,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _tarjetaResumen(
            'Inactivas',
            inactivas,
            Icons.pause_circle_outline,
          ),
        ),
      ],
    );
  }

  Widget _tarjetaResumen(String titulo, int cantidad, IconData icono) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
        child: Column(
          children: [
            Icon(icono, size: 24),
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

  Widget _construirTarjeta(Map<String, dynamic> barberia) {
    final theme = Theme.of(context);
    final activa = barberia['activa'] == true;

    final propietario = barberia['propietario'] as Map<String, dynamic>?;

    final imagen = barberia['imagen']?.toString() ?? '';
    final id = barberia['id']?.toString() ?? '';
    final actualizando = _actualizandoIds.contains(id);

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
                          errorBuilder: (context, error, stackTrace) =>
                              _imagenPredeterminada(),
                        )
                      : _imagenPredeterminada(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _texto(barberia['nombre']),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            activa ? Icons.check_circle : Icons.cancel,
                            size: 16,
                            color: activa ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            activa ? 'Activa' : 'Inactiva',
                            style: TextStyle(
                              color: activa ? Colors.green : Colors.red,
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
              _texto(barberia['telefono']),
            ),
            _dato(
              Icons.location_on_outlined,
              'Dirección',
              _texto(barberia['direccion']),
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
                        activa ? 'Actualmente activa' : 'Actualmente inactiva',
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
                    value: activa,
                    onChanged: (nuevoEstado) {
                      _cambiarEstado(barberia, nuevoEstado);
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
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

  Widget _imagenPredeterminada() {
    return Container(
      width: 76,
      height: 76,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Icon(Icons.content_cut, size: 35),
    );
  }

  Widget _construirVacio(String mensaje) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 45),
      child: Column(
        children: [
          const Icon(Icons.content_cut, size: 55),
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
              'No fue posible cargar las barberías.',
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
