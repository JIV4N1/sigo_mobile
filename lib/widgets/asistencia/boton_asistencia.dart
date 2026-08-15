import 'package:flutter/material.dart';

class BotonAsistencia extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final Color colorBase;
  final bool habilitado;
  final String? subtitulo;
  final VoidCallback onPressed;

  const BotonAsistencia({
    Key? key,
    required this.titulo,
    required this.icono,
    required this.colorBase,
    required this.habilitado,
    this.subtitulo,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: habilitado ? 1.0 : 0.5,
      child: Material(
        color: colorBase.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: habilitado ? onPressed : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: habilitado ? colorBase : Colors.grey,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icono, size: 34, color: habilitado ? colorBase : Colors.grey),
                const SizedBox(height: 8),
                Text(
                  titulo,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: habilitado ? colorBase : Colors.grey[700],
                  ),
                ),
                if (subtitulo != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitulo!,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: habilitado ? colorBase.withOpacity(0.8) : Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
