import 'package:flutter/material.dart';

typedef CambioPestana = void Function(int indice);

class SelectorViajes extends StatelessWidget {
  const SelectorViajes({
    super.key,
    required this.indiceActual,
    required this.alCambiar,
  });

  final int indiceActual; // 0 = Pendientes, 1 = Pasados
  final CambioPestana alCambiar;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _opcion('Pendientes', 0, context),
          _opcion('Pasados', 1, context),
        ],
      ),
    );
  }

  Widget _opcion(String etiqueta, int indice, BuildContext context) {
    final bool seleccionado = indice == indiceActual;
    return Expanded(
      child: GestureDetector(
        onTap: () => alCambiar(indice),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: seleccionado ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            etiqueta,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: seleccionado ? Colors.black87 : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }
}
