import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';
import 'dart:async';
import 'network.dart';
import 'package:flutter/foundation.dart';
import 'fcm_service.dart';

// URL base del backend.
// - Por defecto usa la IP de desarrollo actual. Cámbiala según tu red/back-end.
// - Para mayor flexibilidad, puedes sobreescribirla en tiempo de ejecución de
//   build / run usando --dart-define, por ejemplo:
//   flutter run --dart-define=BASE_URL="http://192.168.0.6:8000"
// Notas útiles:
// - Si usas el Android emulator (default), desde el emulador la IP del host
//   es 10.0.2.2 (usa http://10.0.2.2:8000)
// - Genymotion usa 10.0.3.2
// - iOS Simulator puede usar localhost (http://127.0.0.1:8000)
// - Si ejecutas en un dispositivo físico en la misma LAN, usa la IP de tu PC
//   en la LAN (por ejemplo 192.168.0.6). Asegúrate que esa IP está en
//   ALLOWED_HOSTS en tu backend.
// Si no pasas --dart-define, se usará _defaultBaseUrl.
// Production value is documented in .env.example and can be provided via
// --dart-define or env file. Default to local emulator host for dev.
const String _defaultBaseUrl = 'http://192.168.0.6:8000';

/// Resuelve la URL base con el siguiente orden de prioridad:
/// 1. dotenv.env['BASE_URL'] (archivo .env cargado en main)
/// 2. --dart-define=BASE_URL (String.fromEnvironment)
/// 3. _defaultBaseUrl (10.0.2.2 para emulador Android)
String get baseUrl {
  // Resolve at call time so dotenv (loaded in main) has a chance to populate values.
  final env = dotenv.env['BASE_URL'];
  if (env != null && env.isNotEmpty) return env;
  return const String.fromEnvironment('BASE_URL',
      defaultValue: _defaultBaseUrl);
}

// Nota: para depuración, pide la variable `baseUrl` desde otro archivo
// (por ejemplo desde main.dart) en tiempo de ejecución — evitar prints
// en el nivel superior para mantener la librería limpia.
final storage = FlutterSecureStorage();

class AuthService {
  static Future<Map<String, dynamic>> register(
      Map<String, dynamic> data) async {
    try {
      final response = await postPath('/api/register/',
          headers: {'Content-Type': 'application/json'}, body: data);
      if (response.statusCode == 201) {
        final respData = jsonDecode(response.body);
        // backend may return 'token' (TokenAuthentication) or 'access' (JWT)
        if (respData['token'] != null)
          await storage.write(key: 'token', value: respData['token']);
        if (respData['access'] != null)
          await storage.write(key: 'access', value: respData['access']);
        return {'success': true, 'data': respData};
      } else {
        final errorData = jsonDecode(response.body);
        return {'success': false, 'error': errorData};
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de red o inesperado: $e'};
    }
  }

  static Future<bool> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/api/login/');
    print('[AuthService] Intentando login en: $url');
    print(
        '[AuthService] Body: {"email": "$email", "password": "${'*' * password.length}"}');
    try {
      // Apply a timeout so the call fails fast if network is unreachable
      final start = DateTime.now();
      // Use network helper which will try candidates and cache a working base URL
      final response = await postPath('/api/login/',
          headers: {'Content-Type': 'application/json'},
          body: {'email': email, 'password': password});
      final elapsed = DateTime.now().difference(start);
      print(
          '[AuthService] Status: ${response.statusCode} (took ${elapsed.inMilliseconds} ms)');
      print('[AuthService] Respuesta: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // backend may return 'token' (TokenAuthentication) or 'access' (JWT)
        if (data['token'] != null)
          await storage.write(key: 'token', value: data['token']);
        if (data['access'] != null)
          await storage.write(key: 'access', value: data['access']);
        if (data['refresh'] != null)
          await storage.write(key: 'refresh', value: data['refresh']);
        // user object may be under 'user' or 'profile'
        if (data['user'] != null)
          await storage.write(key: 'user', value: jsonEncode(data['user']));
        if (data['profile'] != null)
          await storage.write(key: 'user', value: jsonEncode(data['profile']));
        print('[AuthService] Login exitoso, tokens guardados.');
        // Attempt to register FCM token after successful login (if available).
        // Use a safe fallback that ensures Firebase is initialized before
        // attempting to obtain the token.
        try {
          final registered = await FcmService.ensureInitializedAndRegister();
          if (registered) {
            if (kDebugMode)
              debugPrint('[AuthService] FCM token sent to backend');
          } else {
            if (kDebugMode)
              debugPrint(
                  '[AuthService] FCM token not registered (no token or backend rejected)');
          }
        } catch (e) {
          if (kDebugMode)
            debugPrint('[AuthService] Could not register FCM token: $e');
        }
        return true;
      } else {
        print('[AuthService] Login fallido. Status ${response.statusCode}');
        try {
          final err = jsonDecode(response.body);
          print('[AuthService] Error body: $err');
        } catch (_) {
          print('[AuthService] Error body (no-json): ${response.body}');
        }
        return false;
      }
    } on TimeoutException catch (te) {
      print('[AuthService] TimeoutException: $te');
      return false;
    } on SocketException catch (se) {
      print('[AuthService] SocketException (network): $se');
      return false;
    } catch (e, st) {
      print('[AuthService] Excepción inesperada: $e');
      print(st);
      return false;
    }
  }

  static Future<String?> getAccessToken() async {
    // Prefer Token ('token') used by rest_framework.authtoken, fall back to JWT 'access'
    final t = await storage.read(key: 'token');
    if (t != null) return t;
    return await storage.read(key: 'access');
  }

  /// Devuelve el id del usuario almacenado en secure storage (si existe).
  static Future<int?> getCurrentUserId() async {
    final s = await storage.read(key: 'user');
    if (s == null) return null;
    try {
      final m = jsonDecode(s);
      if (m is Map<String, dynamic>) {
        final idVal = m['id'] ?? m['pk'] ?? m['user_id'];
        if (idVal is int) return idVal;
        if (idVal is String) return int.tryParse(idVal);
      }
    } catch (e) {
      // ignore parse errors
    }
    return null;
  }

  /// Devuelve el mapa del usuario almacenado (o null si no existe)
  static Future<Map<String, dynamic>?> getStoredUser() async {
    final s = await storage.read(key: 'user');
    if (s == null) return null;
    try {
      final m = jsonDecode(s);
      if (m is Map<String, dynamic>) return m;
    } catch (_) {}
    return null;
  }

  static Future<void> logout() async {
    await storage.deleteAll();
  }

  static Future<http.Response?> getProfile() async {
    final token = await getAccessToken();
    if (token == null) return null;
    // prefer /api/users/me/ as in guide, fall back to /api/perfil/
    try {
      return await getPath('/api/users/me/', headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      });
    } catch (_) {
      return await getPath('/api/perfil/', headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      });
    }
  }
}
