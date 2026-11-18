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
  bool _cancelando = false;
  bool _reprogramando = false;

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

      final barberias = await _client.from('barberias').select('id, nombre');
      final barberos = await _client.from('barberos').select('id, nombre');
      final servicios = await _client.from('servicios').select('id, nombre');

      if (!mounted) return;

      _barberias.clear();
      _barberos.clear();
      _servicios.clear();

      for (final item in barberias) {
        _barberias[item['id'].toString()] =
            item['nombre']?.toString() ?? 'Barbería';
      }

      for (final item in barberos) {
        _barberos[item['id'].toString()] =
            item['nombre']?.toString() ?? 'Barbero';
      }

      for (final item in servicios) {
        _servicios[item['id'].toString()] =
            item['nombre']?.toString() ?? 'Servicio';
      }

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

  bool _puedeModificar(Cita cita) {
    return _esProxima(cita) && cita.fechaInicio.isAfter(DateTime.now());
  }

  Future<void> _cancelarCita(Cita cita) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar cita'),
        content: const Text('¿Estás seguro de que deseas cancelar esta cita?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    setState(() {
      _cancelando = true;
    });

    try {
      await _citaRepository.cancelar(cita.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La cita fue cancelada correctamente.'),
          backgroundColor: Colors.green,
        ),
      );

      await _cargarCitas();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo cancelar la cita: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _cancelando = false;
        });
      }
    }
  }

  Future<void> _reprogramarCita(Cita cita) async {
    final ahora = DateTime.now();

    final fechaInicial = cita.fechaInicio.isAfter(ahora)
        ? cita.fechaInicio
        : ahora.add(const Duration(minutes: 1));

    final nuevaFecha = await showDatePicker(
      context: context,
      initialDate: fechaInicial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      helpText: 'Selecciona la nueva fecha',
    );

    if (nuevaFecha == null || !mounted) return;

    setState(() {
      _reprogramando = true;
    });

    try {
      final horarios = await _citaRepository.obtenerHorariosDisponibles(
        citaId: cita.id,
        fecha: nuevaFecha,
      );

      if (!mounted) return;

      if (horarios.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay horarios disponibles para esta fecha.'),
          ),
        );
        return;
      }

      final fechaHora = await showDialog<DateTime>(
        context: context,
        builder: (dialogContext) {
          DateTime? seleccionada;

          return StatefulBuilder(
            builder: (context, actualizarDialogo) {
              return AlertDialog(
                title: const Text('Horarios disponibles'),
                content: SizedBox(
                  width: 350,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Selecciona una hora para el '
                          '${_formatearFecha(nuevaFecha)}',
                        ),
                        const SizedBox(height: 12),
                        ...horarios.map((hora) {
                          final seleccionadaActual = seleccionada == hora;

                          return Card(
                            child: ListTile(
                              leading: Icon(
                                seleccionadaActual
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: seleccionadaActual
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey,
                              ),
                              title: Text(
                                _formatearHora(hora),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Finaliza a las ${_formatearHora(hora.add(cita.fechaFin.difference(cita.fechaInicio)))}',
                              ),
                              selected: seleccionadaActual,
                              onTap: () {
                                actualizarDialogo(() {
                                  seleccionada = hora;
                                });
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Volver'),
                  ),
                  FilledButton(
                    onPressed: seleccionada == null
                        ? null
                        : () => Navigator.pop(dialogContext, seleccionada),
                    child: const Text('Continuar'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (fechaHora == null || !mounted) return;

      final confirmar = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Confirmar reprogramación'),
          content: Text(
            '¿Deseas cambiar tu cita para el '
            '${_formatearFecha(fechaHora)} a las '
            '${_formatearHora(fechaHora)}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Volver'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      );

      if (confirmar != true || !mounted) return;

      await _citaRepository.reprogramar(
        citaId: cita.id,
        nuevaFechaInicio: fechaHora,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La cita fue reprogramada correctamente.'),
          backgroundColor: Colors.green,
        ),
      );

      await _cargarCitas();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo reprogramar la cita: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _reprogramando = false;
        });
      }
    }
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
    final puedeModificar = _puedeModificar(cita);

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

            if (puedeModificar) ...[
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: (_cancelando || _reprogramando)
                        ? null
                        : () => _reprogramarCita(cita),
                    icon: const Icon(Icons.edit_calendar),
                    label: const Text('Reprogramar'),
                  ),
                  OutlinedButton.icon(
                    onPressed: (_cancelando || _reprogramando)
                        ? null
                        : () => _cancelarCita(cita),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Cancelar cita'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
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
    final historial = _citas.where((cita) => !_esProxima(cita)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis citas'),
        actions: [
          IconButton(
            onPressed: _cargando ? null : _cargarCitas,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar citas',
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No se pudieron cargar las citas.\n$_error',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _cargarCitas,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _cargarCitas,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _construirSeccion('Próximas citas', proximas),
                  _construirSeccion('Historial', historial),
                ],
              ),
            ),
    );
  }
}
