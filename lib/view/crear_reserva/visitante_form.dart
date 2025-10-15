import 'package:flutter/material.dart';

class VisitanteForm extends StatelessWidget {
  final TextEditingController nombreController;
  final TextEditingController apellidoController;
  final TextEditingController fechaNacController;
  final TextEditingController nacionalidadController;
  final TextEditingController nroDocController;
  final TextEditingController emailController;
  final bool soyVisitante;
  final ValueChanged<bool?> onSoyVisitanteChanged;
  final Future<void> Function(TextEditingController) onPickDate;

  const VisitanteForm({
    Key? key,
    required this.nombreController,
    required this.apellidoController,
    required this.fechaNacController,
    required this.nacionalidadController,
    required this.nroDocController,
    required this.emailController,
    required this.soyVisitante,
    required this.onSoyVisitanteChanged,
    required this.onPickDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Visitante titular',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Row(children: [
            const Text('Soy el visitante'),
            Checkbox(value: soyVisitante, onChanged: onSoyVisitanteChanged)
          ])
        ]),
        TextFormField(
            controller: nombreController,
            decoration: const InputDecoration(labelText: 'Nombre'),
            validator: (v) => v == null || v.isEmpty ? 'Requerido' : null),
        TextFormField(
            controller: apellidoController,
            decoration: const InputDecoration(labelText: 'Apellido'),
            validator: (v) => v == null || v.isEmpty ? 'Requerido' : null),
        TextFormField(
            controller: fechaNacController,
            decoration: const InputDecoration(
                labelText: 'Fecha Nacimiento (YYYY-MM-DD)'),
            readOnly: true,
            onTap: () => onPickDate(fechaNacController),
            validator: (v) => v == null || v.isEmpty ? 'Requerido' : null),
        TextFormField(
            controller: nacionalidadController,
            decoration: const InputDecoration(labelText: 'Nacionalidad'),
            validator: (v) => v == null || v.isEmpty ? 'Requerido' : null),
        TextFormField(
            controller: nroDocController,
            decoration: const InputDecoration(labelText: 'Número de Documento'),
            validator: (v) => v == null || v.isEmpty ? 'Requerido' : null),
        TextFormField(
            controller: emailController,
            decoration: const InputDecoration(labelText: 'Email'),
            validator: (v) => v == null || v.isEmpty ? 'Requerido' : null),
      ],
    );
  }
}
