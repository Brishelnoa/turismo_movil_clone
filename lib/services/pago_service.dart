
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

const String _debugLocalBaseUrl = 'http://10.0.2.2:8000';
const String _releaseBaseUrl = 'https://backendspring2-production.up.railway.app';
const String _defaultBaseUrl = kReleaseMode ? _releaseBaseUrl : _debugLocalBaseUrl;
const String baseUrl = String.fromEnvironment('BASE_URL', defaultValue: _defaultBaseUrl);

class PagoService {
  static Future<String?> iniciarPago(double monto, int reservaId) async {
    final url = Uri.parse('$baseUrl/api/pagos/crear-checkout-session/');
    debugPrint('=================================================');
    debugPrint('🚀 INICIANDO PAGO');
    debugPrint('📍 URL: $url');
    debugPrint('💰 Monto: $monto');
    debugPrint('🔑 Reserva ID: $reservaId');
    
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'monto': monto, 'reserva_id': reservaId}),
      );

      debugPrint('📥 RESPUESTA DEL SERVIDOR:');
      debugPrint('🔢 Status code: ${response.statusCode}');
      debugPrint('📋 Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final url = data['url'];
        debugPrint('🔗 URL de pago generada: $url');
        debugPrint('=================================================');
        return url;
      } else {
        debugPrint('❌ Error al crear sesión de pago:');
        debugPrint('Status: ${response.statusCode}');
        debugPrint('Respuesta: ${response.body}');
        debugPrint('=================================================');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error inesperado al iniciar pago:');
      debugPrint(e.toString());
      debugPrint('=================================================');
      return null;
    }
  }
}
