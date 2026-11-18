import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/cita.dart';
import '../../domain/services/disponibilidad_citas.dart';
import '../../../horarios/domain/entities/horario.dart';

class CitaRepository {
  final SupabaseClient _client;
  final DisponibilidadCitas _disponibilidad;

  CitaRepository({
    SupabaseClient? client,
    this._disponibilidad = const DisponibilidadCitas(),
  }) : _client = client ?? Supabase.instance.client;

  static const String _tabla = 'citas';

  static const int _margenMaximoMinutos = 10;

  // ============================================================
  // REGLA DE MÁRGENES
  // ============================================================

  static int margenMinutosParaDuracion(int duracion) {
    if (duracion == 20 || duracion == 30) {
      return 10;
    }

    if (duracion == 45 || duracion == 60) {
      return 5;
    }

    // Para cualquier otro servicio:
    // 10 minutos si dura hasta 30, 5 si dura más.
    return duracion <= 30 ? 10 : 5;
  }

  // Obtiene los márgenes de las citas existentes.
  // Se consulta la duración de cada servicio en Supabase.
  Future<Map<String, int>> obtenerMargenesCitas(List<Cita> citas) async {
    if (citas.isEmpty) {
      return {};
    }

    final serviciosIds = citas.map((cita) => cita.servicioId).toSet().toList();

    final servicios = await _client
        .from('servicios')
        .select('id, duracion_min')
        .inFilter('id', serviciosIds);

    final margenesPorServicio = <String, int>{};

    for (final servicio in servicios) {
      final id = servicio['id'].toString();
      final duracion = (servicio['duracion_min'] as num?)?.toInt() ?? 0;

      margenesPorServicio[id] = margenMinutosParaDuracion(duracion);
    }

    final resultado = <String, int>{};

    for (final cita in citas) {
      resultado[cita.id] = margenesPorServicio[cita.servicioId] ?? 10;
    }

    return resultado;
  }

  // Comprueba el espacio ocupado por la cita nueva y las existentes.
  // El margen se aplica después de cada servicio.
  static bool tieneCruceConMargen({
    required DateTime inicio,
    required DateTime fin,
    required int duracionMinutos,
    required List<Cita> citas,
    required Map<String, int> margenesPorCita,
  }) {
    final margenNuevo = margenMinutosParaDuracion(duracionMinutos);

    final finNuevoConMargen = fin.add(Duration(minutes: margenNuevo));

    for (final cita in citas) {
      final margenExistente = margenesPorCita[cita.id] ?? 10;

      final finExistenteConMargen = cita.fechaFin.add(
        Duration(minutes: margenExistente),
      );

      final seCruzan =
          inicio.isBefore(finExistenteConMargen) &&
          finNuevoConMargen.isAfter(cita.fechaInicio);

      if (seCruzan) {
        return true;
      }
    }

    return false;
  }

  Cita _fromMap(Map<String, dynamic> m) {
    return Cita(
      id: m['id'].toString(),
      userId: m['user_id'].toString(),
      barberiaId: m['barberia_id'].toString(),
      barberoId: m['barbero_id'].toString(),
      servicioId: m['servicio_id'].toString(),
      fechaInicio: DateTime.parse(m['fecha_inicio'].toString()).toLocal(),
      fechaFin: DateTime.parse(m['fecha_fin'].toString()).toLocal(),
      estado: (m['estado'] ?? 'pendiente').toString(),
    );
  }

  String _hhmm(dynamic valor) {
    final texto = (valor ?? '00:00').toString();
    return texto.length >= 5 ? texto.substring(0, 5) : texto;
  }

  // ============================================================
  // CONSULTA ADMINISTRATIVA: TODAS LAS CITAS
  // ============================================================

