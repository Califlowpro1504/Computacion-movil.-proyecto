import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/barberia.dart';
import 'crear_barberia_screen.dart';
import 'editar_barberia_screen.dart';

class PanelPropietarioScreen extends StatefulWidget {
  const PanelPropietarioScreen({super.key});

  @override
  State<PanelPropietarioScreen> createState() => _PanelPropietarioScreenState();
}

class _PanelPropietarioScreenState extends State<PanelPropietarioScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  late Future<List<Map<String, dynamic>>> _barberiasFuture;

  @override
  void initState() {
    super.initState();
    _barberiasFuture = _obtenerMisBarberias();
  }

  Future<List<Map<String, dynamic>>> _obtenerMisBarberias() async {
    final usuario = _supabase.auth.currentUser;

    if (usuario == null) {
      throw Exception('No hay una sesión iniciada.');
    }

    final respuesta = await _supabase
        .from('barberias')
        .select('id, nombre, direccion, telefono, imagen, activa')
        .eq('propietario_id', usuario.id);

    return List<Map<String, dynamic>>.from(respuesta);
  }

  void _recargarBarberias() {
    setState(() {
      _barberiasFuture = _obtenerMisBarberias();
    });
  }

  Future<void> _abrirFormulario() async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const CrearBarberiaScreen()),
    );

    if (!mounted) return;

    if (resultado == true) {
      _recargarBarberias();
    }
  }

  Future<void> _editarBarberia(Map<String, dynamic> datos) async {
    final barberia = Barberia(
      id: datos['id'].toString(),
      nombre: datos['nombre'] ?? '',
      direccion: datos['direccion'] ?? '',
      telefono: datos['telefono'] ?? '',
      imagen: datos['imagen'] ?? '',
      activa: datos['activa'] ?? true,
    );

    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditarBarberiaScreen(barberia: barberia),
      ),
    );

    if (!mounted) return;

    if (resultado == true) {
      _recargarBarberias();
    }
  }

  Widget _botonRegistrar() {
    return ElevatedButton.icon(
      onPressed: _abrirFormulario,
      icon: const Icon(Icons.add_business),
      label: const Text('Registrar mi barbería'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de propietario'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _recargarBarberias,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Registrar barbería',
            onPressed: _abrirFormulario,
            icon: const Icon(Icons.add_business),
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 55),
                    const SizedBox(height: 12),
                    const Text(
                      'No se pudieron cargar tus barberías.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('${snapshot.error}', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _recargarBarberias,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Intentar nuevamente'),
                    ),
                  ],
                ),
              ),
            );
          }

          final barberias = snapshot.data ?? [];

          if (barberias.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.store_outlined, size: 70),
                    const SizedBox(height: 16),
                    const Text(
                      'Todavía no tienes una barbería registrada.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Aquí podrás administrar tu barbería y sus citas.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    _botonRegistrar(),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Mis barberías',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...barberias.map((barberia) {
                final activa = barberia['activa'] == true;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.content_cut)),
                    title: Text(
                      barberia['nombre'] ?? 'Sin nombre',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${barberia['direccion'] ?? 'Sin dirección'}\n'
                      'Teléfono: ${barberia['telefono'] ?? 'No registrado'}',
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          activa ? Icons.check_circle : Icons.pause_circle,
                          color: activa ? Colors.green : Colors.orange,
                        ),
                        IconButton(
                          tooltip: 'Editar barbería',
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editarBarberia(barberia),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),
              _botonRegistrar(),
            ],
          );
        },
      ),
    );
  }
}
