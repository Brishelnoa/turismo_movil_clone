import 'package:flutter/material.dart';

class ClientCard extends StatelessWidget {
  final Map<String, dynamic>? user;

  const ClientCard({Key? key, this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (user == null) return const SizedBox.shrink();
    final nombre = user?['nombre'] ?? user?['name'] ?? '—';
    final telefono = (user?['telefono'] ?? '').toString();
    final documento = (user?['documento_identidad'] ?? '').toString();
    final email = (user?['user'] is Map) ? (user!['user']['email'] ?? '') : '';

    return Card(
      color: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cliente (logueado)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(nombre.toString()),
            const SizedBox(height: 4),
            if (telefono.isNotEmpty) Text('Tel: $telefono'),
            if (documento.isNotEmpty) Text('Documento: $documento'),
            if (email != null && email.toString().isNotEmpty)
              Text('Email: ${email.toString()}'),
          ],
        ),
      ),
    );
  }
}
