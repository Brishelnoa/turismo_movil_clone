import 'package:flutter/material.dart';
import '../services/paquetes_service.dart';
import '../models/paquete.dart';
import 'crear_reserva_page.dart';

class PaqueteDetailPage extends StatefulWidget {
  const PaqueteDetailPage({Key? key, required this.paqueteId}) : super(key: key);
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
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(resp['error'].toString())));
      }
    } else {
      paquete = Paquete.fromJson(resp.cast<String, dynamic>());
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Detalle del Paquete'),
        backgroundColor: Colors.teal,
        elevation: 2,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : paquete == null
              ? const Center(child: Text('No se encontró el paquete'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Imagen principal (si el modelo tiene campo imagen)
                      // if (paquete!.imagenUrl != null &&
                      //     paquete!.imagenUrl!.isNotEmpty)
                      //   ClipRRect(
                      //     borderRadius: BorderRadius.circular(16),
                      //     child: Image.network(
                      //       paquete!.imagenUrl!,
                      //       height: 200,
                      //       width: double.infinity,
                      //       fit: BoxFit.cover,
                      //     ),
                      //   ),
                      // const SizedBox(height: 16),

                      // Nombre
                      Text(
                        paquete!.nombre,
                        style: theme.textTheme.headlineSmall!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.teal[800],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Descripción
                      if (paquete!.descripcion.isNotEmpty)
                        Text(
                          paquete!.descripcion,
                          style: theme.textTheme.bodyLarge!.copyWith(
                            color: Colors.grey[700],
                            height: 1.4,
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Datos básicos
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _InfoChip(
                            icon: Icons.access_time,
                            label: 'Duración',
                            value: paquete!.duracion,
                          ),
                          _InfoChip(
                            icon: Icons.attach_money,
                            label: 'Precio',
                            value: paquete!.displayPrice,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Itinerario
                      _SectionCard(
                        title: 'Itinerario',
                        icon: Icons.calendar_month,
                        children: paquete!.itinerario.map((d) {
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
                                    if (a is Map && a.containsKey('titulo')) {
                                      return a['titulo']?.toString() ?? '';
                                    }
                                    if (a is Map && a.containsKey('title')) {
                                      return a['title']?.toString() ?? '';
                                    }
                                    return a.toString();
                                  })
                                  .where((s) => s.isNotEmpty)
                                  .join(', ');
                            }
                          } catch (_) {}
                          return ListTile(
                            leading: const Icon(Icons.today, color: Colors.teal),
                            title: Text('Día $dia'),
                            subtitle: Text(activities.isNotEmpty
                                ? activities
                                : 'Sin actividades registradas'),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 16),

                      // Servicios incluidos
                      _SectionCard(
                        title: 'Servicios Incluidos',
                        icon: Icons.check_circle_outline,
                        children: paquete!.serviciosIncluidos.map((s) {
                          final titulo = (s['titulo'] ??
                                  s['title'] ??
                                  s['titulo']?.toString() ??
                                  '')
                              .toString();
                          final precioUsd = (s['precio_usd'] ??
                                      s['precio'] ??
                                      s['price'])
                                  ?.toString() ??
                              '';
                          return ListTile(
                            leading:
                                const Icon(Icons.done, color: Colors.teal),
                            title:
                                Text(titulo.isNotEmpty ? titulo : 'Servicio'),
                            subtitle: precioUsd.isNotEmpty
                                ? Text('Precio USD: $precioUsd')
                                : null,
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),

                      // Botón de reserva
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          textStyle: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CrearReservaPage(
                                paqueteId: paquete!.id,
                                paqueteNombre: paquete!.nombre,
                                prefillTotal: paquete!.displayPrice,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.shopping_cart_outlined),
                        label: const Text('Reservar este paquete'),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoChip(
      {required this.icon, required this.label, required this.value, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18, color: Colors.teal[700]),
      backgroundColor: Colors.teal[50],
      label: Text(
        '$label: $value',
        style: TextStyle(color: Colors.teal[800]),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _SectionCard(
      {required this.title, required this.icon, required this.children, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.teal),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }
}
