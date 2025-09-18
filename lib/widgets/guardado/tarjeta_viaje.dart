import 'package:flutter/material.dart';
import '../../models/viaje.dart';

class TarjetaViaje extends StatelessWidget {
  const TarjetaViaje({super.key, required this.viaje});

  final Viaje viaje;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _miniatura(viaje.imagenUrl),
          const SizedBox(width: 10),
          Expanded(child: _info(context)),
        ],
      ),
    );
  }

  Widget _miniatura(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        width: 72,
        height: 72,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _info(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          viaje.titulo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            const Icon(Icons.location_on_outlined, size: 16, color: Colors.black45),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                viaje.ubicacion,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.black54),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 16),
            const SizedBox(width: 4),
            Text(
              '${viaje.calificacion}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '\$${viaje.precioUsd}',
                    style: const TextStyle(
                      color: Color(0xFFFF6A00),
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const TextSpan(
                    text: ' por persona',
                    style: TextStyle(color: Colors.black45),
                  ),
                ],
                style: DefaultTextStyle.of(context).style,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
