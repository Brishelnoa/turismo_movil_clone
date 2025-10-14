import 'package:flutter/material.dart';
import 'vista_principal_items.dart';
import 'hero_list_item_page.dart';
import 'pago_view.dart';

class HeroListView extends StatefulWidget {
  const HeroListView({super.key});

  @override
  State<HeroListView> createState() => _HeroListViewState();
}

class _HeroListViewState extends State<HeroListView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hero List View")),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) => ListTile(
          minTileHeight: 100,
          title: Text(items[index].title),
          leading: Hero(
            tag: "hero_list_item_$index",
            child: Container(
              width: 60,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: items[index].color.withValues(alpha: 0.1),
              ),
              child: Icon(items[index].icon, color: items[index].color),
            ),
          ),
          onTap: () {
            if (items[index].title == "Procesar Pago") {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PagoView(
                    monto: 50.0,
                    reservaId: 1,
                  ),
                ),
              );
            } else if (items[index].title == "Mis Reservas") {
              Navigator.pushNamed(context, '/MisReservas');
            } else if (items[index].title == "Crear Reserva") {
              Navigator.pushNamed(context, '/CrearReserva');
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HeroListItemPage(index: index),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
