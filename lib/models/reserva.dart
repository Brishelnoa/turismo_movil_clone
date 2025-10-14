class Reserva {
  final int id;
  final String fecha;
  final String estado;
  final String total;
  final String moneda;
  final int numeroReprogramaciones;
  final Map<String, dynamic>? cupon;

  Reserva({
    required this.id,
    required this.fecha,
    required this.estado,
    required this.total,
    required this.moneda,
    required this.numeroReprogramaciones,
    this.cupon,
  });

  factory Reserva.fromJson(Map<String, dynamic> json) {
    return Reserva(
      id: json['id'] as int,
      fecha: json['fecha'] as String? ?? '',
      estado: json['estado'] as String? ?? '',
      total: json['total']?.toString() ?? '0',
      moneda: json['moneda'] as String? ?? '',
      numeroReprogramaciones: json['numero_reprogramaciones'] as int? ?? 0,
      cupon: json['cupon'] as Map<String, dynamic>?,
    );
  }

  String get fechaFormateada {
    try {
      final d = DateTime.parse(fecha);
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return fecha;
    }
  }
}
