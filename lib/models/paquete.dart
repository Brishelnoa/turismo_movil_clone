class Paquete {
  final int id;
  final String nombre;
  final String descripcion;
  final String duracion;
  final String precioBase;
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
    this.cuponesDisponibles = const [],
    this.precioTotalServicios,
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
            : null;

    return Paquete(
      id: (json['id'] is int)
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      nombre: json['nombre'] as String? ?? json['name'] as String? ?? '',
      descripcion: json['descripcion'] as String? ??
          json['description'] as String? ??
          '',
      duracion:
          json['duracion'] as String? ?? json['duration']?.toString() ?? '',
      precioBase:
          json['precio_base']?.toString() ?? json['price']?.toString() ?? '0',
      serviciosIncluidos: servicios,
      itinerario: itin,
      disponibilidad: (json['disponibilidad'] is Map)
          ? Map<String, dynamic>.from(json['disponibilidad'])
          : null,
      fechaInicio:
          json['fecha_inicio'] as String? ?? json['start_date'] as String?,
      fechaFin: json['fecha_fin'] as String? ?? json['end_date'] as String?,
      tipoDescuento:
          json['tipo_descuento'] as String? ?? json['tipo'] as String?,
      monto: json['monto']?.toString() ?? json['monto_descuento']?.toString(),
      cuponesDisponibles: cupones,
      precioTotalServicios: precioTotalServicios,
    );
  }

  // Precio a mostrar: preferir precio_total_servicios.total_usd, si no usar monto o precioBase
  String get displayPrice {
    try {
      final pts = precioTotalServicios;
      if (pts != null) {
        final total =
            pts['total_usd'] ?? pts['total'] ?? pts['total_usd']?.toString();
        if (total != null) return total.toString();
      }
    } catch (_) {}
    if (monto != null && monto!.isNotEmpty) return monto!;
    // fallback: buscar recursivamente en el objeto disponibilidad o en la estructura de servicios
    try {
      String? found;
      String? _findPriceInMap(dynamic node) {
        if (node == null) return null;
        try {
          if (node is Map) {
            for (final k in node.keys) {
              final lk = k.toString().toLowerCase();
              if ([
                'total_usd',
                'precio_usd',
                'precio_usd',
                'price',
                'monto',
                'total'
              ].contains(lk)) {
                final v = node[k];
                if (v != null) return v.toString();
              }
              final res = _findPriceInMap(node[k]);
              if (res != null) return res;
            }
          } else if (node is List) {
            for (final e in node) {
              final res = _findPriceInMap(e);
              if (res != null) return res;
            }
          }
        } catch (_) {}
        return null;
      }

      found = _findPriceInMap(disponibilidad) ??
          _findPriceInMap(serviciosIncluidos) ??
          _findPriceInMap(itinerario);
      if (found != null && found.isNotEmpty) return found;
    } catch (_) {}

    return precioBase;
  }
}
