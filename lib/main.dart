import 'package:flutter/material.dart';
import 'widgets/configuracion/configuracion.dart';
import 'widgets/login/login.dart';
import 'widgets/login/register.dart';
import 'widgets/nav/navbar.dart';
import 'view/pago_view.dart';
import 'view/mis_reservas_page.dart';
import 'view/crear_reserva_page.dart';
import 'view/paquetes_list_page.dart';
import 'view/paquete_detail_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Descubre Bolivia',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SignInPage1(),
      routes: {
        '/login': (context) => const SignInPage1(),
        '/register': (context) => const RegisterPage(),
        '/Perfil': (context) => const SettingsPage2(),
        '/Inicio': (context) => const GoogleBottomBar(),
        '/Pago': (context) => const PagoView(monto: 50.0, reservaId: 1),
        '/MisReservas': (context) => const MisReservasPage(),
        '/CrearReserva': (context) => const CrearReservaPage(),
        '/Paquetes': (context) => const PaquetesListPage(),
        '/PaqueteDetail': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          final id =
              args is int ? args : int.tryParse(args?.toString() ?? '0') ?? 0;
          return PaqueteDetailPage(paqueteId: id);
        },
      },
    );
  }
}
