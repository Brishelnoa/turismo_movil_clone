import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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

    debugPrint('[StripeCheckout] 🚀 Inicializando WebView...');
    debugPrint('[StripeCheckout] - Checkout URL: ${widget.checkoutUrl}');
    debugPrint('[StripeCheckout] - Success URL: ${widget.successUrl}');

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) async {
            debugPrint('[StripeCheckout] 🌐 Navegando a: $url');

            // 🔹 Detectar éxito de pago
            if (url.startsWith(widget.successUrl) ||
                url.contains('/success') ||
                url.contains('/pago-exitoso')) {
              debugPrint('[StripeCheckout] ✅✅✅ PAGO EXITOSO DETECTADO');
              debugPrint('[StripeCheckout] - URL detectada: $url');
              debugPrint(
                  '[StripeCheckout] - Cerrando WebView y retornando true...');
              Navigator.pop(context, true); // éxito
              return;
            }

            // 🔹 Detectar cancelación
            if (url.contains('cancelado') ||
                url.contains('/cancel') ||
                url.contains('cancelled')) {
              debugPrint('[StripeCheckout] ❌❌❌ PAGO CANCELADO DETECTADO');
              debugPrint('[StripeCheckout] - URL detectada: $url');
              debugPrint(
                  '[StripeCheckout] - Cerrando WebView y retornando false...');
              Navigator.pop(context, false); // cancelado
              return;
            }
          },
          onPageFinished: (url) {
            debugPrint('[StripeCheckout] ✅ Página cargada: $url');
            setState(() => _loading = false);
          },
          onWebResourceError: (error) {
            debugPrint('[StripeCheckout] ❌ Error al cargar recurso:');
            debugPrint('[StripeCheckout] - Tipo: ${error.errorType}');
            debugPrint('[StripeCheckout] - Código: ${error.errorCode}');
            debugPrint('[StripeCheckout] - Descripción: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));

    debugPrint('[StripeCheckout] 📱 WebView configurado, cargando página...');
  }

  @override
  void dispose() {
    debugPrint('[StripeCheckout] 🔚 Cerrando WebView y liberando recursos');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        debugPrint('[StripeCheckout] ⬅️ Usuario presionó BACK');
        debugPrint('[StripeCheckout] - Retornando null (no completó pago)');
        return true; // Permite cerrar, retorna null automáticamente
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.teal,
          title: const Text("Pago con Stripe"),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              debugPrint('[StripeCheckout] ❌ Usuario presionó botón CERRAR');
              debugPrint(
                  '[StripeCheckout] - Retornando null (canceló sin completar)');
              Navigator.pop(context, null);
            },
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_loading)
              const Center(
                  child: CircularProgressIndicator(color: Colors.teal)),
          ],
        ),
      ),
    );
  }
}
