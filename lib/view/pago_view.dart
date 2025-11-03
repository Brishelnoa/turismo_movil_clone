import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/pago_service.dart';

class PagoView extends StatefulWidget {
  final double monto;
  final int reservaId;

  const PagoView({super.key, required this.monto, required this.reservaId});

  @override
  State<PagoView> createState() => _PagoViewState();
}

class _PagoViewState extends State<PagoView> {
  bool _isLoading = false;

  Future<void> _iniciarPago() async {
    setState(() => _isLoading = true);

    try {
      final url = await PagoService.iniciarPago(widget.monto, widget.reservaId);
      setState(() => _isLoading = false);

      if (url == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al crear la sesión de pago. Por favor intenta nuevamente.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        
        if (!launched) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo abrir el navegador para el pago'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('URL inválida: $url'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error inesperado: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Procesar Pago'),
        backgroundColor: Colors.orangeAccent,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.credit_card,
                  color: Colors.orangeAccent.shade200, size: 90),
              const SizedBox(height: 25),
              Text(
                'Monto a pagar:',
                style: TextStyle(fontSize: 22, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 10),
              Text(
                'Bs. ${widget.monto.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.orangeAccent),
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const CircularProgressIndicator(color: Colors.orangeAccent)
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.payment),
                      label: const Text('Pagar con Stripe'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 15),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                      onPressed: _iniciarPago,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
