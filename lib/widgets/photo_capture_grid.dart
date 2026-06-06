import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/report_model.dart';
import '../theme/app_colors.dart';

class PhotoCaptureGrid extends StatefulWidget {
  final List<ReportPhoto> initialPhotos;
  final ValueChanged<List<ReportPhoto>> onPhotosChanged;
  final int maxPhotos;

  const PhotoCaptureGrid({
    super.key,
    required this.initialPhotos,
    required this.onPhotosChanged,
    this.maxPhotos = 6,
  });

  @override
  State<PhotoCaptureGrid> createState() => _PhotoCaptureGridState();
}

class _PhotoCaptureGridState extends State<PhotoCaptureGrid> {
  late List<ReportPhoto> _photos;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _photos = List.from(widget.initialPhotos);
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_photos.length >= widget.maxPhotos) return;

    try {
      final XFile? image = await _picker.pickImage(source: source, imageQuality: 70);
      if (image != null) {
        setState(() {
          _photos.add(ReportPhoto(path: image.path));
        });
        widget.onPhotosChanged(_photos);
      }
    } catch (e) {
      // Manejar error silenciosamente o mostrar snackbar
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
    widget.onPhotosChanged(_photos);
  }

  void _showPhotoDetails(int index) {
    final photo = _photos[index];
    final TextEditingController descController = TextEditingController(text: photo.description);
    String selectedCategory = photo.category;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(photo.path),
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descController,
                    decoration: InputDecoration(
                      labelText: 'Describe esta imagen...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: ['Avance', 'Material', 'Personal', 'Incidencia'].map((cat) {
                      final isSelected = selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        selectedColor: AppColors.accent.withOpacity(0.2),
                        onSelected: (selected) {
                          setModalState(() {
                            selectedCategory = selected ? cat : '';
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                      onPressed: () {
                        setState(() {
                          _photos[index] = ReportPhoto(
                            path: photo.path,
                            description: descController.text,
                            category: selectedCategory,
                          );
                        });
                        widget.onPhotosChanged(_photos);
                        Navigator.pop(context);
                      },
                      child: const Text('Guardar descripción'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _photos.length < widget.maxPhotos ? () => _pickImage(ImageSource.camera) : null,
                icon: const Icon(Icons.camera_alt, size: 28),
                label: const Text('Tomar Foto', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 16),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _photos.length < widget.maxPhotos ? () => _pickImage(ImageSource.gallery) : null,
              icon: const Icon(Icons.photo_library, size: 24),
              label: const Text('Galería'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Evidencia capturada',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            Text(
              '${_photos.length}/${widget.maxPhotos}',
              style: const TextStyle(fontSize: 14, color: AppColors.textMedium),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_photos.isEmpty)
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, style: BorderStyle.solid),
            ),
            child: const Center(
              child: Text('No hay fotos capturadas', style: TextStyle(color: AppColors.textMedium)),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _photos.length,
            itemBuilder: (context, index) {
              final photo = _photos[index];
              return GestureDetector(
                onTap: () => _showPhotoDetails(index),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(photo.path),
                        fit: BoxFit.cover,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(Icons.remove_red_eye, color: Colors.white, size: 24),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removePhoto(index),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 16, color: AppColors.critical),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.access_time, size: 14, color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
