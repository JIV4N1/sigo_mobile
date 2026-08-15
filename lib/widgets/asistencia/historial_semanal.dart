import 'package:flutter/material.dart';
import '../../models/asistencia_model.dart';
import '../../theme/app_colors.dart';
import 'package:intl/intl.dart';

class _EstadoInfo {
  final Color color;
  final IconData icono;
  final String label;

  const _EstadoInfo(this.color, this.icono, this.label);
}

class HistorialSemanal extends StatelessWidget {
  final List<ResumenDia> historial;

  const HistorialSemanal({Key? key, required this.historial}) : super(key: key);

  _EstadoInfo _estadoInfo(String estado) {
    switch (estado) {
      case 'Completo':
        return const _EstadoInfo(AppColors.success, Icons.check_circle, 'Completo');
      case 'Incompleto':
        return const _EstadoInfo(AppColors.warning, Icons.warning_amber_rounded, 'Incompleto');
      default:
        return const _EstadoInfo(AppColors.textMedium, Icons.remove_circle_outline, 'Sin registrar');
    }
  }

  String _formatFecha(DateTime fecha) {
    final texto = DateFormat('E d/MM', 'es').format(fecha);
    return texto[0].toUpperCase() + texto.substring(1);
  }

  String _formatDuration(Duration duration) {
    if (duration == Duration.zero) return 'Sin horas';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  void _mostrarDetalle(BuildContext context, ResumenDia dia) {
    final info = _estadoInfo(dia.estado);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat("EEEE d 'de' MMMM 'de' y", 'es').format(dia.fecha),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: info.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(info.icono, color: info.color, size: 18),
                  const SizedBox(width: 8),
                  Text(info.label, style: TextStyle(color: info.color, fontWeight: FontWeight.bold)),
                ]),
              ),
              const SizedBox(height: 16),
              Text(
                'Horas trabajadas: ${_formatDuration(dia.horasTrabajadas)}',
                style: const TextStyle(fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Historial Semanal',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: historial.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final dia = historial[index];
                final info = _estadoInfo(dia.estado);
                return InkWell(
                  onTap: () => _mostrarDetalle(context, dia),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: info.color.withOpacity(0.12),
                              child: Icon(info.icono, color: info.color, size: 16),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatFecha(dia.fecha),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  info.label,
                                  style: TextStyle(color: info.color, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              _formatDuration(dia.horasTrabajadas),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: dia.horasTrabajadas == Duration.zero ? Colors.grey : Colors.black,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
