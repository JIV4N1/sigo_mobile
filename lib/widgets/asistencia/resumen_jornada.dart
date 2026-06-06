import 'package:flutter/material.dart';
import '../../models/asistencia_model.dart';
import 'package:intl/intl.dart';

class ResumenJornada extends StatelessWidget {
  final RegistroAsistencia registro;

  const ResumenJornada({Key? key, required this.registro}) : super(key: key);

  String _formatTime(DateTime? time) {
    if (time == null) return 'Pendiente';
    return DateFormat('hh:mm a').format(time);
  }

  String _formatDuration(Duration duration) {
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
              'Resumen de la Jornada',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
            ),
            const SizedBox(height: 16),
            _buildRow('Entrada', _formatTime(registro.entrada), Colors.green),
            const Divider(),
            _buildRow('Inicio comida', _formatTime(registro.inicioComida), Colors.orange),
            const Divider(),
            _buildRow('Fin comida', _formatTime(registro.finComida), Colors.blue),
            const Divider(),
            _buildRow('Salida', _formatTime(registro.salida), Colors.red),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total horas', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('Horas extra', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatDuration(registro.horasTrabajadas),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1A237E)),
                      ),
                      const SizedBox(height: 4),
                      const Text('0h 00m', style: TextStyle(color: Colors.grey)), // Simulado
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.circle, size: 12, color: color),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.black87)),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: value == 'Pendiente' ? Colors.grey : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
