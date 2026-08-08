import 'package:flutter/material.dart';

class AppColors {
  // Primarios y acentos (usados por las pantallas ya migradas y no migradas)
  static const Color primary = Color(0xFF1A237E); // Azul oscuro
  static const Color primaryLight = Color(0xFF3949AB); // Azul medio (variante clara/modo oscuro)
  static const Color accent = Color(0xFFFF6D00); // Naranja construcción
  static const Color accentLight = Color(0xFFFF9100); // Naranja claro

  // Semántica (compartida por ambos modos)
  static const Color success = Color(0xFF2E7D32); // Verde (A Tiempo)
  static const Color warning = Color(0xFFF57F17); // Ámbar (Retrasado)
  static const Color critical = Color(0xFFC62828); // Rojo (Crítico) — alias de error
  static const Color error = critical;
  static const Color info = Color(0xFF3B82F6);

  // Superficies — modo claro (nombres históricos, no tocar: usados en ~26 pantallas)
  static const Color surface = Color(0xFFFFFFFF); // Blanco
  static const Color surfaceLight = Color(0xFFFAFAFA); // Gris muy claro (para cards o áreas secundarias)
  static const Color background = Color(0xFFF5F5F5); // Fondo de la app

  // Texto e Iconos — modo claro (nombres históricos, no tocar)
  static const Color textDark = Color(0xFF212121);
  static const Color textMedium = Color(0xFF757575);
  static const Color border = Color(0xFFE0E0E0);

  // ─── Modo oscuro (nombres nuevos y explícitos para no chocar con los de arriba) ──
  static const Color backgroundDarkMode = Color(0xFF121212);
  static const Color surfaceDarkMode = Color(0xFF1E1E2E);
  static const Color textOnDarkPrimary = Color(0xFFE8E8E8);
  static const Color textOnDarkSecondary = Color(0xFF9CA3AF);
  static const Color borderDarkMode = Color(0xFF33333F);
}
