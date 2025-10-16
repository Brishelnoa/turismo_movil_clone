import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
const String _defaultBaseUrl =
    'https://backendspring2-production.up.railway.app';
const String baseUrl =
    String.fromEnvironment('BASE_URL', defaultValue: _defaultBaseUrl);
final storage = FlutterSecureStorage();

class AuthService {
  static Future<Map<String, dynamic>> register(
      Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/api/register/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
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
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      print('[AuthService] Status: ${response.statusCode}');
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
        return true;
      } else {
        print('[AuthService] Login fallido.');
        return false;
      }
    } catch (e) {
      print('[AuthService] Excepción: $e');
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
    final url = Uri.parse('$baseUrl/api/users/me/');
    try {
      return await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );
    } catch (_) {
      final url2 = Uri.parse('$baseUrl/api/perfil/');
      return await http.get(
        url2,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );
    }
  }
}
