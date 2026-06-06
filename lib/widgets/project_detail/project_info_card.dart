import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/project_model.dart';
import '../../theme/app_colors.dart';

class ProjectInfoCard extends StatelessWidget {
  final Project project;

  const ProjectInfoCard({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy', 'es');

    return Card(
      elevation: 1,
      margin: const EdgeInsets.all(16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: const Text('Información General', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
        childrenPadding: const EdgeInsets.all(16.0).copyWith(top: 0),
        children: [
          _buildInfoRow('Cliente', project.client),
          _buildInfoRow('Contrato', project.contract),
          _buildInfoRow('Fecha inicio', dateFormat.format(project.startDate)),
          _buildInfoRow('Fecha fin estimada', dateFormat.format(project.endDate)),
          _buildInfoRow('Presupuesto', project.budget),
          _buildInfoRow('Encargado', project.manager),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.picture_as_pdf, size: 18),
              label: const Text('Ver contrato completo'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Abriendo PDF...')));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(key, style: const TextStyle(color: AppColors.textMedium, fontSize: 13)),
          ),
          Expanded(
            flex: 3,
            child: Text(value, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
