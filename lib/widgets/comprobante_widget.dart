import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';

/// Muestra el comprobante de un gasto: imagen (JPG/PNG) o ícono de PDF.
class ComprobanteWidget extends StatelessWidget {
  final String? url;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const ComprobanteWidget({
    super.key,
    required this.url,
    this.onTap,
    this.onDelete,
  });

  bool get _esPdf {
    final u = url;
    if (u == null) return false;
    return u.split('?').first.toLowerCase().endsWith('.pdf');
  }

  Future<void> _abrirEnNavegador(BuildContext context) async {
    final u = url;
    if (u == null || u.isEmpty) return;
    final uri = Uri.parse(u);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir el comprobante'),
          backgroundColor: AppColors.critical,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Text('Sin comprobante', style: TextStyle(color: AppColors.textMedium)),
        ),
      );
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap ?? () => _abrirEnNavegador(context),
            child: _esPdf ? _buildPdfTile(context) : _buildImageTile(context),
          ),
        ),
        if (onDelete != null)
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 18, color: AppColors.critical),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPdfTile(BuildContext context) {
    return Container(
      height: 140,
      width: double.infinity,
      color: Colors.red.shade50,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.picture_as_pdf, size: 48, color: AppColors.critical),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _abrirEnNavegador(context),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Abrir PDF'),
          ),
        ],
      ),
    );
  }

  Widget _buildImageTile(BuildContext context) {
    return Image.network(
      url!,
      height: 140,
      width: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const SizedBox(
          height: 140,
          child: Center(child: CircularProgressIndicator()),
        );
      },
      errorBuilder: (context, error, stackTrace) => Container(
        height: 140,
        color: AppColors.surfaceLight,
        child: const Center(
          child: Icon(Icons.broken_image, color: AppColors.textMedium, size: 40),
        ),
      ),
    );
  }
}
