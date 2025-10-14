import 'package:flutter/material.dart';
import '../services/paquetes_service.dart';
import '../models/paquete.dart';
import 'crear_reserva_page.dart';

class PaqueteDetailPage extends StatefulWidget {
  const PaqueteDetailPage({Key? key, required this.paqueteId})
      : super(key: key);
  final int paqueteId;

  @override
  State<PaqueteDetailPage> createState() => _PaqueteDetailPageState();
}

class _PaqueteDetailPageState extends State<PaqueteDetailPage> {
  Paquete? paquete;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final resp = await PaquetesService.getPaquete(widget.paqueteId);
    if (resp.containsKey('error')) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(resp['error'].toString())));
    } else {
      paquete = Paquete.fromJson(resp.cast<String, dynamic>());
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle Paquete')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : paquete == null
              ? const Center(child: Text('No se encontró el paquete'))
              : Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ListView(
                    children: [
                      Text(paquete!.nombre,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (paquete!.descripcion.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(paquete!.descripcion),
                      ],
                      const SizedBox(height: 8),
                      Text('Duración: ${paquete!.duracion}'),
                      const SizedBox(height: 8),
                      Text('Precio: ${paquete!.displayPrice}'),
                      const SizedBox(height: 12),
                      const Text('Itinerario:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      ...paquete!.itinerario.map((d) {
                        // d may be a map with 'dia' and 'actividades' (list)
                        final day = d as Map<String, dynamic>? ?? {};
                        final dia = day['dia']?.toString() ??
                            day['day']?.toString() ??
                            '';
                        String activities = '';
                        try {
                          final rawActs =
                              day['actividades'] ?? day['activities'] ?? [];
                          if (rawActs is List) {
                            activities = rawActs
                                .map((a) {
                                  try {
                                    if (a is Map && a.containsKey('titulo'))
                                      return a['titulo']?.toString() ?? '';
                                    if (a is Map && a.containsKey('title'))
                                      return a['title']?.toString() ?? '';
                                  } catch (_) {}
                                  return a.toString();
                                })
                                .where((s) => s.isNotEmpty)
                                .join(', ');
                          }
                        } catch (_) {}
                        return ListTile(title: Text('Día $dia: $activities'));
                      }),
                      const SizedBox(height: 12),
                      const Text('Servicios incluidos:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      ...paquete!.serviciosIncluidos.map((s) {
                        final m = s;
                        final titulo = (m['titulo'] ??
                                m['title'] ??
                                m['titulo']?.toString() ??
                                '')
                            .toString();
                        final precioUsd =
                            (m['precio_usd'] ?? m['precio'] ?? m['price'])
                                    ?.toString() ??
                                '';
                        return ListTile(
                          title: Text(titulo.isNotEmpty ? titulo : 'Servicio'),
                          subtitle: precioUsd.isNotEmpty
                              ? Text('Precio USD: $precioUsd')
                              : null,
                        );
                      }),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          // abrir crear reserva con prefill (paquete id y precio)
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => CrearReservaPage(
                                        paqueteId: paquete!.id,
                                        paqueteNombre: paquete!.nombre,
                                        prefillTotal: paquete!.displayPrice,
                                      )));
                        },
                        child: const Text('Reservar este paquete'),
                      )
                    ],
                  ),
                ),
    );
  }
}
