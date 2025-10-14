import 'package:flutter/material.dart';

import '../models/reserva.dart';
import '../services/reservas_service.dart';
import '../services/auth_service.dart';
import '../widgets/reserva_card.dart';

class MisReservasPage extends StatefulWidget {
  const MisReservasPage({Key? key}) : super(key: key);

  @override
  State<MisReservasPage> createState() => _MisReservasPageState();
}

class _MisReservasPageState extends State<MisReservasPage> {
  bool loading = true;
  List<Reserva> reservas = [];
  final ScrollController _scrollController = ScrollController();
  int _page = 1;
  final int _pageSize = 10;
  bool _loadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _cargarReservas();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _cargarReservas({bool reset = true}) async {
    if (reset) {
      _page = 1;
      _hasMore = true;
    }
    setState(() => loading = true);
    final resp =
        await ReservasService.getMisReservas(page: _page, pageSize: _pageSize);
    if (resp.containsKey('status') && resp['status'] == 401) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('No autorizado. Por favor inicia sesión de nuevo.')));
    } else if (resp.containsKey('reservas')) {
      final list = resp['reservas'] as List<dynamic>;

      // Intentar filtrar por 'cliente' en el JSON si está presente.
      List<Map<String, dynamic>> rawList = [];
      for (final e in list) {
        if (e is Map<String, dynamic>)
          rawList.add(e);
        else if (e is Map) rawList.add(Map<String, dynamic>.from(e));
      }

      try {
        final userId = await AuthService.getCurrentUserId();
        if (userId != null) {
          rawList = rawList.where((m) {
            final c = m['cliente'];
            if (c == null) return true; // si no viene, no filtramos aquí
            if (c is int) return c == userId;
            if (c is String) return int.tryParse(c) == userId;
            if (c is Map && c.containsKey('id')) {
              final v = c['id'];
              if (v is int) return v == userId;
              if (v is String) return int.tryParse(v) == userId;
            }
            return false;
          }).toList();
        }
      } catch (e) {
        // ignore
      }

      final loaded = rawList.map((e) => Reserva.fromJson(e)).toList();
      if (reset)
        reservas = loaded;
      else
        reservas.addAll(loaded);
      // comprobar paginación: si body tenía 'next' o menor que pageSize
      if (resp.containsKey('next')) {
        _hasMore = resp['next'] != null;
      } else {
        _hasMore = loaded.length >= _pageSize;
      }
    } else if (resp.isEmpty) {
      reservas = [];
    } else {
      final msg = resp['error'] ?? 'Error al cargar reservas';
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg.toString())));
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _loadingMore || loading) return;
    _loadingMore = true;
    _page += 1;
    await _cargarReservas(reset: false);
    _loadingMore = false;
    if (mounted) setState(() {});
  }

  Future<void> _cancelar(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Confirmar'),
        content: const Text('¿Deseas cancelar esta reserva?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(c).pop(false),
              child: const Text('No')),
          TextButton(
              onPressed: () => Navigator.of(c).pop(true),
              child: const Text('Sí')),
        ],
      ),
    );
    if (confirm != true) return;
    final res = await ReservasService.cancelarReserva(id);
    if (res['success'] == true) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Reserva cancelada')));
      await _cargarReservas();
    } else {
      final msg = res['error'] ?? 'Error al cancelar';
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Reservas')),
      body: RefreshIndicator(
        onRefresh: _cargarReservas,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : reservas.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(child: Text('No tienes reservas')),
                    ],
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: reservas.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= reservas.length) {
                        // indicador de carga
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final r = reservas[index];
                      return ReservaCard(
                        reserva: r,
                        onVerDetalle: () => _verDetalle(r.id),
                        onCancelar: () => _cancelar(r.id),
                      );
                    },
                  ),
      ),
    );
  }

  void _verDetalle(int id) async {
    // Por simplicidad, mostramos un diálogo con algunos detalles
    final resp = await ReservasService.getDetalleReserva(id);
    if (resp.containsKey('id')) {
      final reserva = Reserva.fromJson(resp.cast<String, dynamic>());
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: Text('Reserva #${reserva.id}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Fecha: ${reserva.fechaFormateada}'),
              Text('Estado: ${reserva.estado}'),
              Text('Total: ${reserva.total} ${reserva.moneda}'),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(c).pop(),
                child: const Text('Cerrar'))
          ],
        ),
      );
    } else {
      final msg = resp['error'] ?? 'Error al obtener detalle';
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg.toString())));
    }
  }
}
