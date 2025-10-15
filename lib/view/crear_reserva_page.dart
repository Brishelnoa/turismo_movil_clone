import 'package:flutter/material.dart';
import '../services/reservas_service.dart';
import '../services/auth_service.dart';
import 'crear_reserva/client_card.dart';
import 'crear_reserva/reserva_fields.dart';
import 'crear_reserva/visitante_form.dart';

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
  final TextEditingController _fechaController = TextEditingController();
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

  Map<String, String> _splitName(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return {'nombre': '', 'apellido': ''};
    if (parts.length == 1) return {'nombre': parts[0], 'apellido': ''};
    if (parts.length == 2) return {'nombre': parts[0], 'apellido': parts[1]};
    final nombre = '${parts[0]} ${parts[1]}';
    final apellido = parts.sublist(2).join(' ');
    return {'nombre': nombre, 'apellido': apellido};
  }

  @override
  void initState() {
    super.initState();
    if (widget.prefillTotal != null && widget.prefillTotal!.isNotEmpty) {
      _totalController.text = widget.prefillTotal!;
    }
    AuthService.getStoredUser().then((u) {
      if (u != null) {
        if (!mounted) return;
        setState(() {
          _storedUser = u;
          final fullName = (u['nombre'] ?? u['name'] ?? '').toString();
          if (fullName.isNotEmpty) {
            final names = _splitName(fullName);
            _visitanteNombre.text = names['nombre']!;
            _visitanteApellido.text = names['apellido']!;
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
    _fechaController.dispose();
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

  String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final now = DateTime.now();
    final initial = controller.text.isNotEmpty
        ? DateTime.tryParse(controller.text) ?? now
        : now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) controller.text = _formatDate(picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    if (_fechaController.text.isEmpty) {
      _fechaController.text = _formatDate(DateTime.now());
    }

    final Map<String, dynamic> reservaPayload = {
      'fecha': _fechaController.text,
      'fecha_inicio': _fechaInicioController.text,
      'fecha_fin': _fechaFinController.text,
      'estado': 'PENDIENTE',
      'total': _totalController.text,
      'moneda': _monedaController.text,
    };

    if (_storedUser != null) {
      final id =
          _storedUser!['id'] ?? _storedUser!['pk'] ?? _storedUser!['user_id'];
      if (id != null) reservaPayload['cliente_id'] = id;
    }

    if (widget.paqueteId != null) reservaPayload['paquete'] = widget.paqueteId;

    final visitante = {
      'nombre': _visitanteNombre.text,
      'apellido': _visitanteApellido.text,
      'email': _visitanteEmail.text,
      'fecha_nac': _visitanteFechaNac.text,
      'nacionalidad': _visitanteNacionalidad.text,
      'nro_doc': _visitanteNroDoc.text,
      'es_titular': true,
    };

    final result = await ReservasService.createReservaCompleta(
      reservaPayload: reservaPayload,
      visitantes: [visitante],
      pagoPayload: null,
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
              ClientCard(user: _storedUser),
              const SizedBox(height: 8),
              ReservaFields(
                fechaController: _fechaController,
                fechaInicioController: _fechaInicioController,
                fechaFinController: _fechaFinController,
                totalController: _totalController,
                monedaController: _monedaController,
                onPickDate: _pickDate,
              ),
              VisitanteForm(
                nombreController: _visitanteNombre,
                apellidoController: _visitanteApellido,
                fechaNacController: _visitanteFechaNac,
                nacionalidadController: _visitanteNacionalidad,
                nroDocController: _visitanteNroDoc,
                emailController: _visitanteEmail,
                soyVisitante: _soyVisitante,
                onSoyVisitanteChanged: (v) {
                  setState(() {
                    _soyVisitante = v ?? false;
                    if (_soyVisitante && _storedUser != null) {
                      final fullName =
                          (_storedUser!['nombre'] ?? _storedUser!['name'] ?? '')
                              .toString();
                      final names = _splitName(fullName);
                      _visitanteNombre.text = names['nombre']!;
                      _visitanteApellido.text = names['apellido']!;
                      if (_storedUser!['user'] is Map &&
                          (_storedUser!['user']['email'] ?? '')
                              .toString()
                              .isNotEmpty)
                        _visitanteEmail.text = _storedUser!['user']['email'];
                      if ((_storedUser!['fecha_nacimiento'] ??
                              _storedUser!['fechaNacimiento'] ??
                              '')
                          .toString()
                          .isNotEmpty)
                        _visitanteFechaNac.text =
                            (_storedUser!['fecha_nacimiento'] ??
                                    _storedUser!['fechaNacimiento'])
                                .toString();
                      if ((_storedUser!['documento_identidad'] ??
                              _storedUser!['documento'] ??
                              '')
                          .toString()
                          .isNotEmpty)
                        _visitanteNroDoc.text =
                            (_storedUser!['documento_identidad'] ??
                                    _storedUser!['documento'])
                                .toString();
                    } else if (!_soyVisitante) {
                      _visitanteNombre.clear();
                      _visitanteApellido.clear();
                      _visitanteEmail.clear();
                      _visitanteFechaNac.clear();
                      _visitanteNacionalidad.clear();
                      _visitanteNroDoc.clear();
                    }
                  });
                },
                onPickDate: _pickDate,
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
