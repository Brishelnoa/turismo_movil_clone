import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

final _storage = FlutterSecureStorage();
const _resolvedKey = 'resolved_base_url';
const _resolvedRawKey = 'resolved_base_urls_raw';

/// Read candidate base URLs from env.
List<String> _candidateBases() {
  final raw = dotenv.env['BASE_URLS'];
  if (raw != null && raw.trim().isNotEmpty) {
    return raw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }
  final single = dotenv.env['BASE_URL'] ??
      const String.fromEnvironment('BASE_URL',
          defaultValue: 'http://10.0.2.2:8000');
  return [single];
}

Future<String?> _getCachedIfValid(List<String> candidates) async {
  final cached = await _storage.read(key: _resolvedKey);
  final raw = await _storage.read(key: _resolvedRawKey);
  final currentRaw = candidates.join(',');
  if (cached != null && raw == currentRaw) return cached;
  return null;
}

Future<void> _cacheResolved(String base, List<String> candidates) async {
  await _storage.write(key: _resolvedKey, value: base);
  await _storage.write(key: _resolvedRawKey, value: candidates.join(','));
}

/// Try a function against each candidate base until a network-level success occurs.
/// "Success" means the HTTP request reached the server (any status code). Network errors
/// (SocketException, TimeoutException) cause a retry with the next candidate.
Future<http.Response> _tryCandidates(
    Future<http.Response> Function(String base) attempt) async {
  final candidates = _candidateBases();
  if (candidates.isEmpty) throw Exception('No base URLs configured');

  final cached = await _getCachedIfValid(candidates);
  if (cached != null) {
    try {
      final resp = await attempt(cached).timeout(const Duration(seconds: 15));
      // reached server -> keep cached
      return resp;
    } on SocketException catch (_) {
      // fallthrough to try others
    } on TimeoutException catch (_) {}
    // if cached failed, continue to try candidates in order
  }

  for (final base in candidates) {
    try {
      final resp = await attempt(base).timeout(const Duration(seconds: 15));
      // network-level success, cache and return
      await _cacheResolved(base, candidates);
      return resp;
    } on SocketException catch (_) {
      // try next
      continue;
    } on TimeoutException catch (_) {
      continue;
    }
  }

  // If we get here, every candidate failed at network level -> throw
  throw SocketException('All base URLs unreachable: ${candidates.join(', ')}');
}

/// Public helper: GET a relative path (e.g., '/api/paquetes/')
Future<http.Response> getPath(String path,
    {Map<String, String>? headers}) async {
  return _tryCandidates((base) async {
    final uri = Uri.parse(base + path);
    return await http.get(uri, headers: headers);
  });
}

/// Public helper: POST to relative path with JSON body
Future<http.Response> postPath(String path,
    {Map<String, String>? headers, Object? body}) async {
  return _tryCandidates((base) async {
    final uri = Uri.parse(base + path);
    final h = headers ?? {'Content-Type': 'application/json'};
    final b = body is String ? body : jsonEncode(body);
    return await http.post(uri, headers: h, body: b);
  });
}

/// Public helper: PATCH to relative path with JSON body
Future<http.Response> patchPath(String path,
    {Map<String, String>? headers, Object? body}) async {
  return _tryCandidates((base) async {
    final uri = Uri.parse(base + path);
    final h = headers ?? {'Content-Type': 'application/json'};
    final b = body is String ? body : jsonEncode(body);
    return await http.patch(uri, headers: h, body: b);
  });
}

/// Public helper: DELETE to relative path
Future<http.Response> deletePath(String path,
    {Map<String, String>? headers}) async {
  return _tryCandidates((base) async {
    final uri = Uri.parse(base + path);
    return await http.delete(uri, headers: headers);
  });
}

/// Helper to get currently resolved base URL (if cached)
Future<String?> currentResolvedBase() async {
  return await _storage.read(key: _resolvedKey);
}
