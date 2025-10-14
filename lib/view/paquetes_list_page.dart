import 'package:flutter/material.dart';
import '../services/paquetes_service.dart';
import '../models/paquete.dart';
import '../widgets/paquete_card.dart';

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
      appBar: AppBar(title: const Text('Paquetes')),
      body: RefreshIndicator(
        onRefresh: () => _loadPage(reset: true),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : paquetes.isEmpty
                ? ListView(children: const [
                    SizedBox(height: 120),
                    Center(child: Text('No hay paquetes'))
                  ])
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: paquetes.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= paquetes.length)
                        return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(child: CircularProgressIndicator()));
                      final p = paquetes[index];
                      return PaqueteCard(
                          paquete: p,
                          onTap: () => Navigator.pushNamed(
                              context, '/PaqueteDetail',
                              arguments: p.id));
                    },
                  ),
      ),
    );
  }
}
