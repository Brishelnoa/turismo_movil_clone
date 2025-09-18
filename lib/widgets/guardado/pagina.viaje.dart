import 'package:flutter/material.dart';
import '../../models/viaje.dart';
import 'selector_viaje.dart';
import 'tarjeta_viaje.dart';

class PaginaViajes extends StatefulWidget {
  const PaginaViajes({super.key});

  @override
  State<PaginaViajes> createState() => _PaginaViajesEstado();
}

class _PaginaViajesEstado extends State<PaginaViajes> {
  int _indiceTab = 0; // 0 = Pendientes, 1 = Pasados

  @override
  Widget build(BuildContext context) {
    final viajesFiltrados = viajesDemo.where((v) {
      return _indiceTab == 0
          ? v.estado == EstadoViaje.pendiente
          : v.estado == EstadoViaje.pasado;
    }).toList();

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectorViajes(
              indiceActual: _indiceTab,
              alCambiar: (i) => setState(() => _indiceTab = i),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: viajesFiltrados.length,
              itemBuilder: (_, i) => TarjetaViaje(viaje: viajesFiltrados[i]),
            ),
          ],
        ),
      ),
    );
  }
}
