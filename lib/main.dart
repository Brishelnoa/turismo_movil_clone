import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/fcm_service.dart';
import 'services/auth_service.dart';
import 'widgets/configuracion/configuracion.dart';
import 'widgets/login/login.dart';
import 'widgets/login/register.dart';
import 'widgets/nav/navbar.dart';
import 'view/pago_view.dart';
import 'view/mis_reservas_page.dart';
import 'view/crear_reserva_page.dart';
import 'view/paquetes_list_page.dart';
import 'view/paquete_detail_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Intentar cargar variables desde .env en la raíz del proyecto.
  // Si no existe (por ejemplo no fue incluido en los assets), no fallamos:
  // - Para desarrollo puedes usar --dart-define=BASE_URL="http://..."
  // - O añadir el archivo .env a los assets en pubspec.yaml
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    // No dejamos que la app se cierre por falta de .env; informamos al dev.
    // En producción preferible usar --dart-define o variables de entorno en CI/CD.
    // Ejemplo: flutter run --dart-define=BASE_URL="http://192.168.0.13:8000"
    // Si quieres incluir .env en los assets, añade en pubspec.yaml:
    // flutter:
    //   assets:
    //     - .env
    print(
        '[dotenv] avisO: .env no encontrado, continuando sin él. Usar --dart-define o añadir .env a assets si lo necesitas. Error: $e');
  }
  // Mostrar la URL que se usará (ayuda a depurar problemas de conexión)
  // Resuelta en el servicio de auth (prioriza .env, luego --dart-define, luego default)
  print('[main] BASE_URL resuelta: $baseUrl');

  // Inicializar Firebase y FCM antes de iniciar la UI
  try {
    await FcmService.init();
  } catch (e) {
    // No debemos bloquear la app si Firebase falla — informar y continuar
    print('[main] Advertencia: FCM init falló: $e');
  }

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