  Future<List<Map<String, dynamic>>> obtenerTodasLasCitasAdmin() async {
    final usuario = _client.auth.currentUser;

    if (usuario == null) {
      throw Exception('Debes iniciar sesión para consultar las citas.');
    }

    final data = await _client
        .from(_tabla)
        .select('''
          id,
          user_id,
          barberia_id,
          barbero_id,
          servicio_id,
          fecha_inicio,
          fecha_fin,
          estado,
          barberias(nombre),
          barberos(nombre, apellido),
          servicios(nombre)
        ''')
        .order('fecha_inicio', ascending: false);

    final usuariosIds = data
        .map((cita) => cita['user_id'].toString())
        .toSet()
        .toList();

    final perfiles = usuariosIds.isEmpty
        ? <Map<String, dynamic>>[]
        : await _client
              .from('profiles')
              .select('id, nombre, apellido')
              .inFilter('id', usuariosIds);

    final perfilesPorId = <String, Map<String, dynamic>>{};

    for (final perfil in perfiles) {
      perfilesPorId[perfil['id'].toString()] = Map<String, dynamic>.from(
        perfil,
      );
    }

    return data.map<Map<String, dynamic>>((cita) {
      final resultado = Map<String, dynamic>.from(cita);

      resultado['cliente'] = perfilesPorId[cita['user_id'].toString()];

      return resultado;
    }).toList();
  }

  // ============================================================
  // CONSULTA DE CITAS DEL CLIENTE
  // ============================================================

  Future<List<Cita>> obtenerMisCitas() async {
    final usuario = _client.auth.currentUser;

    if (usuario == null) {
      throw Exception('Debes iniciar sesión para consultar tus citas.');
    }

    final data = await _client
        .from(_tabla)
        .select()
        .eq('user_id', usuario.id)
        .order('fecha_inicio');

    return data.map<Cita>(_fromMap).toList();
  }

  // ============================================================
  // CONSULTA DE CITAS DE UN BARBERO EN UN DÍA
  // ============================================================

  Future<List<Cita>> obtenerCitasDelDia({
    required String barberoId,
    required DateTime fecha,
  }) async {
    final inicioDia = DateTime(fecha.year, fecha.month, fecha.day);

    final finDia = inicioDia.add(const Duration(days: 1));

    // Se amplía la consulta 10 minutos para considerar
    // los márgenes de citas cercanas al cambio de día.
    final inicioBusqueda = inicioDia.subtract(
      const Duration(minutes: _margenMaximoMinutos),
    );

    final finBusqueda = finDia.add(
      const Duration(minutes: _margenMaximoMinutos),
    );

    final data = await _client
        .from(_tabla)
        .select()
        .eq('barbero_id', barberoId)
        .inFilter('estado', ['pendiente', 'confirmada'])
        .lt('fecha_inicio', finBusqueda.toUtc().toIso8601String())
        .gt('fecha_fin', inicioBusqueda.toUtc().toIso8601String())
        .order('fecha_inicio');

    return data.map<Cita>(_fromMap).toList();
  }

  // ============================================================
  // CREAR UNA CITA
  // ============================================================

