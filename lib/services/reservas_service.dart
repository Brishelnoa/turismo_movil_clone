import 'dart:convert';

// http is used internally by network helpers; avoid direct http.* usage in this service
import 'package:flutter/foundation.dart';

import 'auth_service.dart';
import 'network.dart';

/// Servicio para consumir los endpoints de Reservas descritos en la guía.
///
/// Usa `AuthService.getAccessToken()` para obtener el token y lo incluye en
/// el header `Authorization: Bearer <token>`.
class ReservasService {
  // This service delegates URL resolution to lib/services/network.dart

  /// Construye headers con el token actual
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

  /// Convierte un map de filtros a query string
  static String _encodeQueryParameters(Map<String, dynamic>? params) {
    if (params == null || params.isEmpty) return '';
    final filtered = params.entries
        .where((e) => e.value != null && e.value.toString().isNotEmpty)
        .map((e) =>
            '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value.toString())}');
    return filtered.join('&');
  }

  /// GET /api/reservas/mis_reservas/?...
  static Future<Map<String, dynamic>> getMisReservas({
    Map<String, dynamic>? filtros,
    int? page,
    int? pageSize,
  }) async {
    final merged = <String, dynamic>{};
    if (filtros != null) merged.addAll(filtros);
    if (page != null) merged['page'] = page;
    if (pageSize != null) merged['page_size'] = pageSize;
    final qp = _encodeQueryParameters(merged);
    // relative path used below when calling getPath
    try {
      final headers = await _getHeaders();
      if (kDebugMode)
        debugPrint(
            '[ReservasService] GET /api/reservas/mis_reservas/${qp.isNotEmpty ? '?$qp' : ''}');
      final res = await getPath(
          '/api/reservas/mis_reservas/${qp.isNotEmpty ? '?$qp' : ''}',
          headers: headers);
      if (kDebugMode)
        debugPrint('[ReservasService] Response ${res.statusCode}: ${res.body}');
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        // Normalizar distintos formatos que el backend puede devolver:
        // - {'reservas': [...], ...}
        // - {'count':..., 'results': [...]} (DRF pagination)
        // - [...] (lista en la raíz)
        if (body is Map<String, dynamic>) {
          if (body.containsKey('reservas') && body['reservas'] is List) {
            return body;
          }
          if (body.containsKey('results') && body['results'] is List) {
            // devolver con key 'reservas' para compatibilidad con la UI
            final meta = Map<String, dynamic>.from(body)..remove('results');
            return {'reservas': body['results'], ...meta};
          }
          // mapa sin keys esperadas: devolver según estructura original
          return body.cast<String, dynamic>();
        }
        if (body is List) {
          return {'reservas': body};
        }
        // unexpected body
        return {'reservas': [], 'raw': body};
      }

      if (res.statusCode == 401) {
        if (kDebugMode)
          debugPrint(
              '[ReservasService] Unauthorized (401) - token may be missing/expired');
        return {'error': 'Unauthorized', 'status': 401, 'body': res.body};
      }

      // si la ruta específica no existe en el backend, intentar fallback a /api/reservas/
      if (res.statusCode == 404) {
        final fallbackUrl =
            Uri.parse('/api/reservas/${qp.isNotEmpty ? '?$qp' : ''}');
        if (kDebugMode)
          debugPrint(
              '[ReservasService] mis_reservas not found, trying fallback $fallbackUrl');
        final fres = await getPath(
            '/api/reservas/${qp.isNotEmpty ? '?$qp' : ''}',
            headers: headers);
        if (kDebugMode)
          debugPrint(
              '[ReservasService] Fallback Response ${fres.statusCode}: ${fres.body}');
        if (fres.statusCode == 200) {
          final fbody = jsonDecode(fres.body);
          if (fbody is Map<String, dynamic>) {
            if (fbody.containsKey('results') && fbody['results'] is List) {
              final meta = Map<String, dynamic>.from(fbody)..remove('results');
              return {'reservas': fbody['results'], ...meta};
            }
            if (fbody.containsKey('reservas') && fbody['reservas'] is List)
              return fbody;
            return fbody.cast<String, dynamic>();
          }
          if (fbody is List) return {'reservas': fbody};
          return {'reservas': [], 'raw': fbody};
        }
        return {
          'error': 'Status ${res.statusCode}',
          'body': res.body,
          'status': res.statusCode
        };
      }

      if (kDebugMode)
        debugPrint(
            '[ReservasService] getMisReservas failed: ${res.statusCode} ${res.body}');
      return {
        'error': 'Status ${res.statusCode}',
        'body': res.body,
        'status': res.statusCode
      };
    } catch (e) {
      if (kDebugMode)
        debugPrint('[ReservasService] getMisReservas exception: $e');
      return {'error': e.toString()};
    }
  }

  /// GET /api/reservas/reservas_activas/
  static Future<Map<String, dynamic>> getReservasActivas() async {
    // relative path used below when calling getPath
    try {
      final headers = await _getHeaders();
      if (kDebugMode)
        debugPrint('[ReservasService] GET /api/reservas/reservas_activas/');
      final res =
          await getPath('/api/reservas/reservas_activas/', headers: headers);
      if (kDebugMode)
        debugPrint('[ReservasService] Response ${res.statusCode}: ${res.body}');
      if (res.statusCode == 200)
        return jsonDecode(res.body) as Map<String, dynamic>;
      if (kDebugMode)
        debugPrint(
            '[ReservasService] getReservasActivas failed: ${res.statusCode} ${res.body}');
      return {'error': 'Status ${res.statusCode}', 'body': res.body};
    } catch (e) {
      if (kDebugMode)
        debugPrint('[ReservasService] getReservasActivas exception: $e');
      return {'error': e.toString()};
    }
  }

  /// GET /api/reservas/historial_completo/
  static Future<Map<String, dynamic>> getHistorialCompleto() async {
    // relative path used below when calling getPath
    try {
      final headers = await _getHeaders();
      final res =
          await getPath('/api/reservas/historial_completo/', headers: headers);
      if (res.statusCode == 200)
        return jsonDecode(res.body) as Map<String, dynamic>;
      if (kDebugMode)
        debugPrint(
            '[ReservasService] getHistorialCompleto failed: ${res.statusCode} ${res.body}');
      return {'error': 'Status ${res.statusCode}', 'body': res.body};
    } catch (e) {
      if (kDebugMode)
        debugPrint('[ReservasService] getHistorialCompleto exception: $e');
      return {'error': e.toString()};
    }
  }

  /// GET /api/reservas/{id}/
  static Future<Map<String, dynamic>> getDetalleReserva(int id) async {
    // relative path used below when calling getPath
    try {
      final headers = await _getHeaders();
      final res = await getPath('/api/reservas/$id/', headers: headers);
      if (res.statusCode == 200)
        return jsonDecode(res.body) as Map<String, dynamic>;
      if (kDebugMode)
        debugPrint(
            '[ReservasService] getDetalleReserva failed: ${res.statusCode} ${res.body}');
      return {'error': 'Status ${res.statusCode}', 'body': res.body};
    } catch (e) {
      if (kDebugMode)
        debugPrint('[ReservasService] getDetalleReserva exception: $e');
      return {'error': e.toString()};
    }
  }

  /// PATCH /api/reservas/{id}/  (body: { estado: 'CANCELADA' })
  static Future<Map<String, dynamic>> cancelarReserva(int id) async {
    // relative path used below when calling patchPath
    try {
      final headers = await _getHeaders();
      final res = await patchPath('/api/reservas/$id/',
          headers: headers, body: {'estado': 'CANCELADA'});
      if (res.statusCode == 200 || res.statusCode == 204)
        return {'success': true};
      if (kDebugMode)
        debugPrint(
            '[ReservasService] cancelarReserva failed: ${res.statusCode} ${res.body}');
      return {'error': 'Status ${res.statusCode}', 'body': res.body};
    } catch (e) {
      if (kDebugMode)
        debugPrint('[ReservasService] cancelarReserva exception: $e');
      return {'error': e.toString()};
    }
  }

  /// POST /api/reservas/  - Crear reserva (estado PENDIENTE)
  /// payload: see backend docs
  static Future<Map<String, dynamic>> createReserva(
      Map<String, dynamic> payload) async {
    // relative path used below when calling postPath
    try {
      final headers = await _getHeaders();
      // si no se envía cliente_id, intentar inferirlo del user almacenado
      if (!payload.containsKey('cliente_id')) {
        final uid = await AuthService.getCurrentUserId();
        if (uid != null) payload['cliente_id'] = uid;
      }
      if (kDebugMode)
        debugPrint(
            '[ReservasService] POST /api/reservas/ -> payload: ${jsonEncode(payload)}');
      final res =
          await postPath('/api/reservas/', headers: headers, body: payload);
      if (kDebugMode)
        debugPrint('[ReservasService] Response ${res.statusCode}: ${res.body}');
      if (res.statusCode == 201)
        return jsonDecode(res.body) as Map<String, dynamic>;
      if (kDebugMode)
        debugPrint(
            '[ReservasService] createReserva failed: ${res.statusCode} ${res.body}');
      return {'error': 'Status ${res.statusCode}', 'body': res.body};
    } catch (e) {
      if (kDebugMode)
        debugPrint('[ReservasService] createReserva exception: $e');
      return {'error': e.toString()};
    }
  }

  /// POST /api/visitantes/ - Crear visitante
  static Future<Map<String, dynamic>> createVisitante(
      Map<String, dynamic> payload) async {
    // relative path used below when calling postPath
    try {
      final headers = await _getHeaders();
      final res =
          await postPath('/api/visitantes/', headers: headers, body: payload);
      if (res.statusCode == 201)
        return jsonDecode(res.body) as Map<String, dynamic>;
      if (kDebugMode)
        debugPrint(
            '[ReservasService] createVisitante failed: ${res.statusCode} ${res.body}');
      return {'error': 'Status ${res.statusCode}', 'body': res.body};
    } catch (e) {
      if (kDebugMode)
        debugPrint('[ReservasService] createVisitante exception: $e');
      return {'error': e.toString()};
    }
  }

  /// POST /api/reserva-visitantes/ - Asociar visitante a reserva
  /// payload: { "reserva": <id>, "visitante": <id> }
  static Future<Map<String, dynamic>> asociarVisitante(
      int reservaId, int visitanteId) async {
    // relative path used below when calling postPath
    try {
      final headers = await _getHeaders();
      // Attempt 1: common payload keys (reserva, visitante)
      final payload1 = {'reserva': reservaId, 'visitante': visitanteId};
      if (kDebugMode)
        debugPrint(
            '[ReservasService] asociarVisitante attempt 1 payload: ${jsonEncode(payload1)}');
      var res = await postPath('/api/reserva-visitantes/',
          headers: headers, body: payload1);
      if (kDebugMode)
        debugPrint(
            '[ReservasService] asociarVisitante attempt 1 response: ${res.statusCode} ${res.body}');
      if (res.statusCode == 201)
        return jsonDecode(res.body) as Map<String, dynamic>;

      // Attempt 2: backend may expect *_id keys
      final payload2 = {'reserva_id': reservaId, 'visitante_id': visitanteId};
      if (kDebugMode) {
        debugPrint(
            '[ReservasService] asociarVisitante attempt 2 payload: ${jsonEncode(payload2)}');
        debugPrint(
            '[ReservasService] asociarVisitante request headers: $headers');
      }
      res = await postPath('/api/reserva-visitantes/',
          headers: headers, body: payload2);
      if (kDebugMode)
        debugPrint(
            '[ReservasService] asociarVisitante attempt 2 response: ${res.statusCode} ${res.body}');
      if (res.statusCode == 201)
        return jsonDecode(res.body) as Map<String, dynamic>;
      // Attempt 3: try combined payload (both variants)
      final payloadCombined = {
        'reserva': reservaId,
        'visitante': visitanteId,
        'reserva_id': reservaId,
        'visitante_id': visitanteId
      };
      if (kDebugMode)
        debugPrint(
            '[ReservasService] asociarVisitante attempt 3 combined payload: ${jsonEncode(payloadCombined)}');
      res = await postPath('/api/reserva-visitantes/',
          headers: headers, body: payloadCombined);
      if (kDebugMode)
        debugPrint(
            '[ReservasService] asociarVisitante attempt 3 response: ${res.statusCode} ${res.body}');
      if (res.statusCode == 201)
        return jsonDecode(res.body) as Map<String, dynamic>;

      // Attempt 4: try stringified ids (some serializers parse strings)
      final payload4 = {
        'reserva_id': reservaId.toString(),
        'visitante_id': visitanteId.toString()
      };
      if (kDebugMode)
        debugPrint(
            '[ReservasService] asociarVisitante attempt 4 payload: ${jsonEncode(payload4)}');
      res = await postPath('/api/reserva-visitantes/',
          headers: headers, body: payload4);
      if (kDebugMode)
        debugPrint(
            '[ReservasService] asociarVisitante attempt 4 response: ${res.statusCode} ${res.body}');
      if (res.statusCode == 201)
        return jsonDecode(res.body) as Map<String, dynamic>;

      // Attempt 4: try form-urlencoded body (some endpoints accept form data)
      final headersForm = Map<String, String>.from(headers);
      headersForm['Content-Type'] = 'application/x-www-form-urlencoded';
      final formBody =
          'reserva_id=${Uri.encodeQueryComponent(reservaId.toString())}&visitante_id=${Uri.encodeQueryComponent(visitanteId.toString())}';
      if (kDebugMode)
        debugPrint(
            '[ReservasService] asociarVisitante attempt 4 form body: $formBody');
      res = await postPath('/api/reserva-visitantes/',
          headers: headersForm, body: formBody);
      if (kDebugMode)
        debugPrint(
            '[ReservasService] asociarVisitante attempt 4 response: ${res.statusCode} ${res.body}');
      if (res.statusCode == 201)
        return jsonDecode(res.body) as Map<String, dynamic>;

      if (kDebugMode)
        debugPrint(
            '[ReservasService] asociarVisitante all attempts failed: ${res.statusCode} ${res.body}');
      return {'error': 'Status ${res.statusCode}', 'body': res.body};
    } catch (e) {
      if (kDebugMode)
        debugPrint('[ReservasService] asociarVisitante exception: $e');
      return {'error': e.toString()};
    }
  }

  /// POST /api/pagos/ - Registrar pago
  static Future<Map<String, dynamic>> createPago(
      Map<String, dynamic> payload) async {
    // relative path used below when calling postPath
    try {
      final headers = await _getHeaders();
      final res =
          await postPath('/api/pagos/', headers: headers, body: payload);
      if (res.statusCode == 201)
        return jsonDecode(res.body) as Map<String, dynamic>;
      if (kDebugMode)
        debugPrint(
            '[ReservasService] createPago failed: ${res.statusCode} ${res.body}');
      return {'error': 'Status ${res.statusCode}', 'body': res.body};
    } catch (e) {
      if (kDebugMode) debugPrint('[ReservasService] createPago exception: $e');
      return {'error': e.toString()};
    }
  }

  /// DELETE /api/reservas/{id}/
  static Future<bool> deleteReserva(int id) async {
    // relative path used below when calling deletePath
    try {
      final headers = await _getHeaders();
      final res = await deletePath('/api/reservas/$id/', headers: headers);
      return res.statusCode == 204 || res.statusCode == 200;
    } catch (e) {
      if (kDebugMode)
        debugPrint('[ReservasService] deleteReserva exception: $e');
      return false;
    }
  }

  /// DELETE /api/visitantes/{id}/
  static Future<bool> deleteVisitante(int id) async {
    // relative path used below when calling deletePath
    try {
      final headers = await _getHeaders();
      final res = await deletePath('/api/visitantes/$id/', headers: headers);
      return res.statusCode == 204 || res.statusCode == 200;
    } catch (e) {
      if (kDebugMode)
        debugPrint('[ReservasService] deleteVisitante exception: $e');
      return false;
    }
  }

  /// DELETE /api/reserva-visitantes/{id}/
  static Future<bool> deleteReservaVisitante(int id) async {
    // relative path used below when calling deletePath
    try {
      final headers = await _getHeaders();
      final res =
          await deletePath('/api/reserva-visitantes/$id/', headers: headers);
      return res.statusCode == 204 || res.statusCode == 200;
    } catch (e) {
      if (kDebugMode)
        debugPrint('[ReservasService] deleteReservaVisitante exception: $e');
      return false;
    }
  }

  /// Orquestador: crea reserva + visitantes + asociaciones + pago (opcional).
  /// Hace rollback de forma "best-effort" si algo falla (intenta borrar lo creado).
  static Future<Map<String, dynamic>> createReservaCompleta({
    required Map<String, dynamic> reservaPayload,
    List<Map<String, dynamic>> visitantes = const [],
    Map<String, dynamic>? pagoPayload,
    int? paqueteId,
  }) async {
    int? reservaId;
    final List<int> visitantesCreados = [];
    final List<int> asociacionesCreadas = [];

    try {
      // si se indica paqueteId, anexarlo al payload
      if (paqueteId != null) {
        reservaPayload['paquete'] = paqueteId;
      }

      // 1) crear reserva
      final rResp = await createReserva(reservaPayload);
      if (rResp.containsKey('id')) {
        reservaId = rResp['id'] as int;
      } else {
        return {'error': 'Failed to create reserva', 'body': rResp};
      }

      // 2) crear visitantes y asociarlos
      for (final v in visitantes) {
        // client-side validation: required visitante fields per backend
        final missing = <String>[];
        if ((v['nombre'] ?? '').toString().isEmpty) missing.add('nombre');
        if ((v['apellido'] ?? '').toString().isEmpty) missing.add('apellido');
        if ((v['fecha_nac'] ?? '').toString().isEmpty) missing.add('fecha_nac');
        if ((v['nacionalidad'] ?? '').toString().isEmpty)
          missing.add('nacionalidad');
        if ((v['nro_doc'] ?? '').toString().isEmpty) missing.add('nro_doc');
        if (missing.isNotEmpty) {
          throw Exception(
              'Visitante payload missing fields: ${missing.join(', ')}');
        }

        final vResp = await createVisitante(v);
        if (vResp.containsKey('id')) {
          final vid = vResp['id'] as int;
          visitantesCreados.add(vid);
          final aResp = await asociarVisitante(reservaId, vid);
          if (aResp.containsKey('id')) {
            asociacionesCreadas.add(aResp['id'] as int);
          } else {
            throw Exception('Failed to asociar visitante: $aResp');
          }
        } else {
          throw Exception('Failed to create visitante: $vResp');
        }
      }

      // 3) crear pago (opcional)
      Map<String, dynamic>? pagoResp;
      if (pagoPayload != null) {
        // asegurarse que el payload tenga la reserva
        pagoPayload['reserva'] = reservaId;
        pagoResp = await createPago(pagoPayload);
        if (pagoResp.containsKey('id') == false) {
          throw Exception('Failed to create pago: $pagoResp');
        }
      }

      // éxito
      return {
        'success': true,
        'reserva': rResp,
        'visitantes': visitantesCreados,
        'asociaciones': asociacionesCreadas,
        if (pagoResp != null) 'pago': pagoResp,
      };
    } catch (e) {
      // rollback best-effort
      if (kDebugMode)
        debugPrint('[ReservasService] createReservaCompleta error: $e');
      // intentar borrar asociaciones
      for (final aid in asociacionesCreadas) {
        await deleteReservaVisitante(aid);
      }
      // intentar borrar visitantes creados
      for (final vid in visitantesCreados) {
        await deleteVisitante(vid);
      }
      // intentar borrar reserva
      if (reservaId != null) {
        await deleteReserva(reservaId);
      }

      return {'error': e.toString()};
    }
  }
}
