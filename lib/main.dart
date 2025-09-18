import 'package:flutter/material.dart';
import 'widgets/configuracion/configuracion.dart';
import 'widgets/login/login.dart';
import 'widgets/login/register.dart';
import 'widgets/nav/navbar.dart';

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
      },
    );
  }
}
