import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../models/gasto_model.dart';
import '../../models/categoria_gasto.dart';
import '../../models/proveedor_model.dart';
import '../../models/project_model.dart';
import '../../theme/app_colors.dart';
import '../../services/api_service.dart';
import '../../services/api_config.dart';
import '../../services/gasto_service.dart';
import '../../widgets/comprobante_widget.dart';

const int _maxComprobanteBytes = 5 * 1024 * 1024;
const List<String> _extensionesPermitidas = ['pdf', 'jpg', 'jpeg', 'png'];

/// Formulario de gasto de obra, usado tanto para crear como para editar.
/// Si [gastoToEdit] no es null, el formulario se precarga y el envío
/// actualiza el gasto existente en lugar de crear uno nuevo.
class GastoFormScreen extends StatefulWidget {
  final Gasto? gastoToEdit;
  final int? proyectoIdFijo;

  const GastoFormScreen({super.key, this.gastoToEdit, this.proyectoIdFijo});

  @override
  State<GastoFormScreen> createState() => _GastoFormScreenState();
}

class _GastoFormScreenState extends State<GastoFormScreen> {
  final TextEditingController _montoController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  Project? _selectedProyecto;
  CategoriaGasto? _selectedCategoria;
  Proveedor? _selectedProveedor;
  DateTime _fecha = DateTime.now();

  File? _comprobanteNuevo;
  String? _comprobanteExistenteUrl;

  bool _isLoadingOptions = true;
  bool _isSaving = false;
  List<Project> _proyectos = [];
  List<CategoriaGasto> _categorias = [];
  List<Proveedor> _proveedores = [];

  bool get _esEdicion => widget.gastoToEdit != null;

  @override
  void initState() {
    super.initState();
    _comprobanteExistenteUrl = widget.gastoToEdit?.comprobanteUrl;
    if (widget.gastoToEdit != null) {
      final g = widget.gastoToEdit!;
      _montoController.text = g.monto.toString();
      _descController.text = g.descripcion ?? '';
      _fecha = DateTime.tryParse(g.fecha) ?? DateTime.now();
    }
    _loadOptions();
  }

  @override
  void dispose() {
    _montoController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    setState(() => _isLoadingOptions = true);
    try {
      final results = await Future.wait([
        ApiService.get(ApiConfig.proyectos),
        GastoService.listarCategorias(),
        GastoService.listarProveedores(),
      ]);

      final proyectosResponse = results[0] as Map<String, dynamic>;
      final rawData = proyectosResponse['data'];
      final list = rawData is List
          ? rawData
          : (rawData is Map ? rawData['data'] as List<dynamic>? ?? [] : []);
      final proyectos = list.map((e) => Project.fromJson(e as Map<String, dynamic>)).toList();

      if (!mounted) return;
      setState(() {
        _proyectos = proyectos;
        _categorias = results[1] as List<CategoriaGasto>;
        _proveedores = results[2] as List<Proveedor>;

        final gasto = widget.gastoToEdit;
        final proyectoIdBuscado = gasto?.proyectoId ?? widget.proyectoIdFijo;
        if (proyectoIdBuscado != null) {
          _selectedProyecto = _proyectos.where((p) => p.id == proyectoIdBuscado).firstOrNull;
        }
        if (gasto != null) {
          _selectedCategoria = _categorias.where((c) => c.id == gasto.categoriaId).firstOrNull;
          if (gasto.proveedorId != null) {
            _selectedProveedor = _proveedores.where((p) => p.id == gasto.proveedorId).firstOrNull;
          }
        }
        _isLoadingOptions = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingOptions = false);
    }
  }

  bool _isFormValid() {
    final monto = double.tryParse(_montoController.text.trim());
    return _selectedProyecto != null &&
        _selectedCategoria != null &&
        monto != null &&
        monto > 0;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _fecha = picked);
  }

