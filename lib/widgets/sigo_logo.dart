import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Ícono de marca de SIGO: una grúa torre estilizada, referencia directa
/// al giro de construcción/gestión de obras de la app.
class SigoLogoMark extends StatelessWidget {
  final double size;
  final Color structureColor;
  final Color accentColor;

  const SigoLogoMark({
    super.key,
    this.size = 40,
    this.structureColor = AppColors.primary,
    this.accentColor = AppColors.accent,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CraneMarkPainter(
        structureColor: structureColor,
        accentColor: accentColor,
      ),
    );
  }
}

/// Badge cuadrado (radio consistente con la dirección "flat industrial")
/// que envuelve el [SigoLogoMark] en fondo blanco con borde de marca.
class SigoLogoBadge extends StatelessWidget {
  final double size;

  const SigoLogoBadge({super.key, this.size = 96});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.22),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      child: SigoLogoMark(size: size * 0.6),
    );
  }
}

class _CraneMarkPainter extends CustomPainter {
  final Color structureColor;
  final Color accentColor;

  _CraneMarkPainter({required this.structureColor, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    // Dibujado sobre un viewBox lógico de 64x64, escalado al tamaño real.
    final scale = size.width / 64;
    canvas.save();
    canvas.scale(scale, scale);

    final structure = Paint()
      ..color = structureColor
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final jib = Paint()
      ..color = structureColor
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final cable = Paint()
      ..color = accentColor
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Base del mástil.
    canvas.drawLine(const Offset(16, 52), const Offset(38, 52), structure);
    // Mástil.
    canvas.drawLine(const Offset(27, 52), const Offset(27, 12), structure);
    // Pluma (brazo largo a la derecha) y contrapluma (brazo corto a la izquierda).
    canvas.drawLine(const Offset(10, 12), const Offset(52, 12), jib);
    // Contrapeso.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(9, 8, 8, 8),
        const Radius.circular(1.5),
      ),
      Paint()..color = structureColor,
    );
    // Cable de izaje.
    canvas.drawLine(const Offset(48, 12), const Offset(48, 30), cable);
    // Gancho / carga suspendida — único acento de color.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(44, 30, 8, 8),
        const Radius.circular(1.5),
      ),
      Paint()..color = accentColor,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CraneMarkPainter oldDelegate) {
    return oldDelegate.structureColor != structureColor ||
        oldDelegate.accentColor != accentColor;
  }
}
