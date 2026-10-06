import '../entities/barberia.dart';

abstract class BarberiaRepository {
  Future<List<Barberia>> obtenerBarberias();

  Future<Barberia?> obtenerBarberiaPorId(String id);

  Future<void> crearBarberia(Barberia barberia);

  Future<void> actualizarBarberia(Barberia barberia);

  Future<void> eliminarBarberia(String id);
}