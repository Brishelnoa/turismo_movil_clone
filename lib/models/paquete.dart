import 'package:flutter/foundation.dart';

class Paquete {
  final int id;
  final String nombre;
  final String descripcion;
  final String duracion;
  final double precioBase;
  final String? moneda;
  // Normalizamos a lista de maps con keys como 'titulo' para facilitar UI
  final List<Map<String, dynamic>> serviciosIncluidos;
  // Cada item del itinerario se espera como Map con keys 'dia' y 'actividades'
  final List<Map<String, dynamic>> itinerario;
  final Map<String, dynamic>? disponibilidad;

  // campos adicionales según la guía del backend
  final String? fechaInicio;
  final String? fechaFin;
  final String? tipoDescuento;
  final String? monto;
  final String? imagenPrincipal;
  final List<Map<String, dynamic>> cuponesDisponibles;
  final Map<String, dynamic>? precioTotalServicios;

  Paquete({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.duracion,
    required this.precioBase,
    required this.serviciosIncluidos,
    required this.itinerario,
    this.disponibilidad,
    this.fechaInicio,
    this.fechaFin,
    this.tipoDescuento,
    this.monto,
    this.imagenPrincipal,
    this.cuponesDisponibles = const [],
    this.precioTotalServicios,
    this.moneda,
  });

  factory Paquete.fromJson(Map<String, dynamic> json) {
    // helper to normalize an activity/item into a Map with 'titulo'
    Map<String, dynamic> _normalizeToMap(dynamic item) {
      if (item == null) return {};
      if (item is Map<String, dynamic>) return Map<String, dynamic>.from(item);
      // if it's a string or other primitive, put it under 'titulo'
      return {'titulo': item.toString()};
    }

    // servicios_incluidos puede venir como lista de strings o lista de maps
    final rawServicios = json['servicios_incluidos'] ?? json['servicios'] ?? [];
    final servicios = <Map<String, dynamic>>[];
    if (rawServicios is List) {
      for (final s in rawServicios) {
        final m = _normalizeToMap(s);
        // intentar mapear 'title' a 'titulo' si viene en inglés
        if (m.containsKey('title') && !m.containsKey('titulo')) {
          m['titulo'] = m['title'];
        }
        servicios.add(m);
      }
    }

    // itinerario puede venir como lista de maps; cada actividad puede ser map o string
    final rawItinerario = json['itinerario'] ?? json['itinery'] ?? [];
    final itin = <Map<String, dynamic>>[];
    if (rawItinerario is List) {
      for (final item in rawItinerario) {
        if (item is Map<String, dynamic>) {
          final day = Map<String, dynamic>.from(item);
          // normalizar activities
          final rawActs = day['actividades'] ?? day['activities'] ?? [];
          final acts = <Map<String, dynamic>>[];
          if (rawActs is List) {
            for (final a in rawActs) {
              final am = _normalizeToMap(a);
              if (am.containsKey('title') && !am.containsKey('titulo')) {
                am['titulo'] = am['title'];
              }
              acts.add(am);
            }
          }
          day['actividades'] = acts;
          itin.add(day);
        } else {
          // if the item is a primitive, wrap it
          itin.add({'descripcion': item.toString()});
        }
      }
    }

    // cupones
    final rawCupones = json['cupones_disponibles'] ?? json['cupones'] ?? [];
    final cupones = <Map<String, dynamic>>[];
    if (rawCupones is List) {
      for (final c in rawCupones) {
        if (c is Map<String, dynamic>)
          cupones.add(Map<String, dynamic>.from(c));
      }
    }

    final precioTotalServicios = (json['precio_total_servicios'] is Map)
        ? Map<String, dynamic>.from(json['precio_total_servicios'])
        : (json['precio_total'] is Map)
            ? Map<String, dynamic>.from(json['precio_total'])
            : (json['precios'] is Map)
                ? Map<String, dynamic>.from(json['precios'])
                : null;

    // Helper to extract price amount and currency from varied backend shapes
    Map<String, String?> _extractPriceAndCurrency(Map<String, dynamic> src) {
      String? amount;
      String? currency;

      // common direct keys
      final candidates = [
        'price',
        'precio',
        'precio_base',
        'precio_base_bob',
        'price_usd',
        'precio_usd',
        'monto',
        'amount',
        'total',
        'precio_total'
      ];
      for (final k in candidates) {
        if (src.containsKey(k) && src[k] != null) {
          amount = src[k].toString();
          break;
        }
      }

      // nested common structures
      if (amount == null) {
        // look into precio_total_servicios or precio_total
        for (final key in [
          'precio_total_servicios',
          'precio_total',
          'price_info',
          'price_details'
        ]) {
          if (src.containsKey(key) && src[key] is Map) {
            final inner = Map<String, dynamic>.from(src[key]);
            for (final k in ['total', 'total_usd', 'amount', 'price']) {
              if (inner.containsKey(k) && inner[k] != null) {
                amount = inner[k].toString();
                break;
              }
            }
            if (amount != null) break;
          }
        }
      }

      // currency detection
      for (final k in ['currency', 'moneda', 'iso_currency', 'precio_moneda']) {
        if (src.containsKey(k) && src[k] != null) {
          currency = src[k].toString();
          break;
        }
      }
      if (currency == null && precioTotalServicios != null) {
        for (final k in ['currency', 'moneda', 'iso_currency']) {
          if (precioTotalServicios.containsKey(k) &&
              precioTotalServicios[k] != null) {
            currency = precioTotalServicios[k].toString();
            break;
          }
        }
      }

      // heuristic: if key names include 'usd' treat as USD
      if (currency == null) {
        if (src.keys.any((k) => k.toString().toLowerCase().contains('usd')))
          currency = 'USD';
        else if (src.keys
            .any((k) => k.toString().toLowerCase().contains('bob')))
          currency = 'BOB';
      }

      return {'amount': amount, 'currency': currency};
    }

    // Try to extract price from several places using backend field names as priority
    double parsedPrecioBase = 0.0;
    String? extractedCurrency;
    // precio_base comes as number (float) according to backend
    if (json.containsKey('precio_base') && json['precio_base'] != null) {
      parsedPrecioBase = (json['precio_base'] is num)
          ? (json['precio_base'] as num).toDouble()
          : double.tryParse(
                  json['precio_base'].toString().replaceAll(',', '.')) ??
              0.0;
    } else if (json.containsKey('precios') && json['precios'] is Map) {
      final p = Map<String, dynamic>.from(json['precios']);
      if (p.containsKey('precio_final_usd') && p['precio_final_usd'] != null) {
        parsedPrecioBase = (p['precio_final_usd'] is num)
            ? (p['precio_final_usd'] as num).toDouble()
            : double.tryParse(
                    p['precio_final_usd'].toString().replaceAll(',', '.')) ??
                0.0;
      } else if (p.containsKey('precio_original_usd') &&
          p['precio_original_usd'] != null) {
        parsedPrecioBase = (p['precio_original_usd'] is num)
            ? (p['precio_original_usd'] as num).toDouble()
            : double.tryParse(
                    p['precio_original_usd'].toString().replaceAll(',', '.')) ??
                0.0;
      } else if (p.containsKey('precio_bob') && p['precio_bob'] != null) {
        parsedPrecioBase = (p['precio_bob'] is num)
            ? (p['precio_bob'] as num).toDouble()
            : double.tryParse(
                    p['precio_bob'].toString().replaceAll(',', '.')) ??
                0.0;
        extractedCurrency = 'BOB';
      }
    } else if (json.containsKey('precio_bob') && json['precio_bob'] != null) {
      parsedPrecioBase = (json['precio_bob'] is num)
          ? (json['precio_bob'] as num).toDouble()
          : double.tryParse(
                  json['precio_bob'].toString().replaceAll(',', '.')) ??
              0.0;
      extractedCurrency = 'BOB';
    } else {
      // Fallback to previous heuristic search
      final r = _extractPriceAndCurrency(json);
      if (r['amount'] != null && r['amount']!.isNotEmpty) {
        parsedPrecioBase =
            double.tryParse(r['amount']!.replaceAll(',', '.')) ?? 0.0;
      }
      extractedCurrency = r['currency'];
    }

    // Debug: print parsed price and image when in debug mode
    if (kDebugMode) {
      try {
        debugPrint(
            '[Paquete.fromJson] id=${json['id']} parsedPrecioBase=$parsedPrecioBase (${parsedPrecioBase.runtimeType}) imagen=${(json['imagen_principal'] ?? json['imagen'])}');
      } catch (_) {}
    }

    return Paquete(
      id: (json['id'] is int)
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      nombre: (json['nombre'] ?? json['name'])?.toString() ?? '',
      descripcion:
          (json['descripcion'] ?? json['description'])?.toString() ?? '',
      duracion: (json['duracion'] ?? json['duration'])?.toString() ?? '',
      precioBase: parsedPrecioBase,
      serviciosIncluidos: servicios,
      itinerario: itin,
      disponibilidad: (json['disponibilidad'] is Map)
          ? Map<String, dynamic>.from(json['disponibilidad'])
          : null,
      fechaInicio: (json['fecha_inicio'] ?? json['start_date'])?.toString(),
      fechaFin: (json['fecha_fin'] ?? json['end_date'])?.toString(),
      tipoDescuento: (json['tipo_descuento'] ?? json['tipo'])?.toString(),
      monto: (json['monto'] ?? json['monto_descuento'])?.toString(),
      imagenPrincipal: (json['imagen_principal'] ?? json['imagen'])?.toString(),
      cuponesDisponibles: cupones,
      precioTotalServicios: precioTotalServicios,
      moneda: extractedCurrency ??
          json['moneda'] as String? ??
          json['currency'] as String?,
    );
  }

