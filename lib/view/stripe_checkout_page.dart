import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class StripeCheckoutPage extends StatefulWidget {
  final String checkoutUrl;
  final String successUrl;

  const StripeCheckoutPage({
    Key? key,
    required this.checkoutUrl,
    required this.successUrl,
  }) : super(key: key);

  @override
  State<StripeCheckoutPage> createState() => _StripeCheckoutPageState();
}

class _StripeCheckoutPageState extends State<StripeCheckoutPage> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) async {
            // 🔹 Detectar éxito de pago
            if (url.startsWith(widget.successUrl)) {
              Navigator.pop(context, true); // éxito
            }
            if (url.contains("cancelado")) {
              Navigator.pop(context, false); // cancelado
            }
          },
          onPageFinished: (_) => setState(() => _loading = false),
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: const Text("Pago con Stripe"),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Center(child: CircularProgressIndicator(color: Colors.teal)),
        ],
      ),
    );
  }
}
