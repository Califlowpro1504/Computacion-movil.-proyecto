import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../barberias/data/repositories/barberia_repository_impl.dart';
import '../../../barberias/domain/entities/barberia.dart';
import '../../../barberos/data/barbero_repository.dart';
import '../../../barberos/domain/entities/barbero.dart';
import '../../../servicios/data/servicio_repository.dart';
import '../../../servicios/domain/entities/servicio.dart';
import '../../../horarios/data/horario_repository.dart';
import '../../data/repositories/cita_repository.dart';
import '../../domain/services/disponibilidad_citas.dart';

class ReservarCitaScreen extends StatefulWidget {
  const ReservarCitaScreen({super.key});

  @override
  State<ReservarCitaScreen> createState() => _ReservarCitaScreenState();
}

class _ReservarCitaScreenState extends State<ReservarCitaScreen> {
  final _barberiaRepository = BarberiaRepositoryImpl();
  final _barberoRepository = BarberoRepository();
  final _servicioRepository = ServicioRepository();
  final _horarioRepository = HorarioRepository();
  final _citaRepository = CitaRepository();
  final _disponibilidad = const DisponibilidadCitas();

  static const int _intervaloMinutos = 45;

  List<Barberia> _barberias = [];
  List<Barbero> _barberos = [];
  List<Servicio> _servicios = [];

  Barberia? _barberiaSeleccionada;
  Barbero? _barberoSeleccionado;
  Servicio? _servicioSeleccionado;

  // Los selectores usan identificadores únicos, no objetos completos.
  String? _barberiaSeleccionadaId;
  String? _barberoSeleccionadoId;
  String? _servicioSeleccionadoId;

  DateTime? _fechaSeleccionada;
  TimeOfDay? _horaSeleccionada;

  bool _cargando = true;
  bool _reservando = false;
  bool _cargandoHoras = false;

  String? _error;
  List<TimeOfDay> _horasDisponibles = [];

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
      _barberoSeleccionadoId = null;

      _servicioSeleccionado = null;
      _servicioSeleccionadoId = null;

      _barberos = [];
      _servicios = [];

      _fechaSeleccionada = null;
      _horaSeleccionada = null;
      _horasDisponibles = [];