  // Precio a mostrar: preferir precio_total_servicios.total_usd, si no usar monto o precioBase
  String get displayPrice {
    // Prefer USD display. If backend provides USD price use it, else use precioBase as USD.
    try {
      final pts = precioTotalServicios;
      if (pts != null) {
        // prefer USD fields first
        final usdVal = pts['precio_final_usd'] ??
            pts['precio_original_usd'] ??
            pts['total_usd'];
        if (usdVal != null) {
          if (usdVal is num) {
            final numVal = usdVal.toDouble();
            final text = (numVal % 1 == 0)
                ? numVal.toInt().toString()
                : numVal.toStringAsFixed(2);
            return '\$ $text';
          }
          return '\$ ${usdVal.toString()}';
        }
        // if only precio_bob provided, we can show that as Bs.
        final bobVal = pts['precio_bob'] ?? pts['precio_bob'] ?? pts['total'];
        if (bobVal != null) {
          if (bobVal is num) {
            final numVal = bobVal.toDouble();
            final text = (numVal % 1 == 0)
                ? numVal.toInt().toString()
                : numVal.toStringAsFixed(2);
            return 'Bs. $text';
          }
          return 'Bs. ${bobVal.toString()}';
        }
      }
    } catch (_) {}

    // If monto (string) provided, return it raw
    if (monto != null && monto!.isNotEmpty) return monto!;

    // Fallback: treat precioBase as USD value
    try {
      final parsed = precioBase;
      final text = (parsed % 1 == 0)
          ? parsed.toInt().toString()
          : parsed.toStringAsFixed(2);
      return '\$ $text';
    } catch (_) {
      return precioBase.toString();
    }
  }

  /// Precio en BOB: si el backend entrega `precios.precio_bob` lo usamos, si no
  /// multiplicamos el precio USD por 7 (convención acordada).
  String get displayPriceBs {
    try {
      final pts = precioTotalServicios;
      if (pts != null &&
          pts.containsKey('precio_bob') &&
          pts['precio_bob'] != null) {
        final val = pts['precio_bob'];
        if (val is num) {
          final numVal = val.toDouble();
          final text = (numVal % 1 == 0)
              ? numVal.toInt().toString()
              : numVal.toStringAsFixed(2);
          return 'Bs. $text';
        }
        return 'Bs. ${val.toString()}';
      }
    } catch (_) {}

    // Fallback: convertir precioBase (USD) a BOB multiplicando por 7
    try {
      final converted = precioBase * 7.0;
      final text = (converted % 1 == 0)
          ? converted.toInt().toString()
          : converted.toStringAsFixed(2);
      return 'Bs. $text';
    } catch (_) {
      return 'Bs. ${precioBase.toString()}';
    }
  }
}