  Future<Cita> crear({
    required String barberiaId,
    required String barberoId,
    required String servicioId,
    required DateTime fechaInicio,
  }) async {
    final usuario = _client.auth.currentUser;

    if (usuario == null) {
      throw Exception('Debes iniciar sesión para reservar una cita.');
    }

    final inicio = fechaInicio.toLocal();

    if (!inicio.isAfter(DateTime.now())) {
      throw Exception('Selecciona una fecha y hora futuras.');
    }

    final barbero = await _client
        .from('barberos')
        .select('id')
        .eq('id', barberoId)
        .eq('barberia_id', barberiaId)
        .eq('activo', true)
        .maybeSingle();

    if (barbero == null) {
      throw Exception(
        'El barbero no pertenece a esta barbería '
        'o no está disponible.',
      );
    }

    final servicio = await _client
        .from('servicios')
        .select('duracion_min')
        .eq('id', servicioId)
        .eq('barberia_id', barberiaId)
        .eq('activo', true)
        .maybeSingle();

    if (servicio == null) {
      throw Exception('El servicio no existe o no está disponible.');
    }

    final duracion = (servicio['duracion_min'] as num).toInt();

    if (duracion <= 0) {
      throw Exception('El servicio tiene una duración no válida.');
    }

    // La fecha final guardada solo incluye la duración real.
    final fin = inicio.add(Duration(minutes: duracion));

    final margen = margenMinutosParaDuracion(duracion);

    // Para validar el horario laboral se tiene en cuenta
    // también el margen de preparación.
    final bloqueTotal = duracion + margen;

    final horariosData = await _client
        .from('horarios')
        .select()
        .eq('barbero_id', barberoId)
        .eq('activo', true);

    final horarios = horariosData.map<Horario>((m) {
      return Horario(
        id: m['id'].toString(),
        barberoId: m['barbero_id'].toString(),
        dia: (m['dia'] as num).toInt(),
        horaInicio: _hhmm(m['hora_inicio']),
        horaFin: _hhmm(m['hora_fin']),
        activo: m['activo'] as bool? ?? true,
      );
    }).toList();

    final cabe = _disponibilidad.cabeEnHorario(
      inicio: inicio,
      duracionMinutos: bloqueTotal,
      horarios: horarios,
    );

    if (!cabe) {
      throw Exception(
        'La cita y su margen no caben dentro '
        'del horario laboral del barbero.',
      );
    }

    // Buscar citas que puedan interferir con el bloque completo.
    final inicioBusqueda = inicio.subtract(
      const Duration(minutes: _margenMaximoMinutos),
    );

    final finBusqueda = fin.add(Duration(minutes: margen));

    final ocupadas = await _client
        .from(_tabla)
        .select()
        .eq('barbero_id', barberoId)
        .inFilter('estado', ['pendiente', 'confirmada'])
        .lt('fecha_inicio', finBusqueda.toUtc().toIso8601String())
        .gt('fecha_fin', inicioBusqueda.toUtc().toIso8601String());

    final citas = ocupadas.map<Cita>(_fromMap).toList();

    final margenesPorCita = await obtenerMargenesCitas(citas);

    final tieneCruce = tieneCruceConMargen(
      inicio: inicio,
      fin: fin,
      duracionMinutos: duracion,
      citas: citas,
      margenesPorCita: margenesPorCita,
    );

    if (tieneCruce) {
      throw Exception(
        'Ese horario no respeta el margen entre citas. '
        'Elige otro horario.',
      );
    }

    final data = await _client
        .from(_tabla)
        .insert({
          'user_id': usuario.id,
          'barberia_id': barberiaId,
          'barbero_id': barberoId,
          'servicio_id': servicioId,
          'fecha_inicio': inicio.toUtc().toIso8601String(),
          'fecha_fin': fin.toUtc().toIso8601String(),
          'estado': 'pendiente',
        })
        .select()
        .single();

    return _fromMap(data);
  }

  // ============================================================
  // OBTENER HORARIOS DISPONIBLES PARA REPROGRAMAR
  // ============================================================

  Future<List<DateTime>> obtenerHorariosDisponibles({
    required String citaId,
    required DateTime fecha,
  }) async {
    final usuario = _client.auth.currentUser;

    if (usuario == null) {
      throw Exception('Debes iniciar sesión para consultar horarios.');
    }

    final cita = await _client
        .from(_tabla)
        .select('barbero_id, barberia_id, servicio_id, estado, fecha_inicio')
        .eq('id', citaId)
        .eq('user_id', usuario.id)
        .maybeSingle();

    if (cita == null) {
      throw Exception('No se encontró la cita.');
    }

    final estado = cita['estado'].toString();

    if (estado != 'pendiente' && estado != 'confirmada') {
      throw Exception('Esta cita no se puede reprogramar.');
    }

    final barberoId = cita['barbero_id'].toString();
    final barberiaId = cita['barberia_id'].toString();
    final servicioId = cita['servicio_id'].toString();

    final servicio = await _client
        .from('servicios')
        .select('duracion_min')
        .eq('id', servicioId)
        .eq('barberia_id', barberiaId)
        .eq('activo', true)
        .maybeSingle();

    if (servicio == null) {
      throw Exception('El servicio ya no está disponible.');
    }

    final duracion = (servicio['duracion_min'] as num).toInt();

    if (duracion <= 0) {
      throw Exception('La duración del servicio no es válida.');
    }

    final margen = margenMinutosParaDuracion(duracion);
    final bloqueTotal = duracion + margen;

    final dia = DateTime(fecha.year, fecha.month, fecha.day);

    final finDia = dia.add(const Duration(days: 1));

    final horariosData = await _client
        .from('horarios')
        .select()
        .eq('barbero_id', barberoId)
        .eq('activo', true)
        .eq('dia', dia.weekday);

    final horarios = horariosData.map<Horario>((m) {
      return Horario(
        id: m['id'].toString(),
        barberoId: m['barbero_id'].toString(),
        dia: (m['dia'] as num).toInt(),
        horaInicio: _hhmm(m['hora_inicio']),
        horaFin: _hhmm(m['hora_fin']),
        activo: m['activo'] as bool? ?? true,
      );
    }).toList();

    if (horarios.isEmpty) {
      return [];
    }

    final inicioBusqueda = dia.subtract(
      const Duration(minutes: _margenMaximoMinutos),
    );

    final finBusqueda = finDia.add(
      const Duration(minutes: _margenMaximoMinutos),
    );

    final ocupadas = await _client
        .from(_tabla)
        .select()
        .eq('barbero_id', barberoId)
        .inFilter('estado', ['pendiente', 'confirmada'])
        .neq('id', citaId)
        .lt('fecha_inicio', finBusqueda.toUtc().toIso8601String())
        .gt('fecha_fin', inicioBusqueda.toUtc().toIso8601String());

    final citas = ocupadas.map<Cita>(_fromMap).toList();

    final margenesPorCita = await obtenerMargenesCitas(citas);

    final disponibles = <DateTime>{};
    final ahora = DateTime.now();

    for (final horario in horarios) {
      final partesInicio = horario.horaInicio.split(':');
      final partesFin = horario.horaFin.split(':');

      final horaInicio =
          int.parse(partesInicio[0]) * 60 + int.parse(partesInicio[1]);

      final horaFin = int.parse(partesFin[0]) * 60 + int.parse(partesFin[1]);

      // Los horarios se generan usando duración + margen.
      for (
        int minuto = horaInicio;
        minuto + bloqueTotal <= horaFin;
        minuto += bloqueTotal
      ) {
        final inicio = dia.add(
          Duration(hours: minuto ~/ 60, minutes: minuto % 60),
        );

        if (!inicio.isAfter(ahora)) {
          continue;
        }

        final fin = inicio.add(Duration(minutes: duracion));

        final tieneCruce = tieneCruceConMargen(
          inicio: inicio,
          fin: fin,
          duracionMinutos: duracion,
          citas: citas,
          margenesPorCita: margenesPorCita,
        );

        if (!tieneCruce) {
          disponibles.add(inicio);
        }
      }
    }

    final resultado = disponibles.toList()..sort();

    return resultado;
  }

