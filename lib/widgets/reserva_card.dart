import 'package:flutter/material.dart';
import '../models/reserva.dart';

class ReservaCard extends StatelessWidget {
  final Reserva reserva;
  final VoidCallback? onVerDetalle;
  final VoidCallback? onCancelar;

  const ReservaCard(
      {Key? key, required this.reserva, this.onVerDetalle, this.onCancelar})
      : super(key: key);

  Color _colorPorEstado(String estado) {
    switch (estado.toUpperCase()) {
      case 'PENDIENTE':
        return Colors.orange.shade100;
      case 'CONFIRMADA':
        return Colors.lightBlue.shade100;
      case 'PAGADA':
        return Colors.green.shade100;
      case 'CANCELADA':
        return Colors.red.shade100;
      case 'COMPLETADA':
        return Colors.grey.shade300;
      case 'REPROGRAMADA':
        return Colors.blue.shade50;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Reserva #${reserva.id}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _colorPorEstado(reserva.estado),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(reserva.estado,
                      style: const TextStyle(fontSize: 12)),
                )
              ],
            ),
            const SizedBox(height: 8),
            Text('Fecha: ${reserva.fechaFormateada}'),
            Text('Total: ${reserva.total} ${reserva.moneda}'),
            if (reserva.cupon != null)
              Text(
                  'Descuento: ${reserva.cupon!['campania']?['descripcion'] ?? ''}'),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                    onPressed: onVerDetalle, child: const Text('Ver')),
                const SizedBox(width: 8),
                if (reserva.estado.toUpperCase() == 'CONFIRMADA')
                  OutlinedButton(
                      onPressed: onCancelar, child: const Text('Cancelar')),
              ],
            )
          ],
        ),
      ),
    );
  }
}
