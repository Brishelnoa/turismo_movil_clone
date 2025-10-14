import 'package:flutter/material.dart';
import '../models/paquete.dart';

class PaqueteCard extends StatelessWidget {
  final Paquete paquete;
  final VoidCallback? onTap;

  const PaqueteCard({Key? key, required this.paquete, this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final serviciosText = paquete.serviciosIncluidos
        .map((s) {
          try {
            if (s.containsKey('titulo')) return s['titulo']?.toString() ?? '';
            if (s.containsKey('title')) return s['title']?.toString() ?? '';
          } catch (_) {}
          return s.toString();
        })
        .where((e) => e.toString().isNotEmpty)
        .join(', ');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 72,
          height: 72,
          color: Colors.grey.shade200,
          child:
              const Icon(Icons.card_travel, size: 36, color: Colors.blueGrey),
        ),
        title: Text(paquete.nombre,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text('${paquete.duracion} • ${paquete.displayPrice}'),
            const SizedBox(height: 6),
            if (paquete.descripcion.isNotEmpty)
              Text(paquete.descripcion,
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Text('Incluye: $serviciosText',
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
        trailing: const Icon(Icons.keyboard_arrow_right),
      ),
    );
  }
}
