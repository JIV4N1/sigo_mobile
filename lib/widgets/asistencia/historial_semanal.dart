import 'package:flutter/material.dart';
import '../../models/asistencia_model.dart';
import 'package:intl/intl.dart';

class HistorialSemanal extends StatelessWidget {
  final List<ResumenDia> historial;

  const HistorialSemanal({Key? key, required this.historial}) : super(key: key);

  Widget _buildStatusIcon(String estado) {
    switch (estado) {
      case 'Completo':
        return const Icon(Icons.check_circle, color: Colors.green, size: 20);
      case 'Incompleto':
        return const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20);
      default:
        return const Icon(Icons.cancel, color: Colors.red, size: 20);
    }
  }

  String _formatDuration(Duration duration) {
    if (duration == Duration.zero) return '--:--';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
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
                return InkWell(
                  onTap: () {
                    // Muestra detalle del día
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            _buildStatusIcon(dia.estado),
                            const SizedBox(width: 12),
                            Text(
                              DateFormat('E d', 'es').format(dia.fecha).toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.bold),
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
