import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'crear_reserva/client_card.dart';
import 'crear_reserva/visitante_form.dart';
import 'package:url_launcher/url_launcher.dart';
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

  /// 🔹 Crear sesión de pago con Stripe y abrir ventana de checkout
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    // const baseUrl = "https://backendspring2-production.up.railway.app";

    final clienteId = _storedUser?['id'];
    if (clienteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontró el usuario logueado.')),
      );
      setState(() => _loading = false);
      return;
    }

    final double totalDouble =
        double.tryParse(_totalController.text.trim()) ?? 480.0;
    final int precioCentavos = (totalDouble * 100).round();

    if (precioCentavos < 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'El monto debe ser al menos de Bs. 5.00 (aproximadamente 0.50 USD).')),
      );
      setState(() => _loading = false);
      return;
    }

    try {
      // Usar la baseUrl central definida en auth_service (resuelve dotenv / --dart-define / default)
      // Nota: auth_service carga la variable `baseUrl` desde dotenv si existe.
      final base = baseUrl;

      final response = await http.post(
        Uri.parse('$base/api/crear-checkout-session/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'precio': precioCentavos, // 💰 En centavos
        }),
      );

      setState(() => _loading = false);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // ✅ Soporta tanto "checkout_url" como "url"
        final urlPago = data['checkout_url'] ?? data['url'];

        if (urlPago == null || urlPago.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se recibió URL de Stripe')),
          );
          return;
        }

        final uri = Uri.tryParse(urlPago);

        if (uri == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('URL de Stripe inválida')),
          );
          return;
        }

        try {
          // 🔹 1) intenta con navegador externo (Chrome, etc.)
          final launched =
              await launchUrl(uri, mode: LaunchMode.externalApplication);

          if (!launched) {
            // 🔹 2) si no hay navegador, abre en vista interna (WebView)
            await launchUrl(
              uri,
              mode: LaunchMode.inAppWebView,
              webViewConfiguration: const WebViewConfiguration(
                enableJavaScript: true,
                enableDomStorage: true,
              ),
            );
          }
        } catch (e) {
          // 🔹 3) fallback final: mostrar mensaje de error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al abrir Stripe: $e')),
          );
        }
      } else {
        final msg = jsonDecode(response.body)['error'] ??
            'Error al crear la sesión de Stripe';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      setState(() => _loading = false);
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
