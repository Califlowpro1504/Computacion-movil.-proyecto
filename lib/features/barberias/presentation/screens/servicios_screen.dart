import 'package:flutter/material.dart';

import '../../domain/entities/servicio.dart';

class ServiciosScreen extends StatefulWidget {
  const ServiciosScreen({super.key});

  @override
  State<ServiciosScreen> createState() => _ServiciosScreenState();
}

class _ServiciosScreenState extends State<ServiciosScreen> {
  final List<Servicio> _servicios = [
    const Servicio(
      id: '1',
      barberiaId: '1',
      nombre: 'Corte clásico',
      descripcion: 'Corte tradicional con acabado a elección.',
      duracionMinutos: 30,
      precio: 25000,
      activo: true,
    ),
    const Servicio(
      id: '2',
      barberiaId: '1',
      nombre: 'Corte y barba',
      descripcion: 'Corte de cabello y arreglo de barba.',
      duracionMinutos: 45,
      precio: 40000,
      activo: true,
    ),
    const Servicio(
      id: '3',
      barberiaId: '2',
      nombre: 'Diseño de cejas',
      descripcion: 'Perfilado y limpieza de cejas.',
      duracionMinutos: 15,
      precio: 10000,
      activo: true,
    ),
  ];

  final Map<String, String> _barberias = const {
    '1': 'Juanjo Barber',
    '2': 'Barbería Central',
    '3': 'Estilo Urbano',
  };

  bool _soloActivos = false;

  List<Servicio> get _serviciosFiltrados => _servicios
      .where((s) => !_soloActivos || s.activo)
      .toList();

  Future<void> _abrirFormulario({Servicio? servicio}) async {
    final formKey = GlobalKey<FormState>();
    final nombreController =
        TextEditingController(text: servicio?.nombre ?? '');
    final descripcionController =
        TextEditingController(text: servicio?.descripcion ?? '');
    final duracionController = TextEditingController(
      text: servicio?.duracionMinutos.toString() ?? '30',
    );
    final precioController = TextEditingController(
      text: servicio?.precio.toStringAsFixed(0) ?? '',
    );

    String barberiaSeleccionada = servicio?.barberiaId ?? '1';
    bool activo = servicio?.activo ?? true;

    final resultado = await showDialog<Servicio>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            servicio == null ? 'Nuevo servicio' : 'Editar servicio',
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del servicio',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Escribe el nombre'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descripcionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Escribe una descripción'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: barberiaSeleccionada,
                      decoration: const InputDecoration(
                        labelText: 'Barbería',
                        border: OutlineInputBorder(),
                      ),
                      items: _barberias.entries
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setDialogState(
                            () => barberiaSeleccionada = v,
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: duracionController,
                      decoration: const InputDecoration(
                        labelText: 'Duración en minutos',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        return n == null || n <= 0
                            ? 'Ingresa una duración válida'
                            : null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: precioController,
                      decoration: const InputDecoration(
                        labelText: 'Precio en pesos colombianos (COP)',
                        prefixText: r'$ ',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        return n == null || n < 0
                            ? 'Ingresa un precio válido'
                            : null;
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Servicio activo'),
                      value: activo,
                      onChanged: (v) {
                        setDialogState(() => activo = v);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;

                final nuevoServicio = Servicio(
                  id: servicio?.id ??
                      DateTime.now().microsecondsSinceEpoch.toString(),
                  barberiaId: barberiaSeleccionada,
                  nombre: nombreController.text.trim(),
                  descripcion: descripcionController.text.trim(),
                  duracionMinutos:
                      int.parse(duracionController.text.trim()),
                  precio: double.parse(precioController.text.trim()),
                  activo: activo,
                );

                Navigator.pop(dialogContext, nuevoServicio);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    // Esperar a que termine la animación de cierre del diálogo.
    await Future<void>.delayed(const Duration(milliseconds: 400));

    nombreController.dispose();
    descripcionController.dispose();
    duracionController.dispose();
    precioController.dispose();

    if (!mounted || resultado == null) return;

    setState(() {
      final indice = _servicios.indexWhere((s) => s.id == resultado.id);

      if (indice == -1) {
        _servicios.add(resultado);
      } else {
        _servicios[indice] = resultado;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Servicio guardado correctamente')),
    );
  }

  Future<void> _eliminarServicio(Servicio servicio) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar servicio'),
        content: Text('¿Quieres eliminar "${servicio.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    setState(() {
      _servicios.removeWhere((s) => s.id == servicio.id);
    });
  }

  void _cambiarEstado(Servicio servicio, bool activo) {
    setState(() {
      final indice = _servicios.indexWhere((s) => s.id == servicio.id);
      if (indice == -1) return;

      final anterior = _servicios[indice];
      _servicios[indice] = Servicio(
        id: anterior.id,
        barberiaId: anterior.barberiaId,
        nombre: anterior.nombre,
        descripcion: anterior.descripcion,
        duracionMinutos: anterior.duracionMinutos,
        precio: anterior.precio,
        activo: activo,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final servicios = _serviciosFiltrados;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CUT & GO | Servicios'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo servicio'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Administración de servicios',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text('Gestiona los precios, tiempos y disponibilidad.'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Mostrar solo servicios activos'),
              value: _soloActivos,
              onChanged: (v) => setState(() => _soloActivos = v),
            ),
            Text('${servicios.length} servicio(s)'),
            const SizedBox(height: 8),
            Expanded(
              child: servicios.isEmpty
                  ? const Center(child: Text('No hay servicios para mostrar.'))
                  : ListView.separated(
                      itemCount: servicios.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final servicio = servicios[index];

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const CircleAvatar(
                                      child: Icon(Icons.content_cut),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        servicio.nombre,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 17,
                                        ),
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      onSelected: (opcion) {
                                        if (opcion == 'editar') {
                                          _abrirFormulario(
                                            servicio: servicio,
                                          );
                                        } else if (opcion == 'eliminar') {
                                          _eliminarServicio(servicio);
                                        }
                                      },
                                      itemBuilder: (_) => const [
                                        PopupMenuItem(
                                          value: 'editar',
                                          child: Text('Editar'),
                                        ),
                                        PopupMenuItem(
                                          value: 'eliminar',
                                          child: Text('Eliminar'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(servicio.descripcion),
                                const SizedBox(height: 8),
                                Text(
                                  'Barbería: ${_barberias[servicio.barberiaId] ?? "Sin asignar"}',
                                ),
                                Text('Duración: ${servicio.duracionMinutos} min'),
                                Text(
                                  'Precio: \$ ${servicio.precio.toStringAsFixed(0)} COP',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    servicio.activo ? 'Activo' : 'Inactivo',
                                  ),
                                  value: servicio.activo,
                                  onChanged: (v) =>
                                      _cambiarEstado(servicio, v),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

