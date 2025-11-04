import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/pago_service.dart';
import '../services/deep_link_service.dart';
import 'crear_reserva/client_card.dart';
import 'crear_reserva/visitante_form.dart';
import 'payment_result_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CrearReservaPage extends StatefulWidget {
  final int? paqueteId;
  final String? paqueteNombre;
  final String? prefillTotal;

  const CrearReservaPage({
    Key? key,
    this.paqueteId,
    this.paqueteNombre,
    this.prefillTotal,
  }) : super(key: key);

  @override
  State<CrearReservaPage> createState() => _CrearReservaPageState();
}

class _CrearReservaPageState extends State<CrearReservaPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fechaInicioController = TextEditingController();
  final TextEditingController _fechaFinController = TextEditingController();
  final TextEditingController _totalController = TextEditingController();
  final TextEditingController _monedaController =
      TextEditingController(text: 'BOB');

  final TextEditingController _visitanteNombre = TextEditingController();
  final TextEditingController _visitanteEmail = TextEditingController();
  final TextEditingController _visitanteApellido = TextEditingController();
  final TextEditingController _visitanteFechaNac = TextEditingController();
  final TextEditingController _visitanteNacionalidad = TextEditingController();
  final TextEditingController _visitanteNroDoc = TextEditingController();

  bool _loading = false;
  Map<String, dynamic>? _storedUser;
  bool _soyVisitante = false;

  @override
  void initState() {
    super.initState();
    if (widget.prefillTotal != null && widget.prefillTotal!.isNotEmpty) {
      _totalController.text = widget.prefillTotal!;
    }
    AuthService.getStoredUser().then((u) {
      if (u != null && mounted) {
        setState(() {
          _storedUser = u;
          final fullName = (u['nombre'] ?? u['name'] ?? '').toString();
          if (fullName.isNotEmpty) {
            final parts = fullName.trim().split(RegExp(r'\s+'));
            _visitanteNombre.text = parts.first;
            _visitanteApellido.text =
                parts.length > 1 ? parts.sublist(1).join(' ') : '';
          }
          if (u['user'] is Map &&
              (u['user']['email'] ?? '').toString().isNotEmpty) {
            _visitanteEmail.text = u['user']['email'];
          }
          if ((u['fecha_nacimiento'] ?? u['fechaNacimiento'] ?? '')
              .toString()
              .isNotEmpty) {
            _visitanteFechaNac.text =
                (u['fecha_nacimiento'] ?? u['fechaNacimiento']).toString();
          }
          if ((u['documento_identidad'] ?? u['documento'] ?? '')
              .toString()
              .isNotEmpty) {
            _visitanteNroDoc.text =
                (u['documento_identidad'] ?? u['documento']).toString();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _fechaInicioController.dispose();
    _fechaFinController.dispose();
    _totalController.dispose();
    _monedaController.dispose();
    _visitanteNombre.dispose();
    _visitanteEmail.dispose();
    _visitanteApellido.dispose();
    _visitanteFechaNac.dispose();
    _visitanteNacionalidad.dispose();
    _visitanteNroDoc.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate(TextEditingController controller) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.teal,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) controller.text = _formatDate(picked);
  }

  /// 🔹 Crear reserva completa en el backend y abrir checkout de Stripe en navegador externo
  /// con deep links para regresar automáticamente a la app
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      debugPrint('[CrearReserva] ❌ Validación de formulario falló');
      return;
    }

    debugPrint('[CrearReserva] ✅ Iniciando proceso de reserva y pago...');
    setState(() => _loading = true);

    final clienteId = _storedUser?['id'];
    if (clienteId == null) {
      debugPrint(
          '[CrearReserva] ❌ No se encontró ID del cliente en _storedUser');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontró el usuario logueado.')),
      );
      setState(() => _loading = false);
      return;
    }
    debugPrint('[CrearReserva] 👤 Cliente ID: $clienteId');

    final double totalDouble =
        double.tryParse(_totalController.text.trim()) ?? 480.0;
    debugPrint('[CrearReserva] 💰 Total: Bs. $totalDouble');

    if (totalDouble < 0.50) {
      debugPrint('[CrearReserva] ❌ Monto demasiado bajo: Bs. $totalDouble');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El monto debe ser al menos de Bs. 0.50')),
      );
      setState(() => _loading = false);
      return;
    }

    try {
      // Importamos baseUrl directamente desde auth_service
      const base = 'https://backendspring2-production.up.railway.app';
      debugPrint('[CrearReserva] 🌐 Base URL: $base');

      // 🔹 Paso 1: Crear la reserva completa con visitante incluido
      debugPrint('[CrearReserva] 📝 PASO 1: Creando reserva en backend...');
      debugPrint('[CrearReserva] - Paquete ID: ${widget.paqueteId}');
      debugPrint(
          '[CrearReserva] - Fecha inicio: ${_fechaInicioController.text}');
      debugPrint('[CrearReserva] - Fecha fin: ${_fechaFinController.text}');
      debugPrint(
          '[CrearReserva] - Visitante: ${_visitanteNombre.text} ${_visitanteApellido.text}');

      final reservaResponse = await http.post(
        Uri.parse('$base/api/reservas/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token ${await AuthService.getAccessToken()}',
        },
        body: jsonEncode({
          'fecha': _fechaInicioController.text.trim(), // Backend espera 'fecha'
          'fecha_inicio': _fechaInicioController.text.trim(),
          'fecha_fin': _fechaFinController.text.trim(),
          'total': totalDouble,
          'moneda': _monedaController.text.trim(),
          'paquete': widget.paqueteId,
          'cliente_id': clienteId, // Backend espera 'cliente_id' no 'cliente'
          'estado': 'pendiente', // Estado inicial
          'visitante': {
            'nombre': _visitanteNombre.text.trim(),
            'apellido': _visitanteApellido.text.trim(),
            'fecha_nacimiento': _visitanteFechaNac.text.trim(),
            'nacionalidad': _visitanteNacionalidad.text.trim(),
            'nro_documento': _visitanteNroDoc.text.trim(),
            'email': _visitanteEmail.text.trim(),
          }
        }),
      );

      debugPrint(
          '[CrearReserva] 📡 Respuesta reserva - Status: ${reservaResponse.statusCode}');
      debugPrint(
          '[CrearReserva] 📡 Respuesta reserva - Body: ${reservaResponse.body}');

      if (reservaResponse.statusCode != 200 &&
          reservaResponse.statusCode != 201) {
        debugPrint('[CrearReserva] ❌ Error al crear reserva');
        final errorMsg = jsonDecode(reservaResponse.body)['detail'] ??
            jsonDecode(reservaResponse.body)['error'] ??
            'Error al crear la reserva';
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorMsg)));
        setState(() => _loading = false);
        return;
      }

      final reservaData = jsonDecode(reservaResponse.body);
      final reservaId = reservaData['id'];
      debugPrint(
          '[CrearReserva] ✅ Reserva creada exitosamente - ID: $reservaId');

      // 🔹 Paso 2: Crear sesión de Stripe usando el nuevo endpoint móvil
      debugPrint('[CrearReserva] 💳 PASO 2: Creando sesión móvil de Stripe...');

      final checkoutResult = await PagoService.crearCheckoutMobile(
        reservaId: reservaId,
        nombre:
            '${widget.paqueteNombre ?? "Reserva"} - ${_visitanteNombre.text} ${_visitanteApellido.text}',
        precio: totalDouble,
        cantidad: 1,
        moneda: 'BOB',
      );

      setState(() => _loading = false);

      if (!checkoutResult['success']) {
        debugPrint('[CrearReserva] ❌ Error al crear sesión móvil de Stripe');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  checkoutResult['error'] ?? 'Error al crear sesión de pago')),
        );
        return;
      }

      final checkoutUrl = checkoutResult['checkout_url'];
      debugPrint('[CrearReserva] ✅ Sesión móvil Stripe creada');
      debugPrint('[CrearReserva] - Checkout URL: $checkoutUrl');
      debugPrint(
          '[CrearReserva] - Session ID: ${checkoutResult['session_id']}');

      // 🔹 Paso 3: Configurar deep link listener ANTES de abrir el navegador
      debugPrint(
          '[CrearReserva] 🔗 PASO 3: Configurando deep link listener...');

      // Inicializar el servicio con callbacks
      await DeepLinkService.init(
        onPaymentSuccess: (Uri uri) async {
          final sessionId = uri.queryParameters['session_id'];
          final reservaIdStr = uri.queryParameters['reserva_id'];
          final status = uri.queryParameters['status'];
          final monto = uri.queryParameters['monto'];

          debugPrint('[CrearReserva] ✅ Deep link SUCCESS recibido');
          debugPrint('[CrearReserva] - Session ID: $sessionId');
          debugPrint('[CrearReserva] - Reserva ID: $reservaIdStr');
          debugPrint('[CrearReserva] - Monto: $monto');

          // Verificar estado de la reserva en el backend
          if (reservaIdStr != null) {
            final reservaIdInt = int.tryParse(reservaIdStr);
            if (reservaIdInt != null) {
              final estado =
                  await PagoService.verificarEstadoReserva(reservaIdInt);
              debugPrint('[CrearReserva] - Estado verificado: $estado');
            }
          }

          if (!mounted) return;

          // Navegar a pantalla de éxito
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => PaymentResultScreen(
                success: true,
                sessionId: sessionId,
                reservaId:
                    reservaIdStr != null ? int.tryParse(reservaIdStr) : null,
                status: status,
                monto: monto,
              ),
            ),
          );
        },
        onPaymentCancel: (Uri uri) {
          final sessionId = uri.queryParameters['session_id'];
          final reservaIdStr = uri.queryParameters['reserva_id'];
          final status = uri.queryParameters['status'];

          debugPrint('[CrearReserva] ⚠️ Deep link CANCEL recibido');
          debugPrint('[CrearReserva] - Session ID: $sessionId');
          debugPrint('[CrearReserva] - Reserva ID: $reservaIdStr');

          if (!mounted) return;

          // Navegar a pantalla de cancelación
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => PaymentResultScreen(
                success: false,
                sessionId: sessionId,
                reservaId:
                    reservaIdStr != null ? int.tryParse(reservaIdStr) : null,
                status: status,
                errorMessage: 'Pago cancelado. Puedes intentarlo nuevamente.',
              ),
            ),
          );
        },
        onPaymentError: (Uri uri) {
          final sessionId = uri.queryParameters['session_id'];
          final reservaIdStr = uri.queryParameters['reserva_id'];
          final status = uri.queryParameters['status'];
          final error = uri.queryParameters['error'];

          debugPrint('[CrearReserva] ❌ Deep link ERROR recibido');
          debugPrint('[CrearReserva] - Session ID: $sessionId');
          debugPrint('[CrearReserva] - Error: $error');

          if (!mounted) return;

          // Navegar a pantalla de error
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => PaymentResultScreen(
                success: false,
                sessionId: sessionId,
                reservaId:
                    reservaIdStr != null ? int.tryParse(reservaIdStr) : null,
                status: status,
                errorMessage: error ?? 'Ocurrió un error durante el pago.',
              ),
            ),
          );
        },
        onPaymentPending: (Uri uri) {
          final sessionId = uri.queryParameters['session_id'];
          final reservaIdStr = uri.queryParameters['reserva_id'];

          debugPrint('[CrearReserva] ⏳ Deep link PENDING recibido');
          debugPrint('[CrearReserva] - Session ID: $sessionId');
          debugPrint('[CrearReserva] - Reserva ID: $reservaIdStr');

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Pago pendiente. Te notificaremos cuando se confirme.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
        },
      );

      // 🔹 Paso 4: Abrir Stripe en navegador externo
      debugPrint(
          '[CrearReserva] 🌐 PASO 4: Abriendo Stripe en navegador externo...');
      debugPrint(
          '[CrearReserva] - El backend redirigirá a: turismoapp://payment-success o payment-cancel');

      final launched = await PagoService.abrirCheckoutEnNavegador(checkoutUrl);

      if (!launched) {
        debugPrint('[CrearReserva] ❌ No se pudo abrir el navegador');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No se pudo abrir el navegador de pago')),
        );
        DeepLinkService.dispose();
        return;
      }

      debugPrint(
          '[CrearReserva] ✅ Navegador abierto. Esperando deep link de retorno...');

      // El usuario está ahora en el navegador
      // El deep link service escuchará cuando regrese
      // Los callbacks manejarán el resultado
    } catch (e) {
      debugPrint('[CrearReserva] ❌❌❌ EXCEPCIÓN CAPTURADA: $e');
      debugPrint('[CrearReserva] Stack trace:');
      debugPrint(e.toString());

      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.teal,
        elevation: 2,
        title: const Text('Crear Reserva',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (widget.paqueteNombre != null)
                        Card(
                          elevation: 3,
                          color: Colors.teal[50],
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: const Icon(Icons.card_travel,
                                color: Colors.teal),
                            title: Text(widget.paqueteNombre!,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              'Precio: ${widget.prefillTotal ?? '-'} BOB',
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      _SectionTitle(
                          icon: Icons.person_outline,
                          title: 'Datos del Cliente'),
                      ClientCard(user: _storedUser),
                      const SizedBox(height: 16),
                      _SectionTitle(
                          icon: Icons.calendar_month,
                          title: 'Datos de la Reserva'),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              _DateField(
                                controller: _fechaInicioController,
                                label: 'Fecha Inicio',
                                onPickDate: () =>
                                    _pickDate(_fechaInicioController),
                              ),
                              const SizedBox(height: 8),
                              _DateField(
                                controller: _fechaFinController,
                                label: 'Fecha Fin',
                                onPickDate: () =>
                                    _pickDate(_fechaFinController),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _totalController,
                                decoration: InputDecoration(
                                  labelText: 'Total',
                                  prefixIcon: const Icon(Icons.attach_money),
                                  filled: true,
                                  fillColor: Colors.grey[200],
                                ),
                                enabled: false,
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _monedaController,
                                decoration: InputDecoration(
                                  labelText: 'Moneda',
                                  prefixIcon: const Icon(Icons.monetization_on),
                                  filled: true,
                                  fillColor: Colors.grey[200],
                                ),
                                enabled: false,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SectionTitle(
                          icon: Icons.group, title: 'Datos del Visitante'),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: VisitanteForm(
                            nombreController: _visitanteNombre,
                            apellidoController: _visitanteApellido,
                            fechaNacController: _visitanteFechaNac,
                            nacionalidadController: _visitanteNacionalidad,
                            nroDocController: _visitanteNroDoc,
                            emailController: _visitanteEmail,
                            soyVisitante: _soyVisitante,
                            onSoyVisitanteChanged: (v) =>
                                setState(() => _soyVisitante = v ?? false),
                            onPickDate: _pickDate,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 30),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _submit,
                        icon: const Icon(Icons.payment_outlined),
                        label: const Text('Ir al Pago con Stripe',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final VoidCallback onPickDate;
  const _DateField({
    required this.controller,
    required this.label,
    required this.onPickDate,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.date_range),
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_today, color: Colors.teal),
          onPressed: onPickDate,
        ),
      ),
      validator: (v) => v == null || v.isEmpty ? 'Seleccione una fecha' : null,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.teal),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black87),
        ),
      ],
    );
  }
}
