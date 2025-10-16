// Ejemplo de login y uso de token JWT en Flutter
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String _defaultBaseUrl =
    'https://backendspring2-production.up.railway.app';
const String baseUrl =
    String.fromEnvironment('BASE_URL', defaultValue: _defaultBaseUrl);
final storage = FlutterSecureStorage();

Future<void> login(String email, String password) async {
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
    print('Login exitoso. Token guardado.');
  } else {
    print('Error: ' + response.body);
  }
}

Future<void> getUserProfile() async {
  final token = await storage.read(key: 'access');
  if (token == null) {
    print('No hay token guardado.');
    return;
  }
  final url = Uri.parse(
    '$baseUrl/api/auth/profile/',
  ); // Cambia por tu endpoint protegido
  final response = await http.get(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );
  if (response.statusCode == 200) {
    print('Perfil: ' + response.body);
  } else {
    print('Error al obtener perfil: ' + response.body);
  }
}
