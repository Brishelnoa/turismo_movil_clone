import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String baseUrl = 'http://10.0.2.2:8000'; // Cambia por la IP de tu backend si usas dispositivo físico
final storage = FlutterSecureStorage();

class AuthService {
  static Future<bool> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/api/auth/login/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await storage.write(key: 'access', value: data['access']);
      await storage.write(key: 'refresh', value: data['refresh']);
      await storage.write(key: 'user', value: jsonEncode(data['user']));
      return true;
    } else {
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