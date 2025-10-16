import 'package:flutter/material.dart';
import '../services/paquetes_service.dart';
import '../models/paquete.dart';

class PaquetesListPage extends StatefulWidget {
  const PaquetesListPage({Key? key}) : super(key: key);

  @override
  State<PaquetesListPage> createState() => _PaquetesListPageState();
}

class _PaquetesListPageState extends State<PaquetesListPage> {
  List<Paquete> paquetes = [];
  bool loading = true;
  int _page = 1;
  final int _pageSize = 10;
  bool _hasMore = true;
  bool _loadingMore = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadPage();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) _loadMore();
    });
  }

  Future<void> _loadPage({bool reset = false}) async {
    if (reset) {
      _page = 1;
      _hasMore = true;
    }
    if (!mounted) return;
    setState(() => loading = true);
    final resp =
        await PaquetesService.listPaquetes(page: _page, pageSize: _pageSize);
    if (resp.containsKey('error')) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(resp['error'].toString())));
    } else if (resp.containsKey('results')) {
      final list = resp['results'] as List<dynamic>;
      final loaded =
          list.map((e) => Paquete.fromJson(e as Map<String, dynamic>)).toList();
      if (!mounted) return;
      setState(() {
        if (reset)
          paquetes = loaded;
        else
          paquetes.addAll(loaded);
        _hasMore = resp['next'] != null;
      });
    } else if (resp.containsKey('reservas')) {
      // por compatibilidad si backend usa key distinta
      final list = resp['reservas'] as List<dynamic>;
      final loaded =
          list.map((e) => Paquete.fromJson(e as Map<String, dynamic>)).toList();
      if (!mounted) return;
      setState(() {
        if (reset)
          paquetes = loaded;
        else
          paquetes.addAll(loaded);
        _hasMore = loaded.length >= _pageSize;
      });
    } else if (resp.isNotEmpty) {
      // caso lista en la raíz u otra estructura: intentar extraer la primera lista
      final list = resp.values
          .whereType<List>()
          .firstWhere((_) => true, orElse: () => []);
      final loaded =
          list.map((e) => Paquete.fromJson(e as Map<String, dynamic>)).toList();
      if (!mounted) return;
      setState(() {
        if (reset)
          paquetes = loaded;
        else
          paquetes.addAll(loaded);
        _hasMore = loaded.length >= _pageSize;
      });
    }
    if (!mounted) return;
    setState(() => loading = false);
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _loadingMore) return;
    _loadingMore = true;
    _page += 1;
    await _loadPage();
    _loadingMore = false;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paquetes Turísticos')),
      body: RefreshIndicator(
        onRefresh: () => _loadPage(reset: true),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : paquetes.isEmpty
                ? ListView(children: const [
                    SizedBox(height: 120),
                    Center(child: Text('No hay paquetes'))
                  ])
                : LayoutBuilder(builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    // Responsive breakpoints: 1 column (phone), 2 (small tablet), 3 (large tablet), 4 (desktop)
                    int crossAxisCount;
                    double targetTileHeight;
                    if (width < 520) {
                      crossAxisCount = 1;
                      targetTileHeight = 420.0;
                    } else if (width < 900) {
                      crossAxisCount = 2;
                      targetTileHeight = 380.0;
                    } else if (width < 1200) {
                      crossAxisCount = 3;
                      targetTileHeight = 360.0;
                    } else {
                      crossAxisCount = 4;
                      targetTileHeight = 340.0;
                    }

                    // compute childAspectRatio dynamically so each tile has enough height
                    final horizontalPadding =
                        24.0; // total horizontal padding in GridView (12 + 12)
                    final totalSpacing = (crossAxisCount - 1) * 12.0;
                    final itemWidth =
                        (width - horizontalPadding - totalSpacing) /
                            crossAxisCount;
                    final childAspectRatio = itemWidth / targetTileHeight;

                    return GridView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 18,
                        crossAxisSpacing: 12,
                        childAspectRatio: childAspectRatio,
                      ),
                      itemCount: paquetes.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= paquetes.length) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        final p = paquetes[index];
                        return _PaqueteGridCard(
                            paquete: p,
                            onTap: () => Navigator.pushNamed(
                                context, '/PaqueteDetail',
                                arguments: p.id));
                      },
                    );
                  }),
      ),
    );
  }
}

class _PaqueteGridCard extends StatelessWidget {
  final Paquete paquete;
  final VoidCallback? onTap;

  const _PaqueteGridCard({Key? key, required this.paquete, this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // servicios text intentionally omitted here; PaqueteGridCard keeps the UI compact

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            // cover image from backend (imagen_principal)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10)),
              child: SizedBox(
                height: 140,
                width: double.infinity,
                child: paquete.imagenPrincipal != null &&
                        paquete.imagenPrincipal!.isNotEmpty
                    ? Image.network(
                        paquete.imagenPrincipal!,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                              child: Icon(Icons.broken_image,
                                  size: 36, color: Colors.grey)),
                        ),
                      )
                    : Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                            child: Icon(Icons.image,
                                size: 48, color: Colors.grey)),
                      ),
              ),
            ),
            Flexible(
              fit: FlexFit.loose,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(paquete.nombre,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(paquete.descripcion,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 10),
                    Row(children: [
                      const Icon(Icons.schedule, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text(paquete.duracion,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey))),
                    ]),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(paquete.displayPrice,
                            style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold)),
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                              minWidth: 80, maxWidth: 120, minHeight: 36),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 8)),
                            onPressed: onTap,
                            child: const Text('Ver Detalles',
                                overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
