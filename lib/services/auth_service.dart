import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

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
// En debug usamos backend local; en release usamos producción.
// Emulador Android ve el host como 10.0.2.2. Si pruebas en DISPOSITIVO físico,
// puedes poner aquí la IP LAN de tu PC (p.ej. 'http://192.168.0.6:8000')
// o pasarla por --dart-define.
const String _debugLocalBaseUrl = 'http://10.0.2.2:8000';
const String _releaseBaseUrl =
    'https://backendspring2-production.up.railway.app';

const String _defaultBaseUrl =
    kReleaseMode ? _releaseBaseUrl : _debugLocalBaseUrl;

// Siempre se puede sobreescribir con: --dart-define=BASE_URL=http://IP:PUERTO
const String baseUrl =
    String.fromEnvironment('BASE_URL', defaultValue: _defaultBaseUrl);

// 👇 Reemplaza 1 por el ID real del rol CLIENTE en tu BD
const int kClienteRoleId = 2;
final FlutterSecureStorage storage = FlutterSecureStorage();

class AuthService {
  static Future<Map<String, dynamic>> register(
      Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/api/register/');
    debugPrint('=================================================');
    debugPrint('🚀 INICIANDO REGISTRO DE USUARIO');
    debugPrint('📍 URL: $url');
    debugPrint('📡 Base URL: $baseUrl');
    debugPrint('📦 Datos recibidos: ${jsonEncode(data)}');

    // Verificar conexión primero
    try {
      final testConnection = await http.get(Uri.parse('$baseUrl/admin/'));
      print('[AuthService] Test de conexión: ${testConnection.statusCode}');
    } catch (e) {
      print('[AuthService] Error de conexión en test: $e');
    }

    try {
      // Crear un nuevo payload con los campos exactos que espera el backend
      final payload = {
        'nombres': data['nombres']?.trim(),
        'apellidos': data['apellidos']?.trim(),
        'email': data['email']?.trim().toLowerCase(),
        'password': data['password'],
        'password_confirm': data['password'],
        'telefono': data['telefono']?.trim(),
        'fecha_nacimiento': data['fecha_nacimiento'],
        'genero': data['genero'],
        'documento_identidad': data['documento_identidad']?.trim(),
        'pais': data['pais']?.trim() ?? 'BO',
        'rol': kClienteRoleId, // Siempre enviamos el rol de cliente
      };

      // Validar campos requeridos según el backend
      final requiredFields = {
        'nombres': payload['nombres'],
        'email': payload['email'],
        'password': payload['password'],
        'genero': payload['genero'],
        'fecha_nacimiento': payload['fecha_nacimiento'],
        'telefono': payload['telefono'],
      };

      // Verificar campos requeridos
      final missingFields = requiredFields.entries
          .where((e) => e.value == null || e.value.toString().isEmpty)
          .map((e) => e.key)
          .toList();

      if (missingFields.isNotEmpty) {
        return {
          'success': false,
          'error': 'Campos requeridos faltantes: ${missingFields.join(", ")}'
        };
      }

      debugPrint('📤 PAYLOAD A ENVIAR:');
      debugPrint(const JsonEncoder.withIndent('  ').convert(payload));

      debugPrint('🔄 Iniciando petición POST...');

      // si tu backend exige password_confirm:
      if (payload['password'] != null && payload['password_confirm'] == null) {
        payload['password_confirm'] = payload['password'];
      }

      print('[AuthService] URL de registro: $url');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      debugPrint('📥 RESPUESTA DEL SERVIDOR:');
      debugPrint('🔢 Status code: ${response.statusCode}');
      debugPrint('📋 Body: ${response.body}');
      debugPrint('=================================================');

      if (response.statusCode == 201) {
        final respData = jsonDecode(response.body);
        if (respData['token'] != null) {
          await storage.write(key: 'token', value: respData['token']);
        }
        if (respData['access'] != null) {
          await storage.write(key: 'access', value: respData['access']);
        }
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