  bool _validarArchivo(String path, int sizeBytes) {
    final ext = path.split('.').last.toLowerCase();
    if (!_extensionesPermitidas.contains(ext)) {
      _showError('Formato no permitido. Usa PDF, JPG o PNG.');
      return false;
    }
    if (sizeBytes > _maxComprobanteBytes) {
      _showError('El comprobante no debe superar 5MB.');
      return false;
    }
    return true;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source, imageQuality: 80);
      if (image == null) return;
      final file = File(image.path);
      final size = await file.length();
      if (!_validarArchivo(image.path, size)) return;
      setState(() {
        _comprobanteNuevo = file;
        _comprobanteExistenteUrl = null;
      });
    } catch (_) {
      _showError('No se pudo capturar la imagen.');
    }
  }

  Future<void> _pickPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _extensionesPermitidas,
      );
      final path = result?.files.single.path;
      if (path == null) return;
      final file = File(path);
      final size = await file.length();
      if (!_validarArchivo(path, size)) return;
      setState(() {
        _comprobanteNuevo = file;
        _comprobanteExistenteUrl = null;
      });
    } catch (_) {
      _showError('No se pudo adjuntar el archivo.');
    }
  }

  void _quitarComprobante() {
    setState(() {
      _comprobanteNuevo = null;
      _comprobanteExistenteUrl = null;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.critical),
    );
  }

  Future<void> _guardar() async {
    if (!_isFormValid()) return;
    setState(() => _isSaving = true);

    try {
      final monto = double.parse(_montoController.text.trim());
      final fechaIso = DateFormat('yyyy-MM-dd').format(_fecha);

      if (_esEdicion) {
        await GastoService.actualizar(
          widget.gastoToEdit!.id,
          proyectoId: _selectedProyecto!.id,
          categoriaId: _selectedCategoria!.id,
          proveedorId: _selectedProveedor?.id,
          monto: monto,
          fecha: fechaIso,
          descripcion: _descController.text.trim(),
          comprobante: _comprobanteNuevo,
        );
      } else {
        await GastoService.crear(
          proyectoId: _selectedProyecto!.id,
          categoriaId: _selectedCategoria!.id,
          proveedorId: _selectedProveedor?.id,
          monto: monto,
          fecha: fechaIso,
          descripcion: _descController.text.trim(),
          comprobante: _comprobanteNuevo,
        );
      }

      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_esEdicion ? 'Gasto actualizado correctamente' : 'Gasto registrado correctamente'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);

      String errorMsg = e.message;
      if (e.errors != null && e.errors!.isNotEmpty) {
        final msgs = <String>[];
        e.errors!.forEach((key, value) {
          if (value is List) {
            msgs.addAll(value.map((v) => v.toString()));
          } else {
            msgs.add(value.toString());
          }
        });
        errorMsg = msgs.join('\n');
      } else if (e.statusCode == 403) {
        errorMsg = 'No tienes permiso para registrar gastos en este proyecto.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: AppColors.critical, duration: const Duration(seconds: 4)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showError('Error al guardar el gasto: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          _esEdicion ? 'Editar Gasto' : 'Nuevo Gasto',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textDark),
        ),
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: _isLoadingOptions
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 100, top: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Proyecto *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Project>(
                    value: _selectedProyecto,
                    isExpanded: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: widget.proyectoIdFijo != null ? Colors.grey[200] : Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    hint: const Text('Selecciona un proyecto'),
                    items: _proyectos
                        .map((p) => DropdownMenuItem(value: p, child: Text(p.name, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: widget.proyectoIdFijo != null
                        ? null
                        : (val) => setState(() => _selectedProyecto = val),
                  ),
                  const SizedBox(height: 20),

                  const Text('Categoría *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<CategoriaGasto>(
                    value: _selectedCategoria,
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    hint: const Text('Selecciona una categoría'),
                    items: _categorias
                        .map((c) => DropdownMenuItem(value: c, child: Text(c.nombre, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedCategoria = val),
                  ),
                  const SizedBox(height: 20),

                  const Text('Proveedor (Opcional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Proveedor?>(
                    value: _selectedProveedor,
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    hint: const Text('Sin proveedor'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Sin proveedor')),
                      ..._proveedores.map((p) => DropdownMenuItem(value: p, child: Text(p.nombre, overflow: TextOverflow.ellipsis))),
                    ],
                    onChanged: (val) => setState(() => _selectedProveedor = val),
                  ),
                  const SizedBox(height: 20),

                  const Text('Monto *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _montoController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      prefixText: '\$ ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 20),

                  const Text('Fecha *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(DateFormat('dd/MM/yyyy').format(_fecha)),
                          const Icon(Icons.calendar_today, size: 18, color: AppColors.textMedium),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text('Descripción (Opcional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Detalles del gasto...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text('Comprobante (Opcional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt, size: 18),
                          label: const Text('Tomar foto'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library, size: 18),
                          label: const Text('Galería'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _pickPdf,
                      icon: const Icon(Icons.picture_as_pdf, size: 18),
                      label: const Text('Adjuntar PDF'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_comprobanteNuevo != null)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _comprobanteNuevo!.path.toLowerCase().endsWith('.pdf')
                              ? Container(
                                  height: 100,
                                  width: double.infinity,
                                  color: Colors.red.shade50,
                                  child: const Center(child: Icon(Icons.picture_as_pdf, size: 40, color: AppColors.critical)),
                                )
                              : Image.file(_comprobanteNuevo!, height: 140, width: double.infinity, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: _quitarComprobante,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: const Icon(Icons.close, size: 18, color: AppColors.critical),
                            ),
                          ),
                        ),
                      ],
                    )
                  else if (_comprobanteExistenteUrl != null)
                    ComprobanteWidget(url: _comprobanteExistenteUrl, onDelete: _quitarComprobante)
                  else
                    Text('Formatos permitidos: PDF, JPG, PNG. Máximo 5MB.', style: TextStyle(fontSize: 12, color: AppColors.textMedium)),
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isFormValid() && !_isSaving ? _guardar : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      _esEdicion ? 'Guardar cambios' : 'Registrar Gasto',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
