import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../barberias/data/repositories/barberia_repository_impl.dart';
import '../../../barberias/domain/entities/barberia.dart';
import '../../../barberos/data/barbero_repository.dart';
import '../../../barberos/domain/entities/barbero.dart';
import '../../../servicios/data/servicio_repository.dart';
import '../../../servicios/domain/entities/servicio.dart';
import '../../data/repositories/cita_repository.dart';

class ReservarCitaScreen extends StatefulWidget {
  const ReservarCitaScreen({super.key});

  @override
  State<ReservarCitaScreen> createState() => _ReservarCitaScreenState();
}

class _ReservarCitaScreenState extends State<ReservarCitaScreen> {
  final _barberiaRepository = BarberiaRepositoryImpl();
  final _barberoRepository = BarberoRepository();
  final _servicioRepository = ServicioRepository();
  final _citaRepository = CitaRepository();

  List<Barberia> _barberias = [];
  List<Barbero> _barberos = [];
  List<Servicio> _servicios = [];

  Barberia? _barberiaSeleccionada;
  Barbero? _barberoSeleccionado;
  Servicio? _servicioSeleccionado;
  DateTime? _fechaSeleccionada;
  TimeOfDay? _horaSeleccionada;

  bool _cargando = true;
  bool _reservando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarBarberias();
  }

  Future<void> _cargarBarberias() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final barberias = await _barberiaRepository.obtenerBarberias();

      if (!mounted) return;

      setState(() {
        _barberias = barberias.where((b) => b.activa).toList();
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'No fue posible cargar las barberías: $e';
        _cargando = false;
      });
    }
  }

  Future<void> _cargarBarberos(String barberiaId) async {
    setState(() {
      _barberoSeleccionado = null;
      _servicioSeleccionado = null;
      _barberos = [];
      _servicios = [];
      _cargando = true;
      _error = null;
    });

    try {
      final barberos = await _barberoRepository.obtenerPorBarberia(barberiaId);
      final servicios = await _servicioRepository.obtenerPorBarberia(
        barberiaId,
      );

      if (!mounted) return;

      setState(() {
        _barberos = barberos.where((b) => b.activo).toList();
        _servicios = servicios.where((s) => s.activo).toList();
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'No fue posible cargar barberos y servicios: $e';
        _cargando = false;
      });
    }
  }

  Future<void> _elegirFecha() async {
    final ahora = DateTime.now();

    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada ?? ahora,
      firstDate: ahora,
      lastDate: ahora.add(const Duration(days: 90)),
      helpText: 'Selecciona el día de tu cita',
    );

    if (fecha != null && mounted) {
      setState(() {
        _fechaSeleccionada = fecha;
        _horaSeleccionada = null;
      });
    }
  }

  Future<void> _elegirHora() async {
    if (_fechaSeleccionada == null) {
      _mostrarMensaje('Primero selecciona una fecha.');
      return;
    }

    final hora = await showTimePicker(
      context: context,
      initialTime: _horaSeleccionada ?? TimeOfDay.now(),
      helpText: 'Selecciona la hora de tu cita',
    );

    if (hora != null && mounted) {
      setState(() {
        _horaSeleccionada = hora;
      });
    }
  }

  DateTime? _construirFechaInicio() {
    final fecha = _fechaSeleccionada;
    final hora = _horaSeleccionada;

    if (fecha == null || hora == null) return null;

    return DateTime(fecha.year, fecha.month, fecha.day, hora.hour, hora.minute);
  }

  Future<void> _reservar() async {
    if (Supabase.instance.client.auth.currentUser == null) {
      _mostrarMensaje('Debes iniciar sesión para reservar una cita.');
      return;
    }

    final barberia = _barberiaSeleccionada;
    final barbero = _barberoSeleccionado;
    final servicio = _servicioSeleccionado;
    final inicio = _construirFechaInicio();

    if (barberia == null ||
        barbero == null ||
        servicio == null ||
        inicio == null) {
      _mostrarMensaje(
        'Selecciona una barbería, un barbero, un servicio, fecha y hora.',
      );
      return;
    }

    setState(() {
      _reservando = true;
      _error = null;
    });

    try {
      final cita = await _citaRepository.crear(
        barberiaId: barberia.id,
        barberoId: barbero.id,
        servicioId: servicio.id,
        fechaInicio: inicio,
      );

      if (!mounted) return;

      _mostrarMensaje('¡Cita reservada! Estado: ${cita.estado}.');

      setState(() {
        _fechaSeleccionada = null;
        _horaSeleccionada = null;
      });
    } catch (e) {
      if (!mounted) return;

      _mostrarMensaje(
        'No se pudo reservar la cita. Verifica la disponibilidad e inténtalo de nuevo.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _reservando = false;
        });
      }
    }
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CUT & GO | Reservar cita'),
        centerTitle: true,
      ),
      body: _cargando && _barberias.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _barberias.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _cargarBarberias,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          : _barberias.isEmpty
          ? const Center(child: Text('No hay barberías activas disponibles.'))
          : _construirFormulario(),
    );
  }

  Widget _construirFormulario() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Agenda tu próximo corte',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text('Selecciona tu barbería, el profesional y el servicio.'),
        const SizedBox(height: 24),
        DropdownButtonFormField<Barberia>(
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Barbería',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.store),
          ),
          items: _barberias
              .map(
                (b) => DropdownMenuItem(
                  value: b,
                  child: Text(b.nombre, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: _cargando
              ? null
              : (barberia) {
                  if (barberia == null) return;

                  setState(() {
                    _barberiaSeleccionada = barberia;
                    _barberoSeleccionado = null;
                    _servicioSeleccionado = null;
                    _fechaSeleccionada = null;
                    _horaSeleccionada = null;
                  });

                  _cargarBarberos(barberia.id);
                },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<Barbero>(
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Barbero',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),
          items: _barberos
              .map(
                (b) => DropdownMenuItem(
                  value: b,
                  child: Text('${b.nombre} ${b.apellido}'.trim()),
                ),
              )
              .toList(),
          onChanged: _cargando
              ? null
              : (barbero) {
                  setState(() {
                    _barberoSeleccionado = barbero;
                  });
                },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<Servicio>(
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Servicio',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.content_cut),
          ),
          items: _servicios
              .map(
                (s) => DropdownMenuItem(
                  value: s,
                  child: Text(
                    '${s.nombre} · ${s.duracionMin} min · \$${s.precio.toStringAsFixed(0)}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: _cargando
              ? null
              : (servicio) {
                  setState(() {
                    _servicioSeleccionado = servicio;
                  });
                },
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _elegirFecha,
          icon: const Icon(Icons.calendar_month),
          label: Text(
            _fechaSeleccionada == null
                ? 'Seleccionar fecha'
                : '${_fechaSeleccionada!.day.toString().padLeft(2, '0')}/'
                      '${_fechaSeleccionada!.month.toString().padLeft(2, '0')}/'
                      '${_fechaSeleccionada!.year}',
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _elegirHora,
          icon: const Icon(Icons.schedule),
          label: Text(
            _horaSeleccionada == null
                ? 'Seleccionar hora'
                : _horaSeleccionada!.format(context),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: 24),
        SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _reservando || _cargando ? null : _reservar,
            icon: _reservando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_outline),
            label: Text(_reservando ? 'Reservando...' : 'Confirmar reserva'),
          ),
        ),
      ],
    );
  }
}
