import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import '../configuracion/configuracion.dart';
import '../Inicio/tripgo_home_page.dart';
import '../guardado/pagina.viaje.dart';

class GoogleBottomBar extends StatefulWidget {
  const GoogleBottomBar({super.key});

  @override
  State<GoogleBottomBar> createState() => _GoogleBottomBarState();
}

class _GoogleBottomBarState extends State<GoogleBottomBar> {
  int _selectedIndex = 0;

  // 👇 Pantallas de cada tab
  final List<Widget> _screens = const [
    _InicioView(),
    _LikesView(),
    _BuscarView(),
    _PerfilView(), // si quieres, aquí puedes poner tu ProfilePage1()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.orange[400],
        elevation: 0,
        title: const Text(
          'Turismo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.notifications_none, color: Colors.black87),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex, // 👈 mantiene estado de cada tab
        children: _screens,
      ),
      bottomNavigationBar: SalomonBottomBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xff6200ee),
        unselectedItemColor: const Color(0xff757575),
        onTap: (index) => setState(() => _selectedIndex = index),
        items: _navBarItems,
      ),
    );
  }
}

// Títulos para el AppBar por tab
const _titles = ['Turismo - Inicio', 'Tus me gusta', 'Buscar', 'Perfil'];

// Ítems del bottom bar
final _navBarItems = [
  SalomonBottomBarItem(
    icon: const Icon(Icons.home),
    title: const Text("Inicio"),
    selectedColor: Colors.purple,
  ),
  SalomonBottomBarItem(
    icon: const Icon(Icons.favorite_border),
    title: const Text("Me gusta"),
    selectedColor: Colors.pink,
  ),
  SalomonBottomBarItem(
    icon: const Icon(Icons.search),
    title: const Text("Buscar"),
    selectedColor: Colors.orange,
  ),
  SalomonBottomBarItem(
    icon: const Icon(Icons.person),
    title: const Text("Perfil"),
    selectedColor: Colors.teal,
  ),
];

// —— Placeholders simples ——
class _InicioView extends StatelessWidget {
  const _InicioView({super.key});
  @override
  Widget build(BuildContext context) => const TripGoHomePage();
}

class _LikesView extends StatelessWidget {
  const _LikesView({super.key});
  @override
  Widget build(BuildContext context) => const PaginaViajes();
}

class _BuscarView extends StatelessWidget {
  const _BuscarView({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Buscar', style: TextStyle(fontSize: 22)));
}

class _PerfilView extends StatelessWidget {
  const _PerfilView({super.key});
  @override
  Widget build(BuildContext context) => const SettingsPage2();
}
