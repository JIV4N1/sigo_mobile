import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/report_model.dart';
import '../models/project_model.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../widgets/form_stepper_header.dart';
import '../widgets/progress_slider.dart';
import '../widgets/photo_capture_grid.dart';

class ReportFormScreen extends StatefulWidget {
  /// Proyecto preseleccionado (opcional, ej: desde ProjectDetail).
  final Project? initialProject;

  const ReportFormScreen({super.key, this.initialProject});

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  // Estado del stepper (visual)
  int _currentStep = 0;
  final ScrollController _scrollController = ScrollController();

  // Datos del formulario
  Project? _selectedProject;
  DateTime _selectedDate = DateTime.now();
  String? _selectedShift;
  String? _selectedCategory;
  int _progress = 0;
  final TextEditingController _descController = TextEditingController();
  List<ReportPhoto> _photos = [];

  // Estado UI
  bool _isSaving = false;
  bool _isOffline = false;
  bool _isLoadingProjects = true;
  List<Project> _availableProjects = [];

  @override
  void initState() {
    super.initState();
    _loadProjects();
    _checkConnectivity();
    if (widget.initialProject != null) {
      _selectedProject = widget.initialProject;
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ─── Carga de datos ───────────────────────────────────────────────────────────

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
        // Si ya había un proyecto inicial, verificar que sigue en la lista
        if (widget.initialProject != null && _selectedProject == null) {
          _selectedProject = projects
              .where((p) => p.id == widget.initialProject!.id)
              .firstOrNull;
        }
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingProjects = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudieron cargar proyectos: ${e.message}'),
          backgroundColor: AppColors.warning,
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _isLoadingProjects = false);
    }
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    if (mounted) {
      setState(() => _isOffline = result.contains(ConnectivityResult.none));
    }
    Connectivity().onConnectivityChanged.listen((results) {
      if (mounted) {
        setState(() => _isOffline = results.contains(ConnectivityResult.none));
      }
    });
  }

  // ─── Lógica del formulario ────────────────────────────────────────────────────

  void _updateVisualStep() {
    int step = 0;
    if (_selectedProject != null && _selectedShift != null) {
      step = 1;
      if (_selectedCategory != null && _descController.text.length >= 20) {
        step = 2;
      }
    }
    if (_currentStep != step) setState(() => _currentStep = step);
  }

  bool _isFormValid() {
    return _selectedProject != null &&
        _selectedShift != null &&
        _selectedCategory != null &&
        _descController.text.length >= 20 &&
        _photos.isNotEmpty;
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            onSurface: AppColors.textDark,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _insertChipText(String text) {
    setState(() {
      _descController.text = _descController.text.isEmpty
          ? text
          : '$text\n${_descController.text}';
      _updateVisualStep();
    });
  }

  // ─── Guardado con API ─────────────────────────────────────────────────────────

  Future<void> _saveReport() async {
    if (!_isFormValid()) return;
    setState(() => _isSaving = true);

    try {
      final photoPaths = _photos
          .where((p) => p.path.isNotEmpty)
          .map((p) => p.path)
          .toList();

      final fields = {
        'proyecto_id': _selectedProject!.id.toString(),
        'fecha': '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
        'turno': _selectedShift!,
        'categoria': _selectedCategory!,
        'porcentaje_avance': _progress.toString(),
        'descripcion': _descController.text,
      };

      if (photoPaths.isNotEmpty) {
        // POST multipart con fotos incluidas
        await ApiService.postMultipart(
          ApiConfig.reportes,
          fields: fields,
          filePaths: photoPaths,
          fileFieldName: 'fotos[]',
        );
      } else {
        // POST JSON sin fotos
        await ApiService.post(
          ApiConfig.reportes,
          body: {
            ...fields,
            'porcentaje_avance': _progress,
          },
        );
      }

      if (!mounted) return;
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Reporte guardado correctamente'),
            ],
          ),
          backgroundColor: AppColors.success,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.critical,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al guardar el reporte'),
          backgroundColor: AppColors.critical,
        ),
      );
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Registrar Avance',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppColors.textDark,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: Column(
        children: [
          if (_isOffline)
            Container(
              width: double.infinity,
              color: AppColors.warning.withOpacity(0.1),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off, size: 16, color: AppColors.warning),
                  SizedBox(width: 8),
                  Text(
                    'Sin conexión — El reporte no se podrá enviar',
                    style: TextStyle(
                        color: AppColors.warning,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          FormStepperHeader(currentStep: _currentStep),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding:
                  const EdgeInsets.only(left: 24, right: 24, bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Paso 1: Información General ──────────────────────────────
                  _buildSectionTitle('1. Información General'),
                  const SizedBox(height: 16),

                  const Text('Proyecto *',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark)),
                  const SizedBox(height: 8),
                  _isLoadingProjects
                      ? Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary),
                            ),
                          ),
                        )
                      : DropdownButtonFormField<Project>(
                          value: _selectedProject,
                          isExpanded: true,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: widget.initialProject != null
                                ? Colors.grey[200]
                                : Colors.white,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                          ),
                          hint: const Text('Selecciona un proyecto'),
                          items: _availableProjects.map((p) {
                            return DropdownMenuItem(
                              value: p,
                              child: Text(
                                '${p.name} (${p.contract.isNotEmpty ? p.contract : '#${p.id}'})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: widget.initialProject != null
                              ? null
                              : (Project? val) {
                                  setState(() => _selectedProject = val);
                                  _updateVisualStep();
                                },
                        ),
                  const SizedBox(height: 20),

                  const Text('Fecha del reporte *',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _selectDate(context),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        suffixIcon: const Icon(Icons.calendar_today,
                            color: AppColors.primary),
                      ),
                      child: Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: const TextStyle(
                            fontSize: 16, color: AppColors.textDark),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text('Turno *',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildShiftChip('Matutino', Icons.wb_sunny_outlined),
                      _buildShiftChip('Vespertino', Icons.cloud_outlined),
                      _buildShiftChip(
                          'Nocturno', Icons.nights_stay_outlined),
                    ],
                  ),

                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 24),

                  // ── Paso 2: Detalle del Avance ───────────────────────────────
                  _buildSectionTitle('2. Detalle del Avance'),
                  const SizedBox(height: 16),

                  const Text('Categoría *',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark)),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      _buildCategoryChip('Estructural', '🏗️'),
                      _buildCategoryChip('Albañilería', '🧱'),
                      _buildCategoryChip('Instalaciones', '🔌'),
                      _buildCategoryChip('Acabados', '🎨'),
                      _buildCategoryChip('General', '🏢'),
                    ]),
                  ),
                  const SizedBox(height: 20),

                  const Text('Porcentaje de avance actual *',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark)),
                  const SizedBox(height: 8),
                  ProgressSlider(
                    initialValue: _progress,
                    onChanged: (val) {
                      _progress = val;
                      _updateVisualStep();
                    },
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Descripción del avance *',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark)),
                      Text(
                        '${_descController.text.length}/500',
                        style: TextStyle(
                          fontSize: 12,
                          color: _descController.text.length < 20
                              ? AppColors.critical
                              : AppColors.textMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descController,
                    maxLines: null,
                    minLines: 3,
                    maxLength: 500,
                    onChanged: (_) => _updateVisualStep(),
                    decoration: InputDecoration(
                      hintText:
                          'Describe el trabajo realizado hoy, materiales utilizados...',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.all(16),
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildSuggestionChip('Se completó según programa'),
                      _buildSuggestionChip('Se presentaron retrasos'),
                      _buildSuggestionChip(
                          'Se requiere material adicional'),
                      _buildSuggestionChip('Personal insuficiente'),
                    ],
                  ),

                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 24),

                  // ── Paso 3: Evidencia Fotográfica ────────────────────────────
                  _buildSectionTitle('3. Evidencia Fotográfica *'),
                  const SizedBox(height: 16),
                  PhotoCaptureGrid(
                    initialPhotos: _photos,
                    onPhotosChanged: (photos) {
                      setState(() {
                        _photos = photos;
                        _updateVisualStep();
                      });
                    },
                    maxPhotos: 6,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 56,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  _isFormValid() && !_isSaving && !_isOffline
                      ? _saveReport
                      : null,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline, size: 24),
              label: Text(
                _isSaving ? 'Guardando...' : 'Guardar Reporte',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    AppColors.accent.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Widgets helpers ──────────────────────────────────────────────────────────

  Widget _buildSectionTitle(String title) => Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      );

  Widget _buildShiftChip(String label, IconData icon) {
    final isSelected = _selectedShift == label;
    return ChoiceChip(
      label: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon,
            size: 16,
            color: isSelected ? Colors.white : AppColors.textMedium),
        const SizedBox(width: 4),
        Text(label),
      ]),
      selected: isSelected,
      selectedColor: AppColors.primary,
      labelStyle:
          TextStyle(color: isSelected ? Colors.white : AppColors.textDark),
      onSelected: (selected) {
        setState(() => _selectedShift = selected ? label : null);
        _updateVisualStep();
      },
    );
  }

  Widget _buildCategoryChip(String label, String emoji) {
    final isSelected = _selectedCategory == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(emoji),
          const SizedBox(width: 4),
          Text(label),
        ]),
        selected: isSelected,
        selectedColor: AppColors.accent.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onSelected: (selected) {
          setState(() => _selectedCategory = selected ? label : null);
          _updateVisualStep();
        },
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return InkWell(
      onTap: () => _insertChipText(text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(text,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textMedium)),
      ),
    );
  }
}
