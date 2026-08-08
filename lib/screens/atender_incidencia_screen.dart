import 'dart:io';
import 'package:flutter/material.dart';
import '../models/issue_model.dart';
import '../models/report_model.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/incidencia_service.dart';
import '../widgets/photo_capture_grid.dart';
import '../widgets/status_chip.dart';

/// Formulario para registrar la atención de una incidencia: descripción de
/// la acción realizada, evidencia fotográfica opcional y comentario
/// adicional, con dos rutas de guardado (progreso o resuelta).
class AtenderIncidenciaScreen extends StatefulWidget {
  final Issue issue;

  const AtenderIncidenciaScreen({super.key, required this.issue});

  @override
  State<AtenderIncidenciaScreen> createState() => _AtenderIncidenciaScreenState();
}

class _AtenderIncidenciaScreenState extends State<AtenderIncidenciaScreen> {
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _comentarioController = TextEditingController();
  List<ReportPhoto> _photos = [];
  bool _isSaving = false;
  String? _descripcionError;

  @override
  void dispose() {
    _descripcionController.dispose();
    _comentarioController.dispose();
    super.dispose();
  }

  bool _validar() {
    final descripcionVacia = _descripcionController.text.trim().isEmpty;
    setState(() {
      _descripcionError = descripcionVacia ? 'Describe qué se hizo para atender la incidencia.' : null;
    });
    return !descripcionVacia;
  }

  Future<void> _guardar(String estado) async {
    if (!_validar()) return;

    setState(() => _isSaving = true);

    try {
      final files = _photos
          .where((p) => p.path.isNotEmpty)
          .map((p) => File(p.path))
          .toList();

      await IncidenciaService.atenderIncidencia(
        int.tryParse(widget.issue.id) ?? 0,
        descripcion: _descripcionController.text.trim(),
        estado: estado,
        fotos: files,
        comentario: _comentarioController.text.trim().isEmpty
            ? null
            : _comentarioController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.critical),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error inesperado al guardar la atención.'),
          backgroundColor: AppColors.critical,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final issue = widget.issue;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        title: Text(
          'Atender Incidencia #${issue.id}',
          style: const TextStyle(color: AppColors.textDark, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Resumen de la incidencia ────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    issue.title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  if (issue.projectName != null) ...[
                    const SizedBox(height: 4),
                    Text('Proyecto: ${issue.projectName}',
                        style: const TextStyle(color: AppColors.textMedium, fontSize: 13)),
                  ],
                  const SizedBox(height: 8),
                  Row(children: [
                    const Text('Estado actual: ',
                        style: TextStyle(color: AppColors.textMedium, fontSize: 13)),
                    StatusChip(status: issue.status),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Descripción de la acción ────────────────────────────────────────
            const Text('Descripción de la acción *',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('¿Qué se hizo para resolver la incidencia?',
                style: TextStyle(fontSize: 12, color: AppColors.textMedium)),
            const SizedBox(height: 8),
            TextField(
              controller: _descripcionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Ej: Se gestionó la compra de cemento...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                errorText: _descripcionError,
              ),
              onChanged: (_) {
                if (_descripcionError != null) setState(() => _descripcionError = null);
              },
            ),
            const SizedBox(height: 24),

            // ── Fotos de la solución ────────────────────────────────────────────
            const Text('Fotos de la solución (opcional)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            PhotoCaptureGrid(
              initialPhotos: _photos,
              onPhotosChanged: (photos) => setState(() => _photos = photos),
              maxPhotos: 6,
            ),
            const SizedBox(height: 24),

            // ── Comentario adicional ────────────────────────────────────────────
            const Text('Comentario adicional (opcional)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _comentarioController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Ej: Se coordina entrega para mañana...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              )
            ],
          ),
          child: Row(children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: const BorderSide(color: AppColors.accent),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _isSaving ? null : () => _guardar('en_progreso'),
                child: const Text('Guardar Progreso',
                    style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _isSaving ? null : () => _guardar('resuelta'),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Marcar como Resuelta',
                        style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
