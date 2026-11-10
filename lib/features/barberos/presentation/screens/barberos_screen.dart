import 'package:flutter/material.dart';

import '../../data/barbero_repository.dart';
import '../../domain/entities/barbero.dart';
import '../../../horarios/presentation/screens/horarios_screen.dart';

class BarberosScreen extends StatefulWidget {
  final String barberiaId;

  const BarberosScreen({super.key, required this.barberiaId});

  @override
  State<BarberosScreen> createState() => _BarberosScreenState();
}

class _BarberosScreenState extends State<BarberosScreen> {
  final _repo = BarberoRepository();
  late Future<List<Barbero>> _futuro;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    _futuro = _repo.obtenerPorBarberia(widget.barberiaId);
  }

  Future<void> _administrarHorarios(Barbero barbero) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HorariosScreen(
          barberoId: barbero.id,
          barberoNombre: '${barbero.nombre} ${barbero.apellido}',
        ),
      ),
    );
  }

  Future<void> _formulario([Barbero? existente]) async {
    final nombre = TextEditingController(text: existente?.nombre);
    final apellido = TextEditingController(text: existente?.apellido);
    final descripcion = TextEditingController(text: existente?.descripcion);

    try {
      final guardar = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(existente == null ? 'Agregar barbero' : 'Editar barbero'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombre,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                TextField(
                  controller: apellido,
                  decoration: const InputDecoration(labelText: 'Apellido'),
                ),
                TextField(
                  controller: descripcion,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Guardar'),
            ),
          ],
        ),
      );

      if (guardar != true) return;

      if (nombre.text.trim().isEmpty || apellido.text.trim().isEmpty) {
        return;
      }

      if (existente == null) {
        await _repo.crear(
          Barbero(
            id: '',
            barberiaId: widget.barberiaId,
            nombre: nombre.text.trim(),
            apellido: apellido.text.trim(),
            descripcion: descripcion.text.trim(),
          ),
        );
      } else {
        await _repo.actualizar(
          existente.copyWith(
            nombre: nombre.text.trim(),
            apellido: apellido.text.trim(),
            descripcion: descripcion.text.trim(),
          ),
        );
      }

      if (!mounted) return;
      setState(_cargar);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar el barbero: $e')),
      );
    } finally {
      nombre.dispose();
      apellido.dispose();
      descripcion.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Barberos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _formulario(),
        icon: const Icon(Icons.add),
        label: const Text('Agregar barbero'),
      ),
      body: FutureBuilder<List<Barbero>>(
        future: _futuro,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }

          final barberos = snap.data ?? [];

          if (barberos.isEmpty) {
            return const Center(child: Text('No hay barberos registrados'));
          }

          return ListView.builder(
            itemCount: barberos.length,
            itemBuilder: (_, i) {
              final b = barberos[i];

              return ListTile(
                title: Text('${b.nombre} ${b.apellido}'),
                subtitle: Text(b.activo ? 'Activo' : 'Inactivo'),
                trailing: Wrap(
                  spacing: 0,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Administrar horarios',
                      icon: const Icon(Icons.calendar_month),
                      onPressed: () => _administrarHorarios(b),
                    ),
                    IconButton(
                      tooltip: 'Editar barbero',
                      icon: const Icon(Icons.edit),
                      onPressed: () => _formulario(b),
                    ),
                    Switch(
                      value: b.activo,
                      onChanged: (v) async {
                        final messenger = ScaffoldMessenger.of(context);

                        try {
                          await _repo.cambiarEstado(b.id, v);

                          if (!mounted) return;
                          setState(_cargar);
                        } catch (e) {
                          if (!mounted) return;

                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('No se pudo cambiar el estado: $e'),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
