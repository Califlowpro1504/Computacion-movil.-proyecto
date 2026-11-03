import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/cita_repository.dart';
import '../../domain/entities/cita.dart';

class MisCitasScreen extends StatefulWidget {
  const MisCitasScreen({super.key});

  @override
  State<MisCitasScreen> createState() => _MisCitasScreenState();
}

class _MisCitasScreenState extends State<MisCitasScreen> {
  final CitaRepository _citaRepository = CitaRepository();
  final SupabaseClient _client = Supabase.instance.client;

  bool _cargando = true;
  String? _error;

  List<Cita> _citas = [];

  final Map<String, String> _barberias = {};
  final Map<String, String> _barberos = {};
  final Map<String, String> _servicios = {};

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
      final citas = await _citaRepository.obtenerMisCitas();

      final barberiaIds = citas.map((c) => c.barberiaId).toSet().toList();
      final barberoIds = citas.map((c) => c.barberoId).toSet().toList();
      final servicioIds = citas.map((c) => c.servicioId).toSet().toList();

      _barberias.clear();
      _barberos.clear();
      _servicios.clear();

      if (barberiaIds.isNotEmpty) {
        final datos = await _client
            .from('barberias')
            .select('id, nombre')
            .inFilter('id', barberiaIds);

        for (final item in datos) {
          _barberias[item['id'].toString()] = (item['nombre'] ?? 'Barbería')
              .toString();
        }
      }

      if (barberoIds.isNotEmpty) {
        final datos = await _client
            .from('barberos')
            .select('id, nombre, apellido')
            .inFilter('id', barberoIds);

        for (final item in datos) {
          final nombre = '${item['nombre'] ?? ''} ${item['apellido'] ?? ''}'
              .trim();

          _barberos[item['id'].toString()] = nombre.isEmpty
              ? 'Barbero'
              : nombre;
        }
      }

      if (servicioIds.isNotEmpty) {
        final datos = await _client
            .from('servicios')
            .select('id, nombre')
            .inFilter('id', servicioIds);

        for (final item in datos) {
          _servicios[item['id'].toString()] = (item['nombre'] ?? 'Servicio')
              .toString();
        }
      }

      if (!mounted) return;

      setState(() {
        _citas = citas;
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

  bool _esProxima(Cita cita) {
    return cita.estado == 'pendiente' || cita.estado == 'confirmada';
  }

  String _nombreEstado(String estado) {
    switch (estado) {
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
    switch (estado) {
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

  String _formatearFecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year.toString();

    return '$dia/$mes/$anio';
  }

  String _formatearHora(DateTime fecha) {
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minutos = fecha.minute.toString().padLeft(2, '0');

    return '$hora:$minutos';
  }

  Widget _construirTarjeta(Cita cita) {
    final color = _colorEstado(cita.estado);

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
                const Icon(Icons.store, color: Colors.blueGrey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _barberias[cita.barberiaId] ?? 'Barbería',
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
                    _nombreEstado(cita.estado),
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
            _dato(
              Icons.person,
              'Barbero',
              _barberos[cita.barberoId] ?? 'No disponible',
            ),
            const SizedBox(height: 10),
            _dato(
              Icons.content_cut,
              'Servicio',
              _servicios[cita.servicioId] ?? 'No disponible',
            ),
            const SizedBox(height: 10),
            _dato(
              Icons.calendar_today,
              'Fecha',
              _formatearFecha(cita.fechaInicio),
            ),
            const SizedBox(height: 10),
            _dato(
              Icons.access_time,
              'Hora',
              '${_formatearHora(cita.fechaInicio)} - '
                  '${_formatearHora(cita.fechaFin)}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _dato(IconData icono, String titulo, String valor) {
    return Row(
      children: [
        Icon(icono, size: 19, color: Colors.grey.shade600),
        const SizedBox(width: 10),
        Text('$titulo: ', style: const TextStyle(fontWeight: FontWeight.w600)),
        Expanded(child: Text(valor)),
      ],
    );
  }

  Widget _construirSeccion(String titulo, List<Cita> citas) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 12),
          child: Text(
            titulo,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        if (citas.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No tienes citas en esta sección.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          )
        else
          ...citas.map(_construirTarjeta),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final proximas = _citas.where(_esProxima).toList();
    final historial = _citas.where((c) => !_esProxima(c)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis citas'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _cargarCitas,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 12),
                    const Text('No se pudieron cargar tus citas.'),
                    const SizedBox(height: 8),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _cargarCitas,
                      child: const Text('Intentar nuevamente'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _cargarCitas,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _construirSeccion('Próximas citas', proximas),
                  _construirSeccion('Historial', historial),
                ],
              ),
            ),
    );
  }
}
