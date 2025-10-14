import 'package:flutter/material.dart';
import '../services/reservas_service.dart';

class CrearReservaPage extends StatefulWidget {
  final int? paqueteId;
  final String? paqueteNombre;
  final String? prefillTotal;

  const CrearReservaPage(
      {Key? key, this.paqueteId, this.paqueteNombre, this.prefillTotal})
      : super(key: key);

  @override
  State<CrearReservaPage> createState() => _CrearReservaPageState();
}

class _CrearReservaPageState extends State<CrearReservaPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fechaController = TextEditingController();
  final TextEditingController _fechaInicioController = TextEditingController();
  final TextEditingController _fechaFinController = TextEditingController();
  final TextEditingController _totalController = TextEditingController();
  final TextEditingController _monedaController =
      TextEditingController(text: 'BOB');

  final TextEditingController _visitanteNombre = TextEditingController();
  final TextEditingController _visitanteEmail = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _fechaController.dispose();
    _fechaInicioController.dispose();
    _fechaFinController.dispose();
    _totalController.dispose();
    _monedaController.dispose();
    _visitanteNombre.dispose();
    _visitanteEmail.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // si venimos de paquete, prefill total
    if (widget.prefillTotal != null && widget.prefillTotal!.isNotEmpty) {
      _totalController.text = widget.prefillTotal!;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final Map<String, dynamic> reservaPayload = {
      'fecha': _fechaController.text,
      'fecha_inicio': _fechaInicioController.text,
      'fecha_fin': _fechaFinController.text,
      'estado': 'PENDIENTE',
      'total': _totalController.text,
      'moneda': _monedaController.text,
      // 'cliente' será inferido por el backend si usas /reservas/ autenticado
    };

    // si venimos de un paquete, incluirlo en el payload
    if (widget.paqueteId != null) {
      reservaPayload['paquete'] =
          widget.paqueteId; // int allowed because reservaPayload is dynamic
    }

    final visitante = {
      'nombre': _visitanteNombre.text,
      'email': _visitanteEmail.text,
      'es_titular': true,
    };

    final pagoPayload = null; // en este ejemplo no procesamos pago real

    final result = await ReservasService.createReservaCompleta(
      reservaPayload: reservaPayload,
      visitantes: [visitante],
      pagoPayload: pagoPayload,
      paqueteId: widget.paqueteId,
    );

    setState(() => _loading = false);

    if (result['success'] == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reserva creada correctamente')));
      Navigator.of(context).pop();
    } else {
      if (!mounted) return;
      final msg = result['error'] ?? 'Error desconocido';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Reserva')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _fechaController,
                decoration:
                    const InputDecoration(labelText: 'Fecha (YYYY-MM-DD)'),
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              TextFormField(
                controller: _fechaInicioController,
                decoration:
                    const InputDecoration(labelText: 'Fecha Inicio (ISO)'),
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              TextFormField(
                controller: _fechaFinController,
                decoration: const InputDecoration(labelText: 'Fecha Fin (ISO)'),
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              TextFormField(
                controller: _totalController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Total'),
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              TextFormField(
                controller: _monedaController,
                decoration: const InputDecoration(labelText: 'Moneda'),
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              const Text('Visitante titular',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _visitanteNombre,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              TextFormField(
                controller: _visitanteEmail,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 20),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submit, child: const Text('Crear reserva')),
            ],
          ),
        ),
      ),
    );
  }
}
