import 'package:flutter/material.dart';

import '../../domain/entities/barberia.dart';

class BarberiasScreen extends StatefulWidget {
  const BarberiasScreen({super.key});

  @override
  State<BarberiasScreen> createState() => _BarberiasScreenState();
}

class _BarberiasScreenState extends State<BarberiasScreen> {
  final TextEditingController _busquedaController =
      TextEditingController();

  bool _soloActivas = false;

  final List<Barberia> _barberias = const [
    Barberia(
      id: '1',
      nombre: 'Juanjo Barber',
      direccion: 'Palmira, Valle del Cauca',
      telefono: '3000000001',
      imagen:
          'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?auto=format&fit=crop&w=500&q=80',
      activa: true,
    ),
    Barberia(
      id: '2',
      nombre: 'Barbería Central',
      direccion: 'Centro de Palmira',
      telefono: '3000000002',
      imagen:
          'https://images.unsplash.com/photo-1621605815971-fbc98d665033?auto=format&fit=crop&w=500&q=80',
      activa: true,
    ),
    Barberia(
      id: '3',
      nombre: 'Estilo Urbano',
      direccion: 'Palmira, Valle del Cauca',
      telefono: '3000000003',
      imagen:
          'https://images.unsplash.com/photo-1622286342621-4bd786c2447c?auto=format&fit=crop&w=500&q=80',
      activa: false,
    ),
  ];

  List<Barberia> get _barberiasFiltradas {
    final busqueda = _busquedaController.text.toLowerCase().trim();

    return _barberias.where((barberia) {
      final coincideBusqueda =
          barberia.nombre.toLowerCase().contains(busqueda) ||
          barberia.direccion.toLowerCase().contains(busqueda);

      final coincideEstado = !_soloActivas || barberia.activa;

      return coincideBusqueda && coincideEstado;
    }).toList();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final barberias = _barberiasFiltradas;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CUT & GO | Barberías'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Encuentra tu barbería',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Explora los establecimientos y encuentra tu estilo.',
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _busquedaController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o dirección',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Mostrar solo barberías activas'),
              value: _soloActivas,
              onChanged: (valor) {
                setState(() {
                  _soloActivas = valor;
                });
              },
            ),
            const SizedBox(height: 8),
            Text(
              '${barberias.length} barbería(s) encontrada(s)',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: barberias.isEmpty
                  ? const Center(
                      child: Text('No se encontraron barberías.'),
                    )
                  : ListView.separated(
                      itemCount: barberias.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final barberia = barberias[index];

                        return Card(
                          clipBehavior: Clip.antiAlias,
                          elevation: 3,
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(10),
                            minVerticalPadding: 8,
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: SizedBox(
                                width: 90,
                                height: 100,
                                child: barberia.imagen.isNotEmpty
                                    ? Image.network(
                                        barberia.imagen,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return const ColoredBox(
                                            color: Color(0xFFE8E8E8),
                                            child: Icon(
                                              Icons.content_cut,
                                              size: 35,
                                            ),
                                          );
                                        },
                                      )
                                    : const ColoredBox(
                                        color: Color(0xFFE8E8E8),
                                        child: Icon(
                                          Icons.content_cut,
                                          size: 35,
                                        ),
                                      ),
                              ),
                            ),
                            title: Text(
                              barberia.nombre,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(barberia.direccion),
                                  const SizedBox(height: 5),
                                  Text('Teléfono: ${barberia.telefono}'),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.circle,
                                        size: 10,
                                        color: barberia.activa
                                            ? Colors.green
                                            : Colors.grey,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        barberia.activa
                                            ? 'Activa'
                                            : 'Inactiva',
                                        style: TextStyle(
                                          color: barberia.activa
                                              ? Colors.green
                                              : Colors.grey,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            isThreeLine: true,
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
