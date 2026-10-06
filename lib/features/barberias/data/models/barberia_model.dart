import '../../domain/entities/barberia.dart';

class BarberiaModel extends Barberia {
  const BarberiaModel({
    required super.id,
    required super.nombre,
    required super.direccion,
    required super.telefono,
    required super.imagen,
    required super.activa,
  });

  factory BarberiaModel.fromMap(Map<String, dynamic> map) {
    return BarberiaModel(
      id: map['id'] ?? '',
      nombre: map['nombre'] ?? '',
      direccion: map['direccion'] ?? '',
      telefono: map['telefono'] ?? '',
      imagen: map['imagen'] ?? '',
      activa: map['activa'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'direccion': direccion,
      'telefono': telefono,
      'imagen': imagen,
      'activa': activa,
    };
  }
}