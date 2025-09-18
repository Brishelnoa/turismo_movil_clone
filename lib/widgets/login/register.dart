import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {
    'nombres': TextEditingController(),
    'apellidos': TextEditingController(),
    'email': TextEditingController(),
    'password': TextEditingController(),
    'password_confirm': TextEditingController(),
    'telefono': TextEditingController(),
    'fecha_nacimiento': TextEditingController(),
    'documento_identidad': TextEditingController(),
    'pais': TextEditingController(text: 'BO'),
  };
  String? _genero; // 'M', 'F', 'O'
  DateTime? _fechaNacimiento;
  bool _isLoading = false;
  String? _errorMsg;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _isLoading = true; _errorMsg = null; });
    final data = {
      for (final k in _controllers.keys) k: _controllers[k]!.text.trim(),
      'genero': _genero ?? '',
      'fecha_nacimiento': _fechaNacimiento != null ? _fechaNacimiento!.toIso8601String().split('T')[0] : '',
    };
    final result = await AuthService.register(data);
    setState(() { _isLoading = false; });
    if (result['success']) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/Inicio');
    } else {
      setState(() { _errorMsg = result['error'].toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro de Usuario')),
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            margin: const EdgeInsets.all(24),
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _controllers['nombres'],
                      decoration: const InputDecoration(labelText: 'Nombres'),
                      validator: (v) => v == null || v.isEmpty ? 'Obligatorio' : null,
                    ),
                    TextFormField(
                      controller: _controllers['apellidos'],
                      decoration: const InputDecoration(labelText: 'Apellidos'),
                      validator: (v) => v == null || v.isEmpty ? 'Obligatorio' : null,
                    ),
                    TextFormField(
                      controller: _controllers['email'],
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Obligatorio';
                        final emailValid = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}").hasMatch(v);
                        return emailValid ? null : 'Email inválido';
                      },
                    ),
                    TextFormField(
                      controller: _controllers['telefono'],
                      decoration: const InputDecoration(labelText: 'Teléfono'),
                      validator: (v) => v == null || v.isEmpty ? 'Obligatorio' : null,
                    ),
                    GestureDetector(
                      onTap: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _fechaNacimiento ?? DateTime(now.year - 18),
                          firstDate: DateTime(1900),
                          lastDate: now,
                          helpText: 'Selecciona tu fecha de nacimiento',
                        );
                        if (picked != null) {
                          setState(() {
                            _fechaNacimiento = picked;
                            _controllers['fecha_nacimiento']!.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                          });
                        }
                      },
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: _controllers['fecha_nacimiento'],
                          decoration: const InputDecoration(
                            labelText: 'Fecha de nacimiento',
                            hintText: 'Selecciona tu fecha',
                            suffixIcon: Icon(Icons.calendar_today_rounded),
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Obligatorio' : null,
                        ),
                      ),
                    ),
                    DropdownButtonFormField<String>(
                      value: _genero,
                      decoration: const InputDecoration(labelText: 'Género'),
                      items: const [
                        DropdownMenuItem(value: 'M', child: Text('Masculino')),
                        DropdownMenuItem(value: 'F', child: Text('Femenino')),
                        DropdownMenuItem(value: 'O', child: Text('Otro')),
                      ],
                      onChanged: (v) => setState(() => _genero = v),
                      validator: (v) => v == null || v.isEmpty ? 'Obligatorio' : null,
                    ),
                    TextFormField(
                      controller: _controllers['documento_identidad'],
                      decoration: const InputDecoration(labelText: 'Documento de Identidad'),
                    ),
                    TextFormField(
                      controller: _controllers['pais'],
                      decoration: const InputDecoration(labelText: 'País'),
                    ),
                    TextFormField(
                      controller: _controllers['password'],
                      decoration: const InputDecoration(labelText: 'Contraseña'),
                      obscureText: true,
                      validator: (v) => v == null || v.length < 6 ? 'Mínimo 6 caracteres' : null,
                    ),
                    TextFormField(
                      controller: _controllers['password_confirm'],
                      decoration: const InputDecoration(labelText: 'Confirmar Contraseña'),
                      obscureText: true,
                      validator: (v) => v != _controllers['password']!.text ? 'No coincide' : null,
                    ),
                    const SizedBox(height: 16),
                    if (_errorMsg != null)
                      Text(_errorMsg!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        child: _isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Registrarse'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
