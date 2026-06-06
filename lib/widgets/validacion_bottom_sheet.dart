import 'package:flutter/material.dart';
import '../models/reporte_model.dart';

class ValidacionBottomSheet extends StatefulWidget {
  final Reporte reporte;
  final Function(String, String) onValidar; // (estado, notas)

  const ValidacionBottomSheet({
    Key? key,
    required this.reporte,
    required this.onValidar,
  }) : super(key: key);

  @override
  State<ValidacionBottomSheet> createState() => _ValidacionBottomSheetState();
}

class _ValidacionBottomSheetState extends State<ValidacionBottomSheet> {
  final TextEditingController _notasController = TextEditingController();
  bool _isSubmitting = false;

  void _submitValidation(String estado) {
    setState(() {
      _isSubmitting = true;
    });
    
    // Simulamos un retraso de red
    Future.delayed(const Duration(seconds: 1), () {
      widget.onValidar(estado, _notasController.text);
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _notasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // Indicador de arrastre
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Título
              const Text(
                'Validar Reporte',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                ),
              ),
              const SizedBox(height: 16),
              
              // Contenido Scrollable
              Expanded(
                child: ListView(
                  controller: controller,
                  children: [
                    // Detalles del reporte
                    _buildDetailRow('Proyecto:', widget.reporte.proyectoNombre),
                    _buildDetailRow('Supervisor:', widget.reporte.supervisorNombre),
                    _buildDetailRow('Fecha:', '${widget.reporte.fecha.day}/${widget.reporte.fecha.month}/${widget.reporte.fecha.year}'),
                    _buildDetailRow('Turno:', widget.reporte.turno),
                    _buildDetailRow('Categoría:', widget.reporte.categoria),
                    _buildDetailRow('Avance:', '${widget.reporte.avance.toStringAsFixed(0)}%'),
                    
                    const SizedBox(height: 16),
                    const Text(
                      'Descripción del trabajo:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(widget.reporte.descripcion),
                    const SizedBox(height: 24),

                    // Galería de fotos (Simulada para visualización, idealmente usar PhotoView en pantalla completa)
                    const Text(
                      'Evidencia Fotográfica:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.reporte.fotos.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                widget.reporte.fotos[index],
                                width: 120,
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Notas de validación
                    TextField(
                      controller: _notasController,
                      decoration: InputDecoration(
                        labelText: 'Notas de validación (opcional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
                        ),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              
              // Botones de acción
              if (_isSubmitting)
                const Center(child: CircularProgressIndicator())
              else
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _submitValidation('aprobado'),
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text('Aprobar Reporte', style: TextStyle(color: Colors.white, fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _submitValidation('rechazado'),
                        icon: const Icon(Icons.close, color: Colors.red),
                        label: const Text('Rechazar Reporte', style: TextStyle(color: Colors.red, fontSize: 16)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