      _cargandoHoras = false;
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
      firstDate: DateTime(ahora.year, ahora.month, ahora.day),
      lastDate: ahora.add(const Duration(days: 90)),
      helpText: 'Selecciona el día de tu cita',
    );

    if (fecha == null || !mounted) return;

    setState(() {
      _fechaSeleccionada = fecha;
      _horaSeleccionada = null;
      _horasDisponibles = [];
    });

    await _actualizarHorasDisponibles();
  }

  Future<void> _actualizarHorasDisponibles() async {
    final fecha = _fechaSeleccionada;
    final barbero = _barberoSeleccionado;
    final servicio = _servicioSeleccionado;

    if (fecha == null || barbero == null || servicio == null) {
      if (!mounted) return;

      setState(() {
        _horasDisponibles = [];
        _horaSeleccionada = null;
        _cargandoHoras = false;
      });

      return;
    }

    setState(() {
      _cargandoHoras = true;
      _horaSeleccionada = null;
      _horasDisponibles = [];
      _error = null;
    });

    try {
      final horarios = await _horarioRepository.obtenerPorBarbero(barbero.id);

      final citas = await _citaRepository.obtenerCitasDelDia(
        barberoId: barbero.id,
        fecha: fecha,
      );

      if (!mounted) return;

      final opciones = <TimeOfDay>[];
      final ahora = DateTime.now();

      // Genera opciones en intervalos de 45 minutos.
      // Se conservan la duración del servicio y las validaciones existentes.
      for (var minuto = 0; minuto < 24 * 60; minuto += _intervaloMinutos) {
        final hora = minuto ~/ 60;
        final minutoHora = minuto % 60;

        final inicio = DateTime(
          fecha.year,
          fecha.month,
          fecha.day,
          hora,
          minutoHora,
        );

        if (!inicio.isAfter(ahora)) continue;

        final cabe = _disponibilidad.cabeEnHorario(
          inicio: inicio,
          duracionMinutos: servicio.duracionMin,
          horarios: horarios,
        );

        if (!cabe) continue;

        final fin = inicio.add(Duration(minutes: servicio.duracionMin));

        final cruza = _disponibilidad.tieneCruce(
          inicio: inicio,
          fin: fin,
          citas: citas,
        );

        if (!cruza) {
          opciones.add(TimeOfDay(hour: hora, minute: minutoHora));
        }
      }

      setState(() {
        _horasDisponibles = opciones;
        _cargandoHoras = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cargandoHoras = false;
        _horasDisponibles = [];
        _error = 'No fue posible consultar la disponibilidad: $e';
      });
    }
  }

  Future<void> _elegirHora() async {
    if (_barberoSeleccionado == null || _servicioSeleccionado == null) {
      _mostrarMensaje('Selecciona primero un barbero y un servicio.');
      return;
    }

    if (_fechaSeleccionada == null) {
      _mostrarMensaje('Primero selecciona una fecha.');
      return;
    }

    if (_cargandoHoras) {
      _mostrarMensaje('Estamos consultando las horas disponibles.');
      return;
    }

    if (_horasDisponibles.isEmpty) {
      _mostrarMensaje(
        'No hay horas disponibles para esa fecha. Prueba otro día.',
      );
      return;
    }

    final hora = await showModalBottomSheet<TimeOfDay>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Horas disponibles',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ..._horasDisponibles.map(
                (opcion) => ListTile(
                  leading: const Icon(Icons.schedule),
                  title: Text(opcion.format(context)),
                  onTap: () => Navigator.pop(context, opcion),
                ),
              ),
            ],
          ),
        );
      },
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
        _horasDisponibles = [];
      });
    } catch (e) {
      if (!mounted) return;

      _mostrarMensaje(
        'No se pudo reservar la cita. Verifica la disponibilidad e inténtalo de nuevo.',
      );

      await _actualizarHorasDisponibles();
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
    // El valor de cada dropdown siempre debe coincidir con
    // exactamente un elemento de su lista.
    final barberiaIdValido = _barberias.any(
      (b) => b.id == _barberiaSeleccionadaId,
    );

    final barberoIdValido = _barberos.any(
      (b) => b.id == _barberoSeleccionadoId,
    );

    final servicioIdValido = _servicios.any(
      (s) => s.id == _servicioSeleccionadoId,
    );

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

        // Selector de barbería.
        DropdownButtonFormField<String>(
          key: ValueKey('barberia_$_barberiaSeleccionadaId'),
          isExpanded: true,
          initialValue: barberiaIdValido ? _barberiaSeleccionadaId : null,
          decoration: const InputDecoration(
            labelText: 'Barbería',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.store),
          ),
          items: _barberias
              .map(
                (b) => DropdownMenuItem<String>(
                  value: b.id,
                  child: Text(b.nombre, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: _cargando
              ? null
              : (barberiaId) {
                  if (barberiaId == null) return;

                  final coincidencias = _barberias.where(
                    (b) => b.id == barberiaId,
                  );

                  if (coincidencias.length != 1) return;

                  final barberia = coincidencias.first;

                  setState(() {
                    _barberiaSeleccionadaId = barberia.id;
                    _barberiaSeleccionada = barberia;

                    _barberoSeleccionadoId = null;
                    _barberoSeleccionado = null;

                    _servicioSeleccionadoId = null;
                    _servicioSeleccionado = null;

                    _fechaSeleccionada = null;
                    _horaSeleccionada = null;
                    _horasDisponibles = [];
                  });

                  _cargarBarberos(barberia.id);
                },
        ),

        const SizedBox(height: 16),

        // Selector de barbero: usa el ID como valor único.
        DropdownButtonFormField<String>(
          key: ValueKey(
            'barbero_${_barberiaSeleccionadaId}_$_barberoSeleccionadoId',
          ),
          isExpanded: true,
          initialValue: barberoIdValido ? _barberoSeleccionadoId : null,
          decoration: const InputDecoration(
            labelText: 'Barbero',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),
          items: _barberos
              .map(
                (b) => DropdownMenuItem<String>(
                  value: b.id,
                  child: Text('${b.nombre} ${b.apellido}'.trim()),
                ),
              )
              .toList(),
          onChanged: _cargando
              ? null
              : (barberoId) {
                  if (barberoId == null) return;

                  final coincidencias = _barberos.where(
                    (b) => b.id == barberoId,
                  );

                  if (coincidencias.length != 1) return;

                  final barbero = coincidencias.first;

                  setState(() {
                    _barberoSeleccionadoId = barbero.id;
                    _barberoSeleccionado = barbero;

                    _horaSeleccionada = null;
                    _horasDisponibles = [];
                  });

                  _actualizarHorasDisponibles();
                },
        ),

        const SizedBox(height: 16),

        // Selector de servicio.
        DropdownButtonFormField<String>(
          key: ValueKey(
            'servicio_${_barberiaSeleccionadaId}_$_servicioSeleccionadoId',
          ),
          isExpanded: true,
          initialValue: servicioIdValido ? _servicioSeleccionadoId : null,
          decoration: const InputDecoration(
            labelText: 'Servicio',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.content_cut),
          ),
          items: _servicios
              .map(
                (s) => DropdownMenuItem<String>(
                  value: s.id,
                  child: Text(
                    '${s.nombre} · ${s.duracionMin} min · \$${s.precio.toStringAsFixed(0)}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: _cargando
              ? null
              : (servicioId) {
                  if (servicioId == null) return;

                  final coincidencias = _servicios.where(
                    (s) => s.id == servicioId,
                  );

                  if (coincidencias.length != 1) return;

                  final servicio = coincidencias.first;

                  setState(() {
                    _servicioSeleccionadoId = servicio.id;
                    _servicioSeleccionado = servicio;

                    _horaSeleccionada = null;
                    _horasDisponibles = [];
                  });

                  _actualizarHorasDisponibles();
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
            _cargandoHoras
                ? 'Consultando disponibilidad...'
                : _horaSeleccionada == null
                ? 'Seleccionar hora'
                : _horaSeleccionada!.format(context),
          ),
        ),

        if (_fechaSeleccionada != null &&
            _barberoSeleccionado != null &&
            _servicioSeleccionado != null &&
            !_cargandoHoras)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _horasDisponibles.isEmpty
                  ? 'No hay horas disponibles para esta selección.'
                  : '${_horasDisponibles.length} opciones disponibles cada 45 minutos.',
              style: Theme.of(context).textTheme.bodySmall,
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
