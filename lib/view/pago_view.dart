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
    final url = await PagoService.iniciarPago(widget.monto, widget.reservaId);
    setState(() => _isLoading = false);

    if (url != null && await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo iniciar el pago')),
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
