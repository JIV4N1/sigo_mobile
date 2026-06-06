import 'package:flutter/material.dart';
import '../models/reporte_model.dart';

class ReporteCard extends StatelessWidget {
  final Reporte reporte;
  final VoidCallback onTap;

  const ReporteCard({
    Key? key,
    required this.reporte,
    required this.onTap,
  }) : super(key: key);

  String _tiempoTranscurrido(DateTime fecha) {
    final diferencia = DateTime.now().difference(fecha);
    if (diferencia.inDays > 0) return 'Enviado hace ${diferencia.inDays} días';
    if (diferencia.inHours > 0) return 'Enviado hace ${diferencia.inHours} horas';
    if (diferencia.inMinutes > 0) return 'Enviado hace ${diferencia.inMinutes} min';
    return 'Enviado hace un momento';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado: Proyecto y Chip de Estado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reporte.proyectoNombre,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A237E), // Azul oscuro
                          ),
                        ),
                        Text(
                          'Cód: ${reporte.proyectoCodigo}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  _buildEstadoChip(reporte.estado),
                ],
              ),
              const SizedBox(height: 12),
              
              // Información del Supervisor
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(reporte.supervisorFoto),
                    radius: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    reporte.supervisorNombre,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Detalles del Reporte
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${reporte.fecha.day}/${reporte.fecha.month}/${reporte.fecha.year}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    reporte.turno,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Categoría y Avance
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      reporte.categoria,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Avance: ${reporte.avance.toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Barra de progreso
              LinearProgressIndicator(
                value: reporte.avance / 100,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF6D00)), // Naranja
              ),
              const SizedBox(height: 12),

              // Descripción
              Text(
                reporte.descripcion,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 4),
              const Text(
                'Ver más',
                style: TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Fotos y Tiempo Transcurrido
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      ...reporte.fotos.take(3).map((foto) => Padding(
                            padding: const EdgeInsets.only(right: 4.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(foto, width: 40, height: 40, fit: BoxFit.cover),
                            ),
                          )),
                      if (reporte.fotos.length > 3)
                        Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('+${reporte.fotos.length - 3}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  Text(
                    _tiempoTranscurrido(reporte.fechaEnvio),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoChip(String estado) {
    Color bgColor;
    Color textColor;
    String text;

    switch (estado.toLowerCase()) {
      case 'aprobado':
        bgColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        text = 'Aprobado';
        break;
      case 'rechazado':
        bgColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        text = 'Rechazado';
        break;
      default:
        bgColor = Colors.amber[100]!;
        textColor = Colors.amber[900]!;
        text = 'Pendiente';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
