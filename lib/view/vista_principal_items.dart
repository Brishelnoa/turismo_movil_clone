import 'package:flutter/material.dart';

class Item {
  final String title;
  final IconData icon;
  final Color color;

  Item({required this.title, required this.icon, required this.color});
}

final items = [
  Item(title: "Home Page", icon: Icons.home, color: Colors.redAccent),
  Item(title: "Profile Page", icon: Icons.person, color: Colors.blueAccent),
  Item(title: "Settings Page", icon: Icons.settings, color: Colors.cyan),
  Item(title: "Email Page", icon: Icons.email, color: Colors.green),
  Item(title: "Phone Page", icon: Icons.phone, color: Colors.purpleAccent),

  // 👇 Nuevo item para el flujo de pagos móviles
  Item(
      title: "Procesar Pago",
      icon: Icons.credit_card,
      color: Colors.orangeAccent),

  // 👇 Nuevo item para Mis Reservas
  Item(title: "Mis Reservas", icon: Icons.book_online, color: Colors.teal),
  // Item para crear reserva rápida
  Item(title: "Crear Reserva", icon: Icons.add_box, color: Colors.indigo),
];
