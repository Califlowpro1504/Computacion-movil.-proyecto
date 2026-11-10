
import 'package:flutter/material.dart';

import '../../data/repositories/barberia_repository_impl.dart';
import '../../domain/entities/barberia.dart';

class BarberiasScreen extends StatefulWidget {
  const BarberiasScreen({super.key});

  @override
  State<BarberiasScreen> createState() => _BarberiasScreenState();
}

class _BarberiasScreenState extends State<BarberiasScreen> {
  final TextEditingController _busquedaController =
      TextEditingController();

  final BarberiaRepositoryImpl _repo = BarberiaRepositoryImpl();

  late Future<List<Barberia>> _futureBarberias;

  bool _soloActivas = false;

  @override
  void initState() {
    super.initState();
    _futureBarberias = _repo.obtenerBarberias();
  }

  void _recargarBarberias() {
    setState(() {
      _futureBarberias = _repo.obtenerBarberias();
    });
  }

  List<Barberia> _filtrarBarberias(List<Barberia> barberias) {
    final busqueda = _busquedaController.text.toLowerCase().trim();

    return barberias.where((barberia) {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('CUT & GO | Barberías'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Actualizar barberías',
            onPressed: _recargarBarberias,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<Barberia>>(
        future: _futureBarberias,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No pudimos cargar las barberías.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _recargarBarberias,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Intentar nuevamente'),
                    ),
                  ],
                ),
              ),
            );
          }

          final todasLasBarberias = snapshot.data ?? [];
          final barberias = _filtrarBarberias(todasLasBarberias);

          return Padding(
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
          );
        },
      ),
    );
  }
}