  // ============================================================
  // REPROGRAMAR UNA CITA
  // ============================================================

  Future<void> reprogramar({
    required String citaId,
    required DateTime nuevaFechaInicio,
  }) async {
    final usuario = _client.auth.currentUser;

    if (usuario == null) {
      throw Exception('Debes iniciar sesión para reprogramar una cita.');
    }

    final citaActual = await _client
        .from(_tabla)
        .select()
        .eq('id', citaId)
        .eq('user_id', usuario.id)
        .maybeSingle();

    if (citaActual == null) {
      throw Exception('No se encontró la cita o no tienes permiso.');
    }

    final estado = citaActual['estado'].toString();

    if (estado != 'pendiente' && estado != 'confirmada') {
      throw Exception('Esta cita no se puede reprogramar.');
    }

    final fechaActual = DateTime.parse(citaActual['fecha_inicio'].toString())
        .toLocal();

    if (!fechaActual.isAfter(DateTime.now())) {
      throw Exception('No puedes reprogramar una cita que ya comenzó.');
    }

    final inicio = nuevaFechaInicio.toLocal();

    if (!inicio.isAfter(DateTime.now())) {
      throw Exception('Selecciona una fecha y hora futuras.');
    }

    final barberiaId = citaActual['barberia_id'].toString();
    final barberoId = citaActual['barbero_id'].toString();
    final servicioId = citaActual['servicio_id'].toString();

    final servicio = await _client
        .from('servicios')
        .select('duracion_min')
        .eq('id', servicioId)
        .eq('barberia_id', barberiaId)
        .eq('activo', true)
        .maybeSingle();

    if (servicio == null) {
      throw Exception('El servicio ya no está disponible.');
    }

    final duracion = (servicio['duracion_min'] as num).toInt();

    if (duracion <= 0) {
      throw Exception('La duración del servicio no es válida.');
    }

    final margen = margenMinutosParaDuracion(duracion);
    final bloqueTotal = duracion + margen;

    final fin = inicio.add(Duration(minutes: duracion));

    final horariosData = await _client
        .from('horarios')
        .select()
        .eq('barbero_id', barberoId)
        .eq('activo', true);

    final horarios = horariosData.map<Horario>((m) {
      return Horario(
        id: m['id'].toString(),
        barberoId: m['barbero_id'].toString(),
        dia: (m['dia'] as num).toInt(),
        horaInicio: _hhmm(m['hora_inicio']),
        horaFin: _hhmm(m['hora_fin']),
        activo: m['activo'] as bool? ?? true,
      );
    }).toList();

    final cabe = _disponibilidad.cabeEnHorario(
      inicio: inicio,
      duracionMinutos: bloqueTotal,
      horarios: horarios,
    );

    if (!cabe) {
      throw Exception(
        'El nuevo horario y su margen no están '
        'dentro de la jornada del barbero.',
      );
    }

    final inicioBusqueda = inicio.subtract(
      const Duration(minutes: _margenMaximoMinutos),
    );

    final finBusqueda = fin.add(Duration(minutes: margen));

    final ocupadas = await _client
        .from(_tabla)
        .select()
        .eq('barbero_id', barberoId)
        .inFilter('estado', ['pendiente', 'confirmada'])
        .neq('id', citaId)
        .lt('fecha_inicio', finBusqueda.toUtc().toIso8601String())
        .gt('fecha_fin', inicioBusqueda.toUtc().toIso8601String());

    final citas = ocupadas.map<Cita>(_fromMap).toList();

    final margenesPorCita = await obtenerMargenesCitas(citas);

    final tieneCruce = tieneCruceConMargen(
      inicio: inicio,
      fin: fin,
      duracionMinutos: duracion,
      citas: citas,
      margenesPorCita: margenesPorCita,
    );

    if (tieneCruce) {
      throw Exception(
        'Ese horario no respeta el margen entre citas. '
        'Elige otro.',
      );
    }

    final resultado = await _client
        .from(_tabla)
        .update({
          'fecha_inicio': inicio.toUtc().toIso8601String(),
          'fecha_fin': fin.toUtc().toIso8601String(),
        })
        .eq('id', citaId)
        .eq('user_id', usuario.id)
        .inFilter('estado', ['pendiente', 'confirmada'])
        .gt('fecha_inicio', DateTime.now().toUtc().toIso8601String())
        .select('id');

    if (resultado.isEmpty) {
      throw Exception(
        'No se pudo reprogramar. La cita pudo cambiar '
        'de estado o fecha.',
      );
    }
  }

  // ============================================================
  // CANCELAR UNA CITA
  // ============================================================

  Future<void> cancelar(String citaId) async {
    final usuario = _client.auth.currentUser;

    if (usuario == null) {
      throw Exception('Debes iniciar sesión para cancelar una cita.');
    }

    final cita = await _client
        .from(_tabla)
        .select('id, estado, fecha_inicio')
        .eq('id', citaId)
        .eq('user_id', usuario.id)
        .maybeSingle();

    if (cita == null) {
      throw Exception('No se encontró la cita o no tienes permiso.');
    }

    final estado = cita['estado'].toString();

    final fechaInicio = DateTime.parse(cita['fecha_inicio'].toString())
        .toLocal();

    if (estado != 'pendiente' && estado != 'confirmada') {
      throw Exception('Esta cita ya no se puede cancelar.');
    }

    if (!fechaInicio.isAfter(DateTime.now())) {
      throw Exception('No puedes cancelar una cita que ya comenzó.');
    }

    final resultado = await _client
        .from(_tabla)
        .update({'estado': 'cancelada'})
        .eq('id', citaId)
        .eq('user_id', usuario.id)
        .inFilter('estado', ['pendiente', 'confirmada'])
        .gt('fecha_inicio', DateTime.now().toUtc().toIso8601String())
        .select('id');

    if (resultado.isEmpty) {
      throw Exception(
        'No se pudo cancelar. La cita pudo cambiar '
        'de estado o fecha.',
      );
    }
  }

  // ============================================================
  // GESTIONAR ESTADO DE UNA CITA
  // ADMINISTRADOR GENERAL Y PROPIETARIO
  // ============================================================

  Future<void> gestionarEstado({
    required String citaId,
    required String nuevoEstado,
  }) async {
    final usuario = _client.auth.currentUser;

    if (usuario == null) {
      throw Exception('Debes iniciar sesión para gestionar las citas.');
    }

    const estadosPermitidos = ['confirmada', 'cancelada', 'completada'];

    if (!estadosPermitidos.contains(nuevoEstado)) {
      throw Exception('El estado solicitado no es válido.');
    }

    await _client.rpc(
      'gestionar_estado_cita',
      params: {'p_cita_id': citaId, 'p_nuevo_estado': nuevoEstado},
    );
  }
}
