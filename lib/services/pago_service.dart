import 'package:http/http.dart' as http;
import 'dart:convert';

const String baseUrl = 'http://192.168.0.17:8000';

class PagoService {
  static Future<String?> iniciarPago(double monto, int reservaId) async {
    final url = Uri.parse('$baseUrl/api/pagos/crear-checkout-session/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'monto': monto, 'reserva_id': reservaId}),
      );

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
