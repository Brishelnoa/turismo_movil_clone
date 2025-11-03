import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'auth_service.dart';
import 'network.dart';

class PaquetesService {
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getAccessToken();
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) {
      // If token looks like a JWT (has dots), use Bearer; otherwise use DRF Token scheme
      if (token.contains('.'))
        headers['Authorization'] = 'Bearer $token';
      else
        headers['Authorization'] = 'Token $token';
    }
    return headers;
  }

  static Future<Map<String, dynamic>> listPaquetes(
      {int? page, int? pageSize, Map<String, dynamic>? filtros}) async {
    final merged = <String, dynamic>{};
    if (filtros != null) merged.addAll(filtros);
    if (page != null) merged['page'] = page;
    if (pageSize != null) merged['page_size'] = pageSize;
    final qp = merged.entries
        .map((e) =>
            '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value.toString())}')
        .join('&');
    // relative path used with getPath
    try {
      final headers = await _getHeaders();
      if (kDebugMode)
        debugPrint(
            '[PaquetesService] GET /api/paquetes/${qp.isNotEmpty ? '?$qp' : ''}');
      final res = await getPath('/api/paquetes/${qp.isNotEmpty ? '?$qp' : ''}',
          headers: headers);
      if (kDebugMode)
        debugPrint('[PaquetesService] Response ${res.statusCode}: ${res.body}');
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        // Normalizar varios formatos posibles:
        // - List root -> devolver como results (DRF-like)
        // - Map with results/count -> devolver tal cual
        // - Map with other keys -> devolver cast
        if (body is List) {
          if (body.isEmpty) {
            // fallback: maybe backend uses campanias
            if (kDebugMode)
              debugPrint(
                  '[PaquetesService] paquetes empty, trying /api/campanias/${qp.isNotEmpty ? '?$qp' : ''}');
            final res2 = await getPath(
                '/api/campanias/${qp.isNotEmpty ? '?$qp' : ''}',
                headers: headers);
            if (kDebugMode)
              debugPrint(
                  '[PaquetesService] Response campanias ${res2.statusCode}: ${res2.body}');
            if (res2.statusCode == 200) {
              final b2 = jsonDecode(res2.body);
              if (b2 is List) return {'results': b2};
              if (b2 is Map<String, dynamic>) return b2;
              return {'results': b2};
            }
          }
          return {'results': body};
        }
        if (body is Map<String, dynamic>) {
          // if paginated but empty, try campanias
          if (body.containsKey('results') &&
              (body['results'] is List) &&
              (body['results'] as List).isEmpty) {
            if (kDebugMode)
              debugPrint(
                  '[PaquetesService] paquetes.results empty, trying /api/campanias/${qp.isNotEmpty ? '?$qp' : ''}');
            final res2 = await getPath(
                '/api/campanias/${qp.isNotEmpty ? '?$qp' : ''}',
                headers: headers);
            if (kDebugMode)
              debugPrint(
                  '[PaquetesService] Response campanias ${res2.statusCode}: ${res2.body}');
            if (res2.statusCode == 200) {
              final b2 = jsonDecode(res2.body);
              if (b2 is List) return {'results': b2};
              if (b2 is Map<String, dynamic>) return b2;
              return {'results': b2};
            }
          }
          return body;
        }
        // unexpected, wrap
        return {'results': body};
      }
      if (kDebugMode)
        debugPrint(
            '[PaquetesService] listPaquetes failed: ${res.statusCode} ${res.body}');
      return {
        'error': 'Status ${res.statusCode}',
        'body': res.body,
        'status': res.statusCode
      };
    } catch (e) {
      if (kDebugMode) debugPrint('[PaquetesService] exception: $e');
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getPaquete(int id) async {
    // relative path used below when calling getPath
    try {
      final headers = await _getHeaders();
      if (kDebugMode) debugPrint('[PaquetesService] GET /api/paquetes/$id/');
      final res = await getPath('/api/paquetes/$id/', headers: headers);
      if (kDebugMode)
        debugPrint('[PaquetesService] Response ${res.statusCode}: ${res.body}');
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        // Normalize common wrapper shapes so callers receive the paquete Map
        if (body is Map<String, dynamic>) {
          // If there's a direct object under common keys, return that
          for (final key in ['paquete', 'data', 'item', 'result', 'results']) {
            if (body.containsKey(key)) {
              final inner = body[key];
              if (inner is Map<String, dynamic>) return inner;
              if (inner is List &&
                  inner.isNotEmpty &&
                  inner.first is Map<String, dynamic>)
                return inner.first as Map<String, dynamic>;
            }
          }
          // If the map itself looks like the paquete, return it
          return body;
        }
        if (body is List &&
            body.isNotEmpty &&
            body.first is Map<String, dynamic>) {
          return body.first as Map<String, dynamic>;
        }
        // If empty or not found, try campanias detail as fallback
        // e.g., /api/campanias/{id}/
        try {
          if (kDebugMode)
            debugPrint('[PaquetesService] trying fallback /api/campanias/$id/');
          final res2 = await getPath('/api/campanias/$id/', headers: headers);
          if (kDebugMode)
            debugPrint(
                '[PaquetesService] Response campanias detail ${res2.statusCode}: ${res2.body}');
          if (res2.statusCode == 200) {
            final b2 = jsonDecode(res2.body);
            if (b2 is Map<String, dynamic>) return b2;
            if (b2 is List && b2.isNotEmpty && b2.first is Map<String, dynamic>)
              return b2.first as Map<String, dynamic>;
          }
        } catch (_) {}
        // fallback: wrap into map
        return {'data': body};
      }
      if (kDebugMode)
        debugPrint(
            '[PaquetesService] getPaquete failed: ${res.statusCode} ${res.body}');
      return {
        'error': 'Status ${res.statusCode}',
        'body': res.body,
        'status': res.statusCode
      };
    } catch (e) {
      if (kDebugMode) debugPrint('[PaquetesService] exception: $e');
      return {'error': e.toString()};
    }
  }
}
