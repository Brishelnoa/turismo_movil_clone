import 'package:flutter/material.dart';

/// Pantalla de resultado del pago
/// Se muestra cuando el usuario regresa de Stripe
class PaymentResultScreen extends StatelessWidget {
  final bool success;
  final String? sessionId;
  final int? reservaId;
  final String? status;
  final String? monto;
  final String? errorMessage;

  const PaymentResultScreen({
    Key? key,
    required this.success,
    this.sessionId,
    this.reservaId,
    this.status,
    this.monto,
    this.errorMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: success ? Colors.green[50] : Colors.red[50],
      appBar: AppBar(
        backgroundColor: success ? Colors.green : Colors.red,
        title: Text(success ? 'Pago Exitoso' : 'Pago No Completado'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono
              Icon(
                success ? Icons.check_circle : Icons.error,
                size: 120,
                color: success ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 32),

              // Título
              Text(
                success ? '¡Pago Exitoso!' : 'Pago No Completado',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: success ? Colors.green[800] : Colors.red[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Mensaje
              Text(
                success
                    ? 'Tu reserva ha sido confirmada y el pago procesado correctamente.'
                    : errorMessage ?? 'El pago no pudo ser completado.',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Información de la transacción
              if (reservaId != null) ...[
                _InfoCard(
                  icon: Icons.receipt_long,
                  title: 'Reserva ID',
                  value: '#$reservaId',
                ),
                const SizedBox(height: 12),
              ],

              if (monto != null) ...[
                _InfoCard(
                  icon: Icons.attach_money,
                  title: 'Monto',
                  value: 'Bs. $monto',
                ),
                const SizedBox(height: 12),
              ],

              if (sessionId != null) ...[
                _InfoCard(
                  icon: Icons.fingerprint,
                  title: 'Session ID',
                  value: sessionId!,
                  small: true,
                ),
                const SizedBox(height: 12),
              ],

              if (status != null) ...[
                _InfoCard(
                  icon: Icons.info,
                  title: 'Estado',
                  value: status!,
                ),
                const SizedBox(height: 24),
              ],

              // Botones de acción
              if (success) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/MisReservas',
                      (route) => route.isFirst,
                    );
                  },
                  icon: const Icon(Icons.list_alt),
                  label: const Text('Ver Mis Reservas'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/Inicio',
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('Ir al Inicio'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.green),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                  ),
                ),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar Pago'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/Inicio',
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('Volver al Inicio'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool small;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[700]),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: small ? 11 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: small ? TextOverflow.ellipsis : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
