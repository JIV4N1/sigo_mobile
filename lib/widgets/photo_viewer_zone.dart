import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../models/report_model.dart';
import '../theme/app_colors.dart';

class PhotoViewerZone extends StatelessWidget {
  final List<ReportPhoto> photos;
  final int currentIndex;
  final PageController pageController;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onRetake;
  final VoidCallback onDelete;

  const PhotoViewerZone({
    super.key,
    required this.photos,
    required this.currentIndex,
    required this.pageController,
    required this.onPageChanged,
    required this.onRetake,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Text(
            'No hay fotos seleccionadas',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      );
    }

    return Stack(
      children: [
        // Visor de fotos con zoom y swipe
        PhotoViewGallery.builder(
          scrollPhysics: const BouncingScrollPhysics(),
          builder: (BuildContext context, int index) {
            return PhotoViewGalleryPageOptions(
              imageProvider: FileImage(File(photos[index].path)),
              initialScale: PhotoViewComputedScale.contained,
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
              heroAttributes: PhotoViewHeroAttributes(tag: photos[index].path),
            );
          },
          itemCount: photos.length,
          loadingBuilder: (context, event) => const Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          ),
          backgroundDecoration: const BoxDecoration(color: Colors.black),
          pageController: pageController,
          onPageChanged: onPageChanged,
        ),
        
        // Botones superiores flotantes
        Positioned(
          top: 16,
          left: 16,
          child: SafeArea(
            child: _buildFloatingIconButton(
              icon: Icons.flip_camera_ios_outlined,
              onPressed: onRetake,
            ),
          ),
        ),
        Positioned(
          top: 16,
          right: 16,
          child: SafeArea(
            child: _buildFloatingIconButton(
              icon: Icons.delete_outline,
              onPressed: onDelete,
              isDestructive: true,
            ),
          ),
        ),

        // Overlay inferior con gradiente
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.transparent,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      _formatTimestamp(photos[currentIndex].timestamp),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    const Spacer(),
                    // TODO: Implementar análisis de nitidez real en backend/Isolate
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.success, width: 1),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, color: AppColors.success, size: 12),
                          SizedBox(width: 4),
                          Text('Calidad OK', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      _formatLocation(photos[currentIndex]),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingIconButton({required IconData icon, required VoidCallback onPressed, bool isDestructive = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: isDestructive ? AppColors.critical : Colors.white),
        onPressed: onPressed,
      ),
    );
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return 'Sin fecha';
    final now = DateTime.now();
    final isToday = timestamp.year == now.year && timestamp.month == now.month && timestamp.day == now.day;
    final time = '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    return isToday ? 'Hoy $time' : '${timestamp.day}/${timestamp.month}/${timestamp.year} $time';
  }

  String _formatLocation(ReportPhoto photo) {
    if (photo.latitude != null && photo.longitude != null) {
      return '${photo.latitude!.toStringAsFixed(4)}° N, ${photo.longitude!.toStringAsFixed(4)}° W';
    }
    return 'Obteniendo GPS...';
  }
}
