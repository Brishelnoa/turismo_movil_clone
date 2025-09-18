import 'package:flutter/material.dart';
import '../../models/viaje.dart';

class TarjetaViaje extends StatelessWidget {
  const TarjetaViaje({super.key, required this.viaje});

  final Viaje viaje;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            // Imagen
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: Image.network(
                  viaje.imagenUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Título y calificación
            Row(
              children: [
                Expanded(
                  child: Text(
                    viaje.titulo,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    const SizedBox(width: 2),
                    Text(
                      '${viaje.calificacion}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 6),

            // Ubicación
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 18, color: Colors.black54),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    viaje.ubicacion,
                    style: const TextStyle(color: Colors.black54),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Servicios
            _FilaServicios(servicios: viaje.servicios),

            const SizedBox(height: 10),

            // Precio
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '\$${viaje.precioUsd}',
                  style: const TextStyle(
                    color: Color(0xFFFF6A00),
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(width: 4),
                const Text('por persona',
                    style: TextStyle(color: Colors.black45)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaServicios extends StatelessWidget {
  const _FilaServicios({required this.servicios});

  final List<String> servicios;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: servicios.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F1F1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            servicios[i],
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
