import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/barberia.dart';
import '../../domain/repositories/barberia_repository.dart';

class BarberiaRepositoryImpl implements BarberiaRepository {
  final FirebaseFirestore _firestore;

  BarberiaRepositoryImpl({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _barberiasCollection =>
      _firestore.collection('barberias');

  @override
  Future<List<Barberia>> obtenerBarberias() async {
    final snapshot = await _barberiasCollection.get();

    return snapshot.docs.map((doc) {
      final data = doc.data();

      return Barberia(
        id: doc.id,
        nombre: data['nombre'] ?? '',
        direccion: data['direccion'] ?? '',
        telefono: data['telefono'] ?? '',
        imagen: data['imagen'] ?? '',
        activa: data['activa'] ?? true,
      );
    }).toList();
  }

  @override
  Future<Barberia?> obtenerBarberiaPorId(String id) async {
    final doc = await _barberiasCollection.doc(id).get();

    if (!doc.exists) {
      return null;
    }

    final data = doc.data()!;

    return Barberia(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      direccion: data['direccion'] ?? '',
      telefono: data['telefono'] ?? '',
      imagen: data['imagen'] ?? '',
      activa: data['activa'] ?? true,
    );
  }

  @override
  Future<void> crearBarberia(Barberia barberia) async {
    await _barberiasCollection.doc(barberia.id).set({
      'nombre': barberia.nombre,
      'direccion': barberia.direccion,
      'telefono': barberia.telefono,
      'imagen': barberia.imagen,
      'activa': barberia.activa,
    });
  }

  @override
  Future<void> actualizarBarberia(Barberia barberia) async {
    await _barberiasCollection.doc(barberia.id).update({
      'nombre': barberia.nombre,
      'direccion': barberia.direccion,
      'telefono': barberia.telefono,
      'imagen': barberia.imagen,
      'activa': barberia.activa,
    });
  }

  @override
  Future<void> eliminarBarberia(String id) async {
    await _barberiasCollection.doc(id).delete();
  }
}