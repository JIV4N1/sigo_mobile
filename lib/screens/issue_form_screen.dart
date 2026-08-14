import 'dart:io';
import 'package:flutter/material.dart';
import '../models/project_model.dart';
import '../models/report_model.dart'; // For ReportPhoto
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../services/incidencia_service.dart';
import '../widgets/photo_capture_grid.dart';

class IssueFormScreen extends StatefulWidget {
  final Project? initialProject;

  const IssueFormScreen({super.key, this.initialProject});

  @override
  State<IssueFormScreen> createState() => _IssueFormScreenState();
}

class _IssueFormScreenState extends State<IssueFormScreen> {
  // Datos del formulario
  Project? _selectedProject;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  
  String? _selectedCategory;
  String? _selectedSeverity;
  
  bool _includeGps = false;
  List<ReportPhoto> _photos = [];

  // Estado UI
  bool _isSaving = false;
  bool _isLoadingProjects = true;
  List<Project> _availableProjects = [];

  @override
  void initState() {
    super.initState();
    _loadProjects();
    if (widget.initialProject != null) {
      _selectedProject = widget.initialProject;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoadingProjects = true);
    try {
      final response = await ApiService.get(ApiConfig.proyectos);
      final rawData = response['data'];
      List<dynamic> list;
      if (rawData is List) {
        list = rawData;
      } else if (rawData is Map && rawData.containsKey('data')) {
        list = rawData['data'] as List<dynamic>? ?? [];
      } else {
        list = [];
      }

      final projects = list
          .map((e) => Project.fromJson(e as Map<String, dynamic>))
          .toList();

      if (!mounted) return;
      setState(() {
        _availableProjects = projects;
        _isLoadingProjects = false;
        if (widget.initialProject != null && _selectedProject == null) {
          _selectedProject = projects
              .where((p) => p.id == widget.initialProject!.id)
              .firstOrNull;
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingProjects = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudieron cargar los proyectos. Intenta de nuevo.')),
        );
      }
    }
  }

  bool _isFormValid() {
    return _selectedProject != null &&
        _titleController.text.trim().isNotEmpty &&
        _descController.text.trim().length >= 20 &&
        _selectedCategory != null &&
        _selectedSeverity != null;
  }

  String _getApiCategory(String category) {
    switch (category) {
      case 'Seguridad': return 'seguridad';
      case 'Falta de Material': return 'falta_material';
      case 'Falla de Equipo': return 'falla_equipo';
      case 'Clima': return 'clima';
      case 'Otro': return 'otro';
      default: return 'otro';
    }
  }

  String _getApiSeverity(String severity) {
    switch (severity) {
      case 'Baja': return 'baja';
      case 'Media': return 'media';
      case 'Alta': return 'alta';
      case 'Crítica': return 'critica';
      default: return 'baja';
    }
  }

  Future<void> _saveIssue() async {
    if (!_isFormValid()) return;
    setState(() => _isSaving = true);

    try {
      final List<File> files = _photos
          .where((p) => p.path.isNotEmpty)
          .map((p) => File(p.path))
          .toList();

      // Mock GPS coords if toggled
      double? lat = _includeGps ? 19.432608 : null;
      double? lng = _includeGps ? -99.133209 : null;

      await IncidenciaService.createIncidencia(
        proyectoId: _selectedProject!.id,
        titulo: _titleController.text.trim(),
        descripcion: _descController.text.trim(),
        categoria: _getApiCategory(_selectedCategory!),
        severidad: _getApiSeverity(_selectedSeverity!),
        ubicacionDescripcion: _locationController.text.trim(),
        latitud: lat,
        longitud: lng,
        fotos: files,
      );

      if (!mounted) return;
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incidencia reportada correctamente'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      
      String errorMsg = e.message;
      if (e.errors != null && e.errors!.isNotEmpty) {
        final List<String> msgs = [];
        e.errors!.forEach((key, value) {
          if (value is List) {
            msgs.addAll(value.map((v) => v.toString()));
          } else {
            msgs.add(value.toString());
          }
        });
        errorMsg = msgs.join('\n');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: AppColors.critical,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al reportar: ${e.toString()}'),
          backgroundColor: AppColors.critical,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Reportar Incidencia',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppColors.textDark,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 100, top: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Proyecto *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _isLoadingProjects
                ? const CircularProgressIndicator()
                : DropdownButtonFormField<Project>(
                    value: _selectedProject,
                    isExpanded: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: widget.initialProject != null ? Colors.grey[200] : Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    hint: const Text('Selecciona un proyecto'),
                    items: _availableProjects.map((p) {
                      return DropdownMenuItem(
                        value: p,
                        child: Text('${p.name}', overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: widget.initialProject != null
                        ? null
                        : (Project? val) {
                            setState(() => _selectedProject = val);
                          },
                  ),
            const SizedBox(height: 20),

            const Text('Título *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Ej: Fisura en columna...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Descripción *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                Text(
                  '${_descController.text.length} (Mín. 20)',
                  style: TextStyle(
                    fontSize: 12,
                    color: _descController.text.length < 20 ? AppColors.critical : AppColors.textMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Detalla el problema...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),

            const Text('Categoría *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildCategoryChip('Seguridad', '🛡️'),
                _buildCategoryChip('Falta de Material', '📦'),
                _buildCategoryChip('Falla de Equipo', '⚙️'),
                _buildCategoryChip('Clima', '🌧️'),
                _buildCategoryChip('Otro', '📝'),
              ],
            ),
            const SizedBox(height: 20),

            const Text('Severidad *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildSeverityChip('Baja', AppColors.success),
                _buildSeverityChip('Media', AppColors.warning),
                _buildSeverityChip('Alta', Colors.orange),
                _buildSeverityChip('Crítica', AppColors.critical),
              ],
            ),
            const SizedBox(height: 20),

            const Text('Ubicación (Opcional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: 'Ej: Nivel 2, Ala Sur...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            
            SwitchListTile(
              title: const Text('Incluir coordenadas GPS', style: TextStyle(fontSize: 14)),
              value: _includeGps,
              contentPadding: EdgeInsets.zero,
              activeColor: AppColors.primary,
              onChanged: (val) => setState(() => _includeGps = val),
            ),
            const SizedBox(height: 20),

            const Text('Evidencia Fotográfica (Max 6)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            PhotoCaptureGrid(
              initialPhotos: _photos,
              onPhotosChanged: (photos) {
                setState(() => _photos = photos);
              },
              maxPhotos: 6,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isFormValid() && !_isSaving ? _saveIssue : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.critical,
                disabledBackgroundColor: AppColors.critical.withOpacity(0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Reportar Incidencia', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, String emoji) {
    final isSelected = _selectedCategory == label;
    return ChoiceChip(
      label: Text('$emoji $label'),
      selected: isSelected,
      selectedColor: AppColors.primary.withOpacity(0.2),
      onSelected: (selected) {
        setState(() => _selectedCategory = selected ? label : null);
      },
    );
  }

  Widget _buildSeverityChip(String label, Color color) {
    final isSelected = _selectedSeverity == label;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : color)),
      selected: isSelected,
      selectedColor: color,
      backgroundColor: color.withOpacity(0.1),
      onSelected: (selected) {
        setState(() => _selectedSeverity = selected ? label : null);
      },
    );
  }
}
