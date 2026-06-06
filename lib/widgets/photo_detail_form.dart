import 'package:flutter/material.dart';
import '../models/report_model.dart';
import '../theme/app_colors.dart';

class PhotoDetailForm extends StatelessWidget {
  final ReportPhoto currentPhoto;
  final ValueChanged<String> onDescriptionChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<bool> onIsMainChanged;

  const PhotoDetailForm({
    super.key,
    required this.currentPhoto,
    required this.onDescriptionChanged,
    required this.onCategoryChanged,
    required this.onIsMainChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Campo de descripción
          TextField(
            controller: TextEditingController(text: currentPhoto.description)
              ..selection = TextSelection.collapsed(offset: currentPhoto.description.length),
            onChanged: onDescriptionChanged,
            maxLength: 200,
            style: const TextStyle(color: AppColors.textDark, fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Ej: Fisura en muro de carga, lado norte, piso 3...',
              hintStyle: const TextStyle(color: AppColors.textMedium),
              filled: true,
              fillColor: AppColors.surfaceLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.mic, color: AppColors.primary),
                onPressed: () {
                  // TODO: Implementar dictado por voz
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dictado por voz no disponible aún')));
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Chips de clasificación
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryChip('Avance General', Icons.business),
                _buildCategoryChip('Materiales', Icons.inventory_2),
                _buildCategoryChip('Personal', Icons.people),
                _buildCategoryChip('Incidencia', Icons.warning_amber_rounded),
                _buildCategoryChip('Calidad', Icons.star),
                _buildCategoryChip('Seguridad', Icons.security),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Toggle "Marcar como principal"
          SwitchListTile(
            title: const Row(
              children: [
                Icon(Icons.star, color: AppColors.accent, size: 20),
                SizedBox(width: 8),
                Text('Marcar como foto principal del reporte', style: TextStyle(color: AppColors.textDark, fontSize: 14)),
              ],
            ),
            value: currentPhoto.isMain,
            onChanged: onIsMainChanged,
            activeColor: AppColors.accent,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, IconData icon) {
    final isSelected = currentPhoto.category == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.textMedium),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
        selected: isSelected,
        selectedColor: AppColors.accent,
        backgroundColor: AppColors.surfaceLight,
        labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onSelected: (selected) {
          if (selected) {
            onCategoryChanged(label);
          }
        },
      ),
    );
  }
}
