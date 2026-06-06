import 'package:flutter/material.dart';

/// Servicio de navegación global.
/// Permite navegar desde fuera del árbol de widgets (ej: interceptor de 401).
class NavigationService {
  /// Clave global del Navigator raíz de la app.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Navega a una ruta con nombre, eliminando todo el historial previo.
  static void navigateAndRemoveAll(Widget page) {
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => page),
      (route) => false,
    );
  }
}
