import 'package:flutter/material.dart';
import '../../models/gasto_model.dart';
import 'nuevo_gasto_screen.dart';

/// Pantalla de edición de un gasto de obra existente.
/// Reutiliza [GastoFormScreen] precargado con los datos del gasto.
class EditarGastoScreen extends StatelessWidget {
  final Gasto gasto;

  const EditarGastoScreen({super.key, required this.gasto});

  @override
  Widget build(BuildContext context) {
    return GastoFormScreen(gastoToEdit: gasto);
  }
}
