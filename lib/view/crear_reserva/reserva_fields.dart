import 'package:flutter/material.dart';

class ReservaFields extends StatelessWidget {
  final TextEditingController fechaController;
  final TextEditingController fechaInicioController;
  final TextEditingController fechaFinController;
  final TextEditingController totalController;
  final TextEditingController monedaController;
  final Future<void> Function(TextEditingController) onPickDate;

  const ReservaFields({
    Key? key,
    required this.fechaController,
    required this.fechaInicioController,
    required this.fechaFinController,
    required this.totalController,
    required this.monedaController,
    required this.onPickDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
            controller: fechaController,
            decoration: const InputDecoration(labelText: 'Fecha (YYYY-MM-DD)'),
            readOnly: true,
            onTap: () => onPickDate(fechaController),
            validator: (v) => v == null || v.isEmpty ? 'Requerido' : null),
        TextFormField(
            controller: fechaInicioController,
            decoration: const InputDecoration(labelText: 'Fecha Inicio (ISO)'),
            validator: (v) => v == null || v.isEmpty ? 'Requerido' : null),
        TextFormField(
            controller: fechaFinController,
            decoration: const InputDecoration(labelText: 'Fecha Fin (ISO)'),
            validator: (v) => v == null || v.isEmpty ? 'Requerido' : null),
        TextFormField(
            controller: totalController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Total'),
            validator: (v) => v == null || v.isEmpty ? 'Requerido' : null),
        TextFormField(
            controller: monedaController,
            decoration: const InputDecoration(labelText: 'Moneda'),
            validator: (v) => v == null || v.isEmpty ? 'Requerido' : null),
      ],
    );
  }
}
