import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';
import 'package:url_launcher/url_launcher.dart';

// 🔧 URL del backend - Usando producción (Railway)
const String _releaseBaseUrl =
    'https://backendspring2-production.up.railway.app';
const String baseUrl =
    String.fromEnvironment('BASE_URL', defaultValue: _releaseBaseUrl);

class PagoService {
  /// 🆕 NUEVO: Crear sesión de checkout para app móvil con deep links
  /// Usa el endpoint específico del backend para móvil
  /// ✅ USANDO ENDPOINT MÓVIL OFICIAL - Backend YA implementado
  static Future<Map<String, dynamic>> crearCheckoutMobile({
    required int reservaId,
    required String nombre,
    required double precio, // En bolivianos (ej: 480.00)
    int cantidad = 1,
    String moneda = 'BOB',
    String? clienteEmail,
  }) async {
    debugPrint('=================================================');
    debugPrint('🚀 CREANDO SESIÓN DE CHECKOUT MÓVIL');
    debugPrint('✅ USANDO ENDPOINT MÓVIL OFICIAL');
    debugPrint('📍 URL: $baseUrl/api/crear-checkout-session-mobile/');
    debugPrint('🔑 Reserva ID: $reservaId');
    debugPrint('📝 Nombre producto: $nombre');
    debugPrint('💰 Precio: $precio $moneda');
    debugPrint('📦 Cantidad: $cantidad');
    if (clienteEmail != null) debugPrint('📧 Email: $clienteEmail');

    try {
      // Convertir precio a centavos (Stripe siempre trabaja en centavos)
      final precioCentavos = (precio * 100).round();
      debugPrint('� Precio en centavos: $precioCentavos');

      // Obtener token de autenticación
      final token = await AuthService.getAccessToken();
      if (token == null) {
        throw Exception('No hay token de autenticación. Debes iniciar sesión.');
      }
      debugPrint('✅ Token de autenticación obtenido');

      // ✅ Preparar body para endpoint MÓVIL (formato completo)
      // Backend ahora acepta: reserva_id, nombre, precio, cantidad, moneda
      final body = {
        'reserva_id': reservaId,
        'nombre': nombre,
        'precio': precioCentavos, // ✅ EN CENTAVOS
        'cantidad': cantidad,
        'moneda': moneda,
      };

      debugPrint('📤 Body a enviar (formato MÓVIL oficial):');
      debugPrint(jsonEncode(body));

      // Hacer request al endpoint móvil oficial (backend YA implementado)
      final response = await http.post(
        Uri.parse('$baseUrl/api/crear-checkout-session-mobile/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Token $token',
        },
        body: jsonEncode(body),
      );

      debugPrint('📥 RESPUESTA DEL SERVIDOR:');
      debugPrint('🔢 Status code: ${response.statusCode}');
      debugPrint('📋 Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        debugPrint('✅ Sesión creada exitosamente');
        debugPrint('🔗 Checkout URL: ${data['checkout_url']}');
        debugPrint('🆔 Session ID: ${data['session_id']}');
        debugPrint('💰 Monto: ${data['monto']}');
        debugPrint('=================================================');

        // El backend móvil devuelve formato completo
        return {
          'success': true,
          'checkout_url': data['checkout_url'],
          'session_id': data['session_id'] ?? '',
          'reserva_id': data['reserva_id'] ?? reservaId,
          'monto': data['monto'] ?? precio,
          'moneda': data['moneda'] ?? moneda,
        };
      } else {
        debugPrint('❌ Error del servidor:');
        final errorData = jsonDecode(response.body);
        debugPrint('Error: ${errorData['error']}');

        if (errorData['campo_faltante'] != null) {
          debugPrint('Campo faltante: ${errorData['campo_faltante']}');
        }
        if (errorData['ejemplo'] != null) {
          debugPrint('Ejemplo: ${errorData['ejemplo']}');
        }

        debugPrint('=================================================');

        return {
          'success': false,
          'error': errorData['error'] ?? 'Error desconocido',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      debugPrint('❌ Error inesperado:');
      debugPrint(e.toString());
      debugPrint('=================================================');

      return {
        'success': false,
        'error': 'Error de conexión: ${e.toString()}',
      };
    }
  }

  /// Abre la URL de checkout de Stripe en navegador externo
  /// Esto permite que los deep links funcionen correctamente
  static Future<bool> abrirCheckoutEnNavegador(String checkoutUrl) async {
    debugPrint('[Pago] 🌐 Abriendo checkout en navegador externo...');
    debugPrint('[Pago] URL: $checkoutUrl');

    try {
      final Uri url = Uri.parse(checkoutUrl);

      // 🔧 INTENTO 1: Lanzar directamente sin verificar (más agresivo)
      // canLaunchUrl a veces falla incorrectamente en Android
      debugPrint('[Pago] 🚀 Intentando lanzar URL directamente...');

      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication, // ✅ CRÍTICO: Navegador externo
      );

      if (launched) {
        debugPrint('[Pago] ✅ Navegador abierto correctamente');
      } else {
        debugPrint('[Pago] ❌ No se pudo abrir el navegador (launched = false)');
      }

      return launched;
    } catch (e) {
      debugPrint('[Pago] ❌ Error abriendo navegador: $e');

      // 🔧 INTENTO 2: Probar con modo platformDefault
      try {
        debugPrint('[Pago] 🔄 Reintentando con modo platformDefault...');
        final Uri url = Uri.parse(checkoutUrl);
        final launched2 =
            await launchUrl(url, mode: LaunchMode.platformDefault);
        debugPrint('[Pago] Resultado intento 2: $launched2');
        return launched2;
      } catch (e2) {
        debugPrint('[Pago] ❌ Error en segundo intento: $e2');
        return false;
      }
    }
  }

  /// Verifica el estado de una reserva después del pago
  static Future<Map<String, dynamic>?> verificarEstadoReserva(
      int reservaId) async {
    debugPrint('[Pago] 🔍 Verificando estado de reserva $reservaId...');

    try {
      final token = await AuthService.getAccessToken();
      if (token == null) {
        debugPrint('[Pago] ❌ No hay token de autenticación');
        return null;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/reservas/$reservaId/'),
        headers: {
          'Authorization': 'Token $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('[Pago] 📡 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('[Pago] ✅ Estado de reserva: ${data['estado']}');
        return data;
      } else {
        debugPrint('[Pago] ❌ Error al verificar reserva: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('[Pago] ❌ Error: $e');
      return null;
    }
  }

  // ========================================================================
  // ENDPOINT ANTIGUO (Mantener por compatibilidad, pero marcado como deprecated)
  // ========================================================================

  /// @deprecated Usar crearCheckoutMobile() en su lugar
  /// Este endpoint es para la versión web
  static Future<String?> iniciarPago(double monto, int reservaId) async {
    final url = Uri.parse('$baseUrl/api/pagos/crear-checkout-session/');
    debugPrint('⚠️ ADVERTENCIA: Usando endpoint antiguo (web)');
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
        return url;
      } else {
        debugPrint('❌ Error al crear sesión de pago');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error inesperado: $e');
      return null;
    }
  }
}
