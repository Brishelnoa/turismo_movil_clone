import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:app_links/app_links.dart';

/// Servicio para manejar deep links desde Stripe después del pago
/// Usa app_links (reemplazo moderno de uni_links)
class DeepLinkService {
  static AppLinks? _appLinks;
  static StreamSubscription? _subscription;
  static bool _isInitialized = false;

  /// Callbacks para manejar diferentes resultados del pago
  static Function(Uri)? _onPaymentSuccess;
  static Function(Uri)? _onPaymentCancel;
  static Function(Uri)? _onPaymentError;
  static Function(Uri)? _onPaymentPending;

  /// Inicializa el listener de deep links
  static Future<void> init({
    required Function(Uri) onPaymentSuccess,
    required Function(Uri) onPaymentCancel,
    required Function(Uri) onPaymentError,
    Function(Uri)? onPaymentPending,
  }) async {
    if (_isInitialized) {
      debugPrint('[DeepLink] ⚠️ Ya está inicializado, reiniciando...');
      dispose();
    }

    debugPrint('[DeepLink] 🚀 Inicializando servicio de deep links...');

    _onPaymentSuccess = onPaymentSuccess;
    _onPaymentCancel = onPaymentCancel;
    _onPaymentError = onPaymentError;
    _onPaymentPending = onPaymentPending;

    _appLinks = AppLinks();

    // Manejar deep link inicial (cuando la app se abre desde el link)
    await _handleInitialLink();

    // Escuchar deep links cuando la app está en background
    _subscription = _appLinks!.uriLinkStream.listen(
      (Uri uri) {
        debugPrint('[DeepLink] 📲 Deep link recibido (background): $uri');
        _handleDeepLink(uri);
      },
      onError: (err) {
        debugPrint('[DeepLink] ❌ Error en stream: $err');
      },
    );

    _isInitialized = true;
    debugPrint('[DeepLink] ✅ Servicio inicializado correctamente');
  }

  /// Maneja el deep link inicial (cuando la app se abre con el link)
  static Future<void> _handleInitialLink() async {
    try {
      debugPrint('[DeepLink] 🔍 Buscando deep link inicial...');
      final initialUri = await _appLinks!.getInitialLink();

      if (initialUri != null) {
        debugPrint('[DeepLink] 📲 Deep link inicial encontrado: $initialUri');
        _handleDeepLink(initialUri);
      } else {
        debugPrint('[DeepLink] ℹ️ No hay deep link inicial');
      }
    } catch (e) {
      debugPrint('[DeepLink] ❌ Error obteniendo deep link inicial: $e');
    }
  }

  /// Procesa el deep link y ejecuta el callback correspondiente
  static void _handleDeepLink(Uri uri) {
    debugPrint('[DeepLink] 🔗 Procesando deep link:');
    debugPrint('[DeepLink] - Scheme: ${uri.scheme}');
    debugPrint('[DeepLink] - Host: ${uri.host}');
    debugPrint('[DeepLink] - Path: ${uri.path}');
    debugPrint('[DeepLink] - Query params: ${uri.queryParameters}');

    // Validar que es nuestro esquema
    if (uri.scheme != 'turismoapp') {
      debugPrint('[DeepLink] ⚠️ Esquema no reconocido: ${uri.scheme}');
      return;
    }

    // Extraer parámetros comunes
    final sessionId = uri.queryParameters['session_id'];
    final reservaId = uri.queryParameters['reserva_id'];
    final status = uri.queryParameters['status'];
    final monto = uri.queryParameters['monto'];

    debugPrint('[DeepLink] 📊 Datos extraídos:');
    debugPrint('[DeepLink] - Session ID: $sessionId');
    debugPrint('[DeepLink] - Reserva ID: $reservaId');
    debugPrint('[DeepLink] - Status: $status');
    debugPrint('[DeepLink] - Monto: $monto');

    // Ejecutar callback según el host
    switch (uri.host) {
      case 'payment-success':
        debugPrint('[DeepLink] ✅ PAGO EXITOSO');
        _onPaymentSuccess?.call(uri);
        break;

      case 'payment-cancel':
        debugPrint('[DeepLink] ❌ PAGO CANCELADO');
        _onPaymentCancel?.call(uri);
        break;

      case 'payment-error':
        debugPrint('[DeepLink] 🚨 ERROR EN PAGO');
        _onPaymentError?.call(uri);
        break;

      case 'payment-pending':
        debugPrint('[DeepLink] ⏳ PAGO PENDIENTE');
        _onPaymentPending?.call(uri);
        break;

      default:
        debugPrint('[DeepLink] ⚠️ Host no reconocido: ${uri.host}');
    }
  }

  /// Cancela el listener y limpia recursos
  static void dispose() {
    debugPrint('[DeepLink] 🔚 Cerrando servicio de deep links...');
    _subscription?.cancel();
    _subscription = null;
    _onPaymentSuccess = null;
    _onPaymentCancel = null;
    _onPaymentError = null;
    _onPaymentPending = null;
    _isInitialized = false;
    debugPrint('[DeepLink] ✅ Servicio cerrado');
  }

  /// Verifica si el servicio está inicializado
  static bool get isInitialized => _isInitialized;
}
