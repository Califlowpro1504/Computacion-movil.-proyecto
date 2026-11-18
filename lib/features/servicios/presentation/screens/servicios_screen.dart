import 'package:flutter/material.dart';
import '../../data/servicio_repository.dart';
import '../../domain/entities/servicio.dart';

class ServiciosScreen extends StatefulWidget {
  final String barberiaId;
  const ServiciosScreen({super.key, required this.barberiaId});

  @override
  State<ServiciosScreen> createState() => _ServiciosScreenState();
}

class _ServiciosScreenState extends State<ServiciosScreen> {
  final _repo = ServicioRepository();
  late Future<List<Servicio>> _futuro;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    _futuro = _repo.obtenerPorBarberia(widget.barberiaId);
  }

  void _aviso(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  Future<void> _formulario([Servicio? existente]) async {
    final nombre = TextEditingController(text: existente?.nombre);
    final descripcion = TextEditingController(text: existente?.descripcion);
    final precio = TextEditingController(
      text: existente == null ? '' : existente.precio.toStringAsFixed(0),
    );
    final duracion = TextEditingController(
      text: existente == null ? '' : existente.duracionMin.toString(),
    );

    final guardar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(existente == null ? 'Agregar servicio' : 'Editar servicio'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: nombre,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            TextField(
              controller: descripcion,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
            TextField(
              controller: precio,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Precio (COP)'),
            ),
            TextField(
              controller: duracion,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Duración (minutos)'),
            ),
          ]),
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

    final precioNum = double.tryParse(precio.text.trim().replaceAll(',', '.'));
    final duracionNum = int.tryParse(duracion.text.trim());

    if (nombre.text.trim().isEmpty) {
      _aviso('El nombre es obligatorio');
      return;
    }
    if (precioNum == null || precioNum <= 0) {
      _aviso('El precio debe ser un número mayor a 0');
      return;
    }
    if (duracionNum == null || duracionNum <= 0) {
      _aviso('La duración debe ser un número de minutos mayor a 0');
      return;
    }

    try {
      if (existente == null) {
        await _repo.crear(Servicio(
          id: '',
          barberiaId: widget.barberiaId,
          nombre: nombre.text.trim(),
          descripcion: descripcion.text.trim(),
          precio: precioNum,
          duracionMin: duracionNum,
        ));
      } else {
        await _repo.actualizar(existente.copyWith(
          nombre: nombre.text.trim(),
          descripcion: descripcion.text.trim(),
          precio: precioNum,
          duracionMin: duracionNum,
        ));
      }
      setState(_cargar);
    } catch (e) {
      _aviso('No se pudo guardar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Servicios')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _formulario(),
        icon: const Icon(Icons.add),
        label: const Text('Agregar servicio'),
      ),
      body: FutureBuilder<List<Servicio>>(
        future: _futuro,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final servicios = snap.data ?? [];
          if (servicios.isEmpty) {
            return const Center(child: Text('No hay servicios registrados'));
          }
          return ListView.builder(
            itemCount: servicios.length,
            itemBuilder: (_, i) {
              final s = servicios[i];
              return ListTile(
                title: Text(s.nombre),
                subtitle: Text(
                  '${s.precio.toStringAsFixed(0)} COP - ${s.duracionMin} min - ${s.activo ? "Activo" : "Inactivo"}',
                ),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _formulario(s),
                  ),
                  Switch(
                    value: s.activo,
                    onChanged: (v) async {
                      try {
                        await _repo.cambiarEstado(s.id, v);
                        setState(_cargar);
                      } catch (e) {
                        _aviso('No se pudo cambiar el estado: $e');
                      }
                    },
                  ),
                ]),
              );
            },
          );
        },
      ),
    );
  }
}
