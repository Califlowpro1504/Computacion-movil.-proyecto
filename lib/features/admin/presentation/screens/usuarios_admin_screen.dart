import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UsuariosAdminScreen extends StatefulWidget {
  const UsuariosAdminScreen({super.key});

  @override
  State<UsuariosAdminScreen> createState() => _UsuariosAdminScreenState();
}

class _UsuariosAdminScreenState extends State<UsuariosAdminScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _busquedaController = TextEditingController();

  late Future<List<Map<String, dynamic>>> _usuariosFuture;

  String _filtroRol = 'todos';
  final Set<String> _actualizandoIds = {};

  @override
  void initState() {
    super.initState();
    _usuariosFuture = _cargarUsuarios();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _cargarUsuarios() async {
    final respuesta = await _supabase
        .from('profiles')
        .select(
          'id, nombre, apellido, telefono, rol, activo, '
          'fecha_registro, es_admin',
        )
        .order('fecha_registro', ascending: false);

    return (respuesta as List)
        .map((usuario) => Map<String, dynamic>.from(usuario))
        .toList();
  }

  String _nombreCompleto(Map<String, dynamic> usuario) {
    final nombre = usuario['nombre']?.toString() ?? '';
    final apellido = usuario['apellido']?.toString() ?? '';

    return '$nombre $apellido'.trim();
  }

  bool _esAdministrador(Map<String, dynamic> usuario) {
    return usuario['es_admin'] == true ||
        usuario['rol']?.toString().toLowerCase() == 'admin';
  }

  List<Map<String, dynamic>> _filtrarUsuarios(
    List<Map<String, dynamic>> usuarios,
  ) {
    final busqueda = _busquedaController.text.trim().toLowerCase();

    return usuarios.where((usuario) {
      final nombre = _nombreCompleto(usuario).toLowerCase();
      final telefono = usuario['telefono']?.toString().toLowerCase() ?? '';
      final rol = usuario['rol']?.toString().toLowerCase() ?? '';

      final coincideBusqueda =
          busqueda.isEmpty ||
          nombre.contains(busqueda) ||
          telefono.contains(busqueda) ||
          rol.contains(busqueda);

      final coincideRol = switch (_filtroRol) {
        'cliente' => rol == 'cliente',
        'propietario' => rol == 'propietario',
        'admin' => _esAdministrador(usuario),
        _ => true,
      };

      return coincideBusqueda && coincideRol;
    }).toList();
  }

  Future<void> _cambiarEstado(
    Map<String, dynamic> usuario,
    bool nuevoEstado,
  ) async {
    final id = usuario['id'].toString();

    if (_esAdministrador(usuario)) {
      return;
    }

    setState(() {
      _actualizandoIds.add(id);
    });

    try {
      await _supabase
          .from('profiles')
          .update({'activo': nuevoEstado})
          .eq('id', id);

      if (!mounted) return;

      setState(() {
        _usuariosFuture = _cargarUsuarios();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nuevoEstado
                ? 'La cuenta fue activada correctamente.'
                : 'La cuenta fue desactivada correctamente.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar la cuenta: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _actualizandoIds.remove(id);
        });
      }
    }
  }

  String _formatearFecha(dynamic fecha) {
    if (fecha == null) return 'Sin fecha de registro';

    final fechaParseada = DateTime.tryParse(fecha.toString());

    if (fechaParseada == null) {
      return 'Fecha no disponible';
    }

    final fechaLocal = fechaParseada.toLocal();

    return '${fechaLocal.day.toString().padLeft(2, '0')}/'
        '${fechaLocal.month.toString().padLeft(2, '0')}/'
        '${fechaLocal.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de usuarios'),
        actions: [
          IconButton(
            tooltip: 'Actualizar usuarios',
            onPressed: () {
              setState(() {
                _usuariosFuture = _cargarUsuarios();
              });
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Usuarios registrados',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text('Consulta las cuentas y administra su estado.'),
              const SizedBox(height: 18),

              TextField(
                controller: _busquedaController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre, teléfono o rol...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    onPressed: () {
                      _busquedaController.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.clear),
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 14),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filtroChip('Todos', 'todos'),
                    _filtroChip('Clientes', 'cliente'),
                    _filtroChip('Propietarios', 'propietario'),
                    _filtroChip('Administradores', 'admin'),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _usuariosFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, size: 42),
                            const SizedBox(height: 10),
                            const Text('No fue posible cargar los usuarios.'),
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _usuariosFuture = _cargarUsuarios();
                                });
                              },
                              child: const Text('Intentar nuevamente'),
                            ),
                          ],
                        ),
                      );
                    }

                    final usuarios = _filtrarUsuarios(snapshot.data ?? []);

                    if (usuarios.isEmpty) {
                      return const Center(
                        child: Text('No se encontraron usuarios.'),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        final nuevaConsulta = _cargarUsuarios();

                        setState(() {
                          _usuariosFuture = nuevaConsulta;
                        });

                        await nuevaConsulta;
                      },
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: usuarios.length,
                        itemBuilder: (context, index) {
                          final usuario = usuarios[index];
                          final id = usuario['id'].toString();
                          final esAdmin = _esAdministrador(usuario);
                          final activo = usuario['activo'] == true;
                          final actualizando = _actualizandoIds.contains(id);

                          final rol = usuario['rol']?.toString() ?? 'Sin rol';

                          final nombre = _nombreCompleto(usuario);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 12,
                              ),
                              child: Column(
                                children: [
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      child: Icon(
                                        esAdmin
                                            ? Icons.admin_panel_settings
                                            : Icons.person_outline,
                                      ),
                                    ),
                                    title: Text(
                                      nombre.isEmpty
                                          ? 'Usuario sin nombre'
                                          : nombre,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          usuario['telefono']?.toString() ??
                                              'Sin teléfono',
                                        ),
                                        Text('Rol: $rol'),
                                        Text(
                                          'Registro: ${_formatearFecha(usuario['fecha_registro'])}',
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Divider(),
                                  Row(
                                    children: [
                                      Icon(
                                        activo
                                            ? Icons.check_circle
                                            : Icons.cancel,
                                        size: 18,
                                        color: activo
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          activo
                                              ? 'Cuenta activa'
                                              : 'Cuenta inactiva',
                                        ),
                                      ),
                                      if (esAdmin)
                                        const Text(
                                          'Protegida',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        )
                                      else if (actualizando)
                                        const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      else
                                        Switch(
                                          value: activo,
                                          onChanged: (nuevoEstado) {
                                            _cambiarEstado(
                                              usuario,
                                              nuevoEstado,
                                            );
                                          },
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filtroChip(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(titulo),
        selected: _filtroRol == valor,
        onSelected: (_) {
          setState(() {
            _filtroRol = valor;
          });
        },
      ),
    );
  }
}
