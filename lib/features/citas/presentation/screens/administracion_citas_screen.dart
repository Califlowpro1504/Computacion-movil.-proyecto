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

  final Set<String> _citasProcesando = {};

  @override
  void initState() {
    super.initState();
    _cargarCitas();
  }

  // ============================================================
  // CARGAR CITAS
  // ============================================================

  Future<void> _cargarCitas({bool mostrarCarga = true}) async {
    if (mostrarCarga && mounted) {
      setState(() {
        _cargando = true;
        _error = null;
      });
    }

    try {
      final resultado = await _citaRepository.obtenerTodasLasCitasAdmin();

      if (!mounted) return;

      setState(() {
        _citas = resultado;
        _cargando = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }

  // ============================================================
  // CONVERTIR RELACIONES DE SUPABASE EN MAPAS
  // ============================================================

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

  // ============================================================
  // FORMATEAR FECHAS Y HORAS
  // ============================================================

  DateTime? _convertirFecha(dynamic valor) {
    if (valor == null) return null;

    try {
      return DateTime.parse(valor.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  String _formatearFecha(dynamic valor) {
    final fecha = _convertirFecha(valor);

    if (fecha == null) return 'No disponible';

    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');

    return '$dia/$mes/${fecha.year}';
  }

  String _formatearHora(dynamic valor) {
    final fecha = _convertirFecha(valor);

    if (fecha == null) return '--:--';

    final hora = fecha.hour.toString().padLeft(2, '0');
    final minutos = fecha.minute.toString().padLeft(2, '0');

    return '$hora:$minutos';
  }

  // ============================================================
  // ESTADOS Y COLORES
  // ============================================================

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

  // ============================================================
  // CONTADORES Y FILTROS
  // ============================================================

  int _contarEstado(String estado) {
    return _citas.where((cita) {
      return cita['estado']?.toString().toLowerCase() == estado;
    }).length;
  }

  List<Map<String, dynamic>> get _citasFiltradas {
    if (_filtroEstado == 'todas') return _citas;

    return _citas.where((cita) {
      return cita['estado']?.toString().toLowerCase() == _filtroEstado;
    }).toList();
  }

  Widget _tarjetaResumen(
    String titulo,
    int cantidad,
    Color color,
    IconData icono,
  ) {
    return SizedBox(
      width: 155,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icono, color: color, size: 23),
              const SizedBox(height: 9),
              Text(titulo, style: TextStyle(color: Colors.grey.shade700)),
              const SizedBox(height: 5),
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
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _tarjetaResumen(
          'Total',
          _citas.length,
          Colors.blue,
          Icons.calendar_month,
        ),
        _tarjetaResumen(
          'Pendientes',
          _contarEstado('pendiente'),
          Colors.orange,
          Icons.pending_actions,
        ),
        _tarjetaResumen(
          'Confirmadas',
          _contarEstado('confirmada'),
          Colors.green,
          Icons.check_circle_outline,
        ),
        _tarjetaResumen(
          'Completadas',
          _contarEstado('completada'),
          Colors.indigo,
          Icons.task_alt,
        ),
        _tarjetaResumen(
          'Canceladas',
          _contarEstado('cancelada'),
          Colors.red,
          Icons.cancel_outlined,
        ),
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

  // ============================================================
  // INFORMACIÓN DE CADA CITA
  // ============================================================

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

  // ============================================================
  // CONFIRMAR ACCIONES
  // ============================================================

  Future<bool> _confirmarAccion({
    required String titulo,
    required String mensaje,
    required String textoBoton,
  }) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(titulo),
          content: Text(mensaje),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Volver'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: Text(textoBoton),
            ),
          ],
        );
      },
    );

    return resultado ?? false;
  }

  // ============================================================
  // CAMBIAR ESTADO DE UNA CITA
  // ============================================================

  Future<void> _gestionarEstado({
    required Map<String, dynamic> cita,
    required String nuevoEstado,
  }) async {
    final citaId = cita['id']?.toString();

    if (citaId == null || citaId.isEmpty) {
      _mostrarMensaje(
        'No se encontró el identificador de la cita.',
        esError: true,
      );
      return;
    }

    if (_citasProcesando.contains(citaId)) return;

    String titulo;
    String mensaje;
    String textoBoton;
    String mensajeExito;

    switch (nuevoEstado) {
      case 'confirmada':
        titulo = 'Confirmar cita';
        mensaje = '¿Deseas confirmar esta cita?';
        textoBoton = 'Confirmar';
        mensajeExito = 'La cita fue confirmada correctamente.';
        break;

      case 'cancelada':
        titulo = 'Cancelar cita';
        mensaje = '¿Estás seguro de que deseas cancelar esta cita?';
        textoBoton = 'Cancelar cita';
        mensajeExito = 'La cita fue cancelada correctamente.';
        break;

      case 'completada':
        titulo = 'Completar cita';
        mensaje = '¿Deseas marcar esta cita como completada?';
        textoBoton = 'Completar';
        mensajeExito = 'La cita fue completada correctamente.';
        break;

      default:
        return;
    }

    final confirmado = await _confirmarAccion(
      titulo: titulo,
      mensaje: mensaje,
      textoBoton: textoBoton,
    );

    if (!confirmado || !mounted) return;

    setState(() {
      _citasProcesando.add(citaId);
    });

    try {
      await _citaRepository.gestionarEstado(
        citaId: citaId,
        nuevoEstado: nuevoEstado,
      );

      if (!mounted) return;

      await _cargarCitas(mostrarCarga: false);

      if (!mounted) return;

      _mostrarMensaje(mensajeExito);
    } catch (e) {
      if (!mounted) return;

      _mostrarMensaje(
        'No se pudo actualizar la cita: ${_limpiarError(e)}',
        esError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _citasProcesando.remove(citaId);
        });
      }
    }
  }

  String _limpiarError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  void _mostrarMensaje(String mensaje, {bool esError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: esError ? Colors.red : Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // BOTONES DISPONIBLES SEGÚN ESTADO Y FECHAS
  // ============================================================

  Widget _construirAcciones(Map<String, dynamic> cita) {
    final estado = cita['estado']?.toString().toLowerCase() ?? '';
    final citaId = cita['id']?.toString() ?? '';
    final procesando = _citasProcesando.contains(citaId);

    final fechaInicio = _convertirFecha(cita['fecha_inicio']);
    final fechaFin = _convertirFecha(cita['fecha_fin']);

    final ahora = DateTime.now();

    final esFutura = fechaInicio != null && fechaInicio.isAfter(ahora);

    final puedeCompletar = fechaFin != null && !fechaFin.isAfter(ahora);

    if (estado != 'pendiente' && estado != 'confirmada') {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 20),
        if (procesando)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (estado == 'pendiente')
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                onPressed: esFutura
                    ? () {
                        _gestionarEstado(cita: cita, nuevoEstado: 'confirmada');
                      }
                    : null,
                icon: const Icon(Icons.check),
                label: const Text('Confirmar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              OutlinedButton.icon(
                onPressed: esFutura
                    ? () {
                        _gestionarEstado(cita: cita, nuevoEstado: 'cancelada');
                      }
                    : null,
                icon: const Icon(Icons.close),
                label: const Text('Cancelar'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                onPressed: puedeCompletar
                    ? () {
                        _gestionarEstado(cita: cita, nuevoEstado: 'completada');
                      }
                    : null,
                icon: const Icon(Icons.task_alt),
                label: const Text('Completar'),
              ),
              OutlinedButton.icon(
                onPressed: esFutura
                    ? () {
                        _gestionarEstado(cita: cita, nuevoEstado: 'cancelada');
                      }
                    : null,
                icon: const Icon(Icons.close),
                label: const Text('Cancelar'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ),
        if (!esFutura && estado == 'pendiente')
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Esta cita ya comenzó o pasó. No se puede confirmar ni cancelar.',
              style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
            ),
          ),
        if (!esFutura && estado == 'confirmada' && !puedeCompletar)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Esta cita ya comenzó. Podrás completarla cuando termine.',
              style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // TARJETA DE CITA
  // ============================================================

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
            _construirAcciones(cita),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CONTENIDO PRINCIPAL
  // ============================================================

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

  // ============================================================
  // PANTALLA
  // ============================================================

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
