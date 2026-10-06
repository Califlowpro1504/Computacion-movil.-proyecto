import '../../domain/entities/barberia.dart';
import '../../domain/repositories/barberia_repository.dart';

class BarberiaRepositoryImpl implements BarberiaRepository {
  final List<Barberia> _barberias = [];

  @override
  Future<List<Barberia>> obtenerBarberias() async {
    return List.unmodifiable(_barberias);
  }

  @override
  Future<Barberia?> obtenerBarberiaPorId(String id) async {
    for (final barberia in _barberias) {
      if (barberia.id == id) {
        return barberia;
      }
    }

    return null;
  }

  @override
  Future<void> crearBarberia(Barberia barberia) async {
    _barberias.add(barberia);
  }

  @override
  Future<void> actualizarBarberia(Barberia barberia) async {
    final index = _barberias.indexWhere(
      (elemento) => elemento.id == barberia.id,
    );

    if (index != -1) {
      _barberias[index] = barberia;
    }
  }

  @override
  Future<void> eliminarBarberia(String id) async {
    _barberias.removeWhere(
      (barberia) => barberia.id == id,
    );
  }
}
final List<Barberia> _barberias = [];