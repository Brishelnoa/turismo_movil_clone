import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Usa la IP local de tu PC si usas un dispositivo físico. Ejemplo: 'http://192.168.1.100:8000'
// Usa la IP local real de tu PC si usas un dispositivo físico. Ejemplo: 'http://192.168.0.12:8000'
const String baseUrl = 'http://192.168.0.12:8000';
final storage = FlutterSecureStorage();

class AuthService {
  static Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/api/auth/register/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      if (response.statusCode == 201) {
        final respData = jsonDecode(response.body);
        await storage.write(key: 'access', value: respData['access']);
        await storage.write(key: 'refresh', value: respData['refresh']);
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
    final url = Uri.parse('$baseUrl/api/auth/login/');
    print('[AuthService] Intentando login en: $url');
    print('[AuthService] Body: {"email": "$email", "password": "${'*' * password.length}"}');
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
        await storage.write(key: 'access', value: data['access']);
        await storage.write(key: 'refresh', value: data['refresh']);
        await storage.write(key: 'user', value: jsonEncode(data['user']));
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
    return await storage.read(key: 'access');
  }

  static Future<void> logout() async {
    await storage.deleteAll();
  }

  static Future<http.Response?> getProfile() async {
    final token = await getAccessToken();
    if (token == null) return null;
    final url = Uri.parse('$baseUrl/api/auth/profile/'); // Cambia por tu endpoint protegido
    return await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }
}