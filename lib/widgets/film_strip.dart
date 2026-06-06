import 'dart:io';
import 'package:flutter/material.dart';
import '../models/report_model.dart';
import '../theme/app_colors.dart';

class FilmStrip extends StatelessWidget {
  final List<ReportPhoto> photos;
  final int currentIndex;
  final ValueChanged<int> onPhotoSelected;
  final VoidCallback onAddMore;

  const FilmStrip({
    super.key,
    required this.photos,
    required this.currentIndex,
    required this.onPhotoSelected,
    required this.onAddMore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      color: const Color(0xFF1E1E1E), // Fondo oscuro
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: photos.length + 1, // +1 para el botón Add More
        itemBuilder: (context, index) {
          if (index == photos.length) {
            return _buildAddMoreButton();
          }

          final photo = photos[index];
          final isSelected = index == currentIndex;
          final hasCategory = photo.category.isNotEmpty;

          return GestureDetector(
            onTap: () => onPhotoSelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              width: isSelected ? 72 : 64,
              height: isSelected ? 72 : 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? AppColors.accent : (hasCategory ? AppColors.success : Colors.transparent),
                  width: isSelected ? 3 : (hasCategory ? 2 : 0),
                ),
                image: DecorationImage(
                  image: FileImage(File(photo.path)),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  if (hasCategory && !isSelected)
                    const Positioned(
                      bottom: 2,
                      right: 2,
                      child: Icon(Icons.check_circle, color: AppColors.success, size: 14),
                    ),
                  if (!hasCategory && !isSelected)
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: AppColors.warning,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.cloud_upload_outlined, color: Colors.white, size: 10),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddMoreButton() {
    return GestureDetector(
      onTap: onAddMore,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border, width: 1, style: BorderStyle.solid),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo, color: Colors.white, size: 24),
            SizedBox(height: 4),
            Text('Agregar', style: TextStyle(color: Colors.white, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
