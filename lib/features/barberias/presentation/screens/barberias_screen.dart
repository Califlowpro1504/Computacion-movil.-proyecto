import 'package:flutter/material.dart';

class BarberiasScreen extends StatelessWidget {
  const BarberiasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barberías'),
      ),
      body: const Center(
        child: Text('Módulo de barberías'),
      ),
    );
  }
}
