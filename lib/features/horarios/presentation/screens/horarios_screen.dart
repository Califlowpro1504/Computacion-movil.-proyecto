import 'package:flutter/material.dart';
import '../../data/horario_repository.dart';
import '../../domain/entities/horario.dart';

const _dias = [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];

String _fmt(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

TimeOfDay _parse(String s) {
  final p = s.split(':');
  return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
}

int _minutos(String s) {
  final p = s.split(':');
  return int.parse(p[0]) * 60 + int.parse(p[1]);
}

class HorariosScreen extends StatefulWidget {
  final String barberoId;
  final String barberoNombre;

  const HorariosScreen({
    super.key,
    required this.barberoId,
    this.barberoNombre = '',
  });

  @override
  State<HorariosScreen> createState() => _HorariosScreenState();
}

class _HorariosScreenState extends State<HorariosScreen> {
  final _repo = HorarioRepository();
  late Future<List<Horario>> _futuro;
  List<Horario> _actuales = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    _futuro = _repo.obtenerPorBarbero(widget.barberoId).then((lista) {
      _actuales = lista;
      return lista;
    });
  }

  void _aviso(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  Future<void> _formulario([Horario? existente]) async {
    int dia = existente?.dia ?? 1;
    String inicio = existente?.horaInicio ?? '09:00';
    String fin = existente?.horaFin ?? '18:00';

    final guardar = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(existente == null ? 'Agregar horario' : 'Editar horario'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<int>(
              initialValue: dia,
              decoration: const InputDecoration(labelText: 'Día'),
              items: [
                for (var i = 0; i < _dias.length; i++)
                  DropdownMenuItem(value: i + 1, child: Text(_dias[i])),
              ],
              onChanged: (v) => setLocal(() => dia = v ?? dia),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () async {
                final t = await showTimePicker(
                  context: context,
                  initialTime: _parse(inicio),
                );
                if (t != null) setLocal(() => inicio = _fmt(t));
              },
              child: Text('Hora de inicio: $inicio'),
            ),
            OutlinedButton(
              onPressed: () async {
                final t = await showTimePicker(
                  context: context,
                  initialTime: _parse(fin),
                );
                if (t != null) setLocal(() => fin = _fmt(t));
              },
              child: Text('Hora de finalización: $fin'),
            ),
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    if (guardar != true) return;

    final ini = _minutos(inicio);
    final fi = _minutos(fin);

    if (fi <= ini) {
      _aviso('La hora de finalización debe ser mayor que la de inicio');
      return;
    }

    final cruza = _actuales.any((h) =>
        h.id != existente?.id &&
        h.dia == dia &&
        h.activo &&
        ini < _minutos(h.horaFin) &&
        _minutos(h.horaInicio) < fi);
    if (cruza) {
      _aviso('Ese horario se cruza con otro del mismo día');
      return;
    }

    try {
      if (existente == null) {
        await _repo.crear(Horario(
          id: '',
          barberoId: widget.barberoId,
          dia: dia,
          horaInicio: inicio,
          horaFin: fin,
        ));
      } else {
        await _repo.actualizar(existente.copyWith(
          dia: dia,
          horaInicio: inicio,
          horaFin: fin,
        ));
      }
      setState(_cargar);
    } catch (e) {
      _aviso('No se pudo guardar: $e');
    }
  }

  Future<void> _eliminar(Horario h) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar horario'),
        content: const Text('¿Seguro que quieres eliminar este horario?'),
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
    if (confirmar != true) return;

    try {
      await _repo.eliminar(h.id);
      setState(_cargar);
    } catch (e) {
      _aviso('No se pudo eliminar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final titulo = widget.barberoNombre.isEmpty
        ? 'Horarios'
        : 'Horarios - ${widget.barberoNombre}';

    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _formulario(),
        icon: const Icon(Icons.add),
        label: const Text('Agregar horario'),
      ),
      body: FutureBuilder<List<Horario>>(
        future: _futuro,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final horarios = snap.data ?? [];
          if (horarios.isEmpty) {
            return const Center(child: Text('No hay horarios registrados'));
          }
          return ListView.builder(
            itemCount: horarios.length,
            itemBuilder: (_, i) {
              final h = horarios[i];
              final nombreDia = _dias[(h.dia - 1).clamp(0, 6)];
              return ListTile(
                title: Text('$nombreDia: ${h.horaInicio} - ${h.horaFin}'),
                subtitle: Text(h.activo ? 'Activo' : 'Inactivo'),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _formulario(h),
                  ),
                  Switch(
                    value: h.activo,
                    onChanged: (v) async {
                      try {
                        await _repo.cambiarEstado(h.id, v);
                        setState(_cargar);
                      } catch (e) {
                        _aviso('No se pudo cambiar el estado: $e');
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _eliminar(h),
                  ),
                ]),
              );
            },
          );
        },
      ),
    );
  }
}
