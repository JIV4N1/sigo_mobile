import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../models/report_model.dart';
import '../theme/app_colors.dart';
import '../widgets/photo_viewer_zone.dart';
import '../widgets/photo_detail_form.dart';
import '../widgets/film_strip.dart';

class PhotoManagementScreen extends StatefulWidget {
  final List<ReportPhoto> initialPhotos;

  const PhotoManagementScreen({
    super.key,
    required this.initialPhotos,
  });

  @override
  State<PhotoManagementScreen> createState() => _PhotoManagementScreenState();
}

class _PhotoManagementScreenState extends State<PhotoManagementScreen> {
  late List<ReportPhoto> _photos;
  int _currentIndex = 0;
  late PageController _pageController;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _photos = List.from(widget.initialPhotos);
    _pageController = PageController(initialPage: _currentIndex);
    
    // Obtenemos GPS para las fotos actuales que no tengan
    _determinePosition().then((pos) {
      if (pos != null && mounted) {
        setState(() {
          for (int i = 0; i < _photos.length; i++) {
            if (_photos[i].latitude == null) {
              _photos[i] = _photos[i].copyWith(
                latitude: pos.latitude,
                longitude: pos.longitude,
                timestamp: DateTime.now(),
              );
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition();
  }

  void _onPhotoChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _takeNewPhoto(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source, imageQuality: 70);
      if (image != null) {
        Position? pos = await _determinePosition();
        final newPhoto = ReportPhoto(
          path: image.path,
          timestamp: DateTime.now(),
          latitude: pos?.latitude,
          longitude: pos?.longitude,
        );
        setState(() {
          _photos.add(newPhoto);
          _currentIndex = _photos.length - 1;
        });
        _pageController.jumpToPage(_currentIndex);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al capturar la imagen')));
    }
  }

  void _showAddPhotoBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary, size: 32),
                title: const Text('Tomar foto ahora', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  _takeNewPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.accent, size: 32),
                title: const Text('Seleccionar de galería'),
                onTap: () {
                  Navigator.pop(context);
                  _takeNewPhoto(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.document_scanner, color: AppColors.textMedium, size: 32),
                title: const Text('Escanear documento'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Función de escaneo en desarrollo')));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _updateCurrentPhoto(ReportPhoto updatedPhoto) {
    setState(() {
      _photos[_currentIndex] = updatedPhoto;
      // Si se marca como principal, desmarcamos las demás
      if (updatedPhoto.isMain) {
        for (int i = 0; i < _photos.length; i++) {
          if (i != _currentIndex && _photos[i].isMain) {
            _photos[i] = _photos[i].copyWith(isMain: false);
          }
        }
      }
    });
  }

  void _deleteCurrentPhoto() {
    if (_photos.isEmpty) return;
    
    setState(() {
      _photos.removeAt(_currentIndex);
      if (_currentIndex >= _photos.length) {
        _currentIndex = _photos.length - 1;
      }
    });
    if (_photos.isNotEmpty) {
      _pageController.jumpToPage(_currentIndex);
    }
  }

  void _retakeCurrentPhoto() {
    _deleteCurrentPhoto();
    _takeNewPhoto(ImageSource.camera);
  }

  bool _canConfirm() {
    if (_photos.isEmpty) return false;
    // Habilitar si hay al menos una foto y TODAS tienen categoría, o al menos 1 con categoría
    return _photos.any((p) => p.category.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E), // Fondo oscuro industrial
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Evidencia Fotográfica', style: TextStyle(color: Colors.white)),
        elevation: 0,
      ),
      body: Column(
        children: [
          // ZONA 1: Visor Principal (55%)
          Expanded(
            flex: 55,
            child: PhotoViewerZone(
              photos: _photos,
              currentIndex: _currentIndex,
              pageController: _pageController,
              onPageChanged: _onPhotoChanged,
              onRetake: _retakeCurrentPhoto,
              onDelete: _deleteCurrentPhoto,
            ),
          ),
          
          // ZONA 2: Detalles de la Foto (25%)
          if (_photos.isNotEmpty)
            Expanded(
              flex: 25,
              child: PhotoDetailForm(
                currentPhoto: _photos[_currentIndex],
                onDescriptionChanged: (val) {
                  _updateCurrentPhoto(_photos[_currentIndex].copyWith(description: val));
                },
                onCategoryChanged: (val) {
                  _updateCurrentPhoto(_photos[_currentIndex].copyWith(category: val));
                },
                onIsMainChanged: (val) {
                  _updateCurrentPhoto(_photos[_currentIndex].copyWith(isMain: val));
                },
              ),
            ),
            
          // ZONA 3: Tira de Miniaturas (20%)
          Expanded(
            flex: 20,
            child: FilmStrip(
              photos: _photos,
              currentIndex: _currentIndex,
              onPhotoSelected: (index) {
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              onAddMore: _showAddPhotoBottomSheet,
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          color: AppColors.surface,
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 56,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canConfirm() ? () {
                Navigator.pop(context, _photos);
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                disabledBackgroundColor: AppColors.accent.withOpacity(0.5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Confirmar y agregar al reporte (${_photos.length} fotos)',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
