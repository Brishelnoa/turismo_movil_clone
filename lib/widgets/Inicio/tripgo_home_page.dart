import 'package:flutter/material.dart';
import 'category_chips.dart';
import 'promo_banner.dart';
import 'tarjeta_de_viaje.dart';
import 'popular_categories.dart';

import '../../models/viaje.dart';

class TripGoHomePage extends StatelessWidget {
  const TripGoHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: const TripGoAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PromoBanner(),
            const SizedBox(height: 12),
            const CategoryChips(),
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
