import 'package:flutter/material.dart';

import '../../data/repositories/cita_repository.dart';

class AdministracionCitasScreen extends StatefulWidget {
  const AdministracionCitasScreen({super.key});

  @override
  State<AdministracionCitasScreen> createState() =>
      _AdministracionCitasScreenState();
}

class _AdministracionCitasScreenState extends State<AdministracionCitasScreen> {
  final CitaRepository _citaRepository = CitaRepository();

  bool _cargando = true;
  String? _error;
  String _filtroEstado = 'todas';

  List<Map<String, dynamic>> _citas = [];

  @override
  void initState() {
    super.initState();
    _cargarCitas();
  }

  Future<void> _cargarCitas() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final resultado = await _citaRepository.obtenerTodasLasCitasAdmin();

      if (!mounted) return;

      setState(() {
        _citas = resultado;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }

  Map<String, dynamic>? _convertirMapa(dynamic valor) {
    if (valor is Map) {
      return Map<String, dynamic>.from(valor);
    }

    if (valor is List && valor.isNotEmpty && valor.first is Map) {
      return Map<String, dynamic>.from(valor.first as Map);
    }

    return null;
  }

  String _obtenerNombre(dynamic valor, String alternativo) {
    final mapa = _convertirMapa(valor);

    if (mapa == null) return alternativo;

    final nombre = mapa['nombre']?.toString() ?? '';
    final apellido = mapa['apellido']?.toString() ?? '';
    final completo = '$nombre $apellido'.trim();

    return completo.isEmpty ? alternativo : completo;
  }

  String _formatearFecha(dynamic valor) {
    if (valor == null) return 'No disponible';

    final fecha = DateTime.parse(valor.toString()).toLocal();

    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');

    return '$dia/$mes/${fecha.year}';
  }

  String _formatearHora(dynamic valor) {
    if (valor == null) return '--:--';

    final fecha = DateTime.parse(valor.toString()).toLocal();

    final hora = fecha.hour.toString().padLeft(2, '0');
    final minutos = fecha.minute.toString().padLeft(2, '0');

    return '$hora:$minutos';
  }

  String _nombreEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return 'Pendiente';
      case 'confirmada':
        return 'Confirmada';
      case 'cancelada':
        return 'Cancelada';
      case 'completada':
        return 'Completada';
      default:
        return estado;
    }
  }

  Color _colorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Colors.orange;
      case 'confirmada':
        return Colors.green;
      case 'cancelada':
        return Colors.red;
      case 'completada':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  List<Map<String, dynamic>> get _citasFiltradas {
    if (_filtroEstado == 'todas') return _citas;

    return _citas.where((cita) {
      return cita['estado']?.toString().toLowerCase() == _filtroEstado;
    }).toList();
  }

  Widget _tarjetaResumen(String titulo, int cantidad, Color color) {
    return SizedBox(
      width: 145,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: TextStyle(color: Colors.grey.shade700)),
              const SizedBox(height: 8),
              Text(
                cantidad.toString(),
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirResumen() {
    final pendientes = _citas.where((c) => c['estado'] == 'pendiente').length;
    final confirmadas = _citas.where((c) => c['estado'] == 'confirmada').length;
    final completadas = _citas.where((c) => c['estado'] == 'completada').length;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _tarjetaResumen('Total', _citas.length, Colors.blue),
        _tarjetaResumen('Pendientes', pendientes, Colors.orange),
        _tarjetaResumen('Confirmadas', confirmadas, Colors.green),
        _tarjetaResumen('Completadas', completadas, Colors.indigo),
      ],
    );
  }

  Widget _construirFiltros() {
    const filtros = [
      ('todas', 'Todas'),
      ('pendiente', 'Pendientes'),
      ('confirmada', 'Confirmadas'),
      ('cancelada', 'Canceladas'),
      ('completada', 'Completadas'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filtros.map((filtro) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filtro.$2),
              selected: _filtroEstado == filtro.$1,
              onSelected: (_) {
                setState(() {
                  _filtroEstado = filtro.$1;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _dato(IconData icono, String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 19, color: Colors.grey.shade600),
          const SizedBox(width: 9),
          Text(
            '$titulo: ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Expanded(child: Text(valor)),
        ],
      ),
    );
  }

  Widget _construirTarjetaCita(Map<String, dynamic> cita) {
    final estado = cita['estado']?.toString() ?? 'desconocido';
    final color = _colorEstado(estado);

    final cliente = _obtenerNombre(cita['cliente'], 'Cliente no disponible');

    final barberia = _obtenerNombre(
      cita['barberias'],
      'Barbería no disponible',
    );

    final barbero = _obtenerNombre(cita['barberos'], 'Barbero no disponible');

    final servicio = _obtenerNombre(
      cita['servicios'],
      'Servicio no disponible',
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Colors.blueGrey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cliente,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _nombreEstado(estado),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _dato(Icons.store, 'Barbería', barberia),
            _dato(Icons.content_cut, 'Barbero', barbero),
            _dato(Icons.design_services, 'Servicio', servicio),
            _dato(
              Icons.calendar_today,
              'Fecha',
              _formatearFecha(cita['fecha_inicio']),
            ),
            _dato(
              Icons.access_time,
              'Horario',
              '${_formatearHora(cita['fecha_inicio'])} - '
                  '${_formatearHora(cita['fecha_fin'])}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirContenido() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 42),
              const SizedBox(height: 12),
              const Text(
                'No se pudieron cargar las citas.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _cargarCitas,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarCitas,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _construirResumen(),
          const SizedBox(height: 22),
          const Text(
            'Filtrar citas por estado',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _construirFiltros(),
          const SizedBox(height: 18),
          Text(
            'Citas registradas (${_citasFiltradas.length})',
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (_citasFiltradas.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 35),
              child: Center(child: Text('No hay citas para este filtro.')),
            )
          else
            ..._citasFiltradas.map(_construirTarjetaCita),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administración de citas'),
        actions: [
          IconButton(
            onPressed: _cargando ? null : _cargarCitas,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar citas',
          ),
        ],
      ),
      body: _construirContenido(),
    );
  }
}
