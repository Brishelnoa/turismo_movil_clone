import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'network.dart';

const String _defaultBaseUrl = 'http://10.0.2.2:8000';

String get baseUrl {
  final env = dotenv.env['BASE_URL'];
  if (env != null && env.isNotEmpty) return env;
  return const String.fromEnvironment('BASE_URL',
      defaultValue: _defaultBaseUrl);
}

class PagoService {
  static Future<String?> iniciarPago(double monto, int reservaId) async {
    try {
      final response = await postPath('/api/pagos/crear-checkout-session/',
          headers: {'Content-Type': 'application/json'},
          body: {'monto': monto, 'reserva_id': reservaId});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url'];
      } else {
        print('Error al crear sesión: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error al iniciar pago: $e');
      return null;
    }
  }
}
