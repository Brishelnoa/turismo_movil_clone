import 'package:flutter/material.dart';
import 'category_chips.dart';
import 'promo_banner.dart';
import 'tarjeta_de_viaje.dart';
import 'popular_categories.dart';

import '../../models/viaje.dart';
import '../../models/paquete.dart';
import '../../services/paquetes_service.dart';
import '../../widgets/paquete_card.dart';

class TripGoHomePage extends StatefulWidget {
  const TripGoHomePage({super.key});

  @override
  State<TripGoHomePage> createState() => _TripGoHomePageState();
}

class _TripGoHomePageState extends State<TripGoHomePage> {
  List<Paquete> paquetes = [];
  bool loadingPaquetes = false;

  @override
  void initState() {
    super.initState();
    _loadPaquetes();
  }

  Future<void> _loadPaquetes() async {
    setState(() => loadingPaquetes = true);
    try {
      final res = await PaquetesService.listPaquetes(page: 1, pageSize: 10);
      final list = (res['results'] ??
          res['data'] ??
          res['paquetes'] ??
          res['items'] ??
          []) as List<dynamic>;
      final loaded =
          list.map((e) => Paquete.fromJson(e as Map<String, dynamic>)).toList();
      if (!mounted) return;
      setState(() => paquetes = loaded);
    } catch (_) {
      // ignore errors for now
    } finally {
      if (!mounted) return;
      setState(() => loadingPaquetes = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PromoBanner(),
            const SizedBox(height: 12),
            const CategoryChips(),
            const SizedBox(height: 12),

            // Paquetes destacados horizontal list
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text('Paquetes destacados',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            SizedBox(
              height: 220,
              child: loadingPaquetes
                  ? const Center(child: CircularProgressIndicator())
                  : paquetes.isEmpty
                      ? const Center(child: Text('No hay paquetes'))
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.only(bottom: 8, right: 8),
                          itemBuilder: (context, index) {
                            final p = paquetes[index];
                            return SizedBox(
                                width: 320,
                                child: PaqueteCard(
                                    paquete: p,
                                    onTap: () => Navigator.pushNamed(
                                        context, '/PaqueteDetail',
                                        arguments: p.id)));
                          },
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemCount: paquetes.length,
                        ),
            ),

            const SizedBox(height: 12),
            Column(
              children: viajesDemo
                  .map((viaje) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TarjetaViaje(viaje: viaje),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            const PopularCategoriesSection(),
          ],
        ),
      ),
    );
  }
}
