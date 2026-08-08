import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/gasto_model.dart';
import '../../theme/app_colors.dart';
import '../../services/api_service.dart';
import '../../services/gasto_service.dart';
import '../../widgets/comprobante_widget.dart';
import 'editar_gasto_screen.dart';

class GastoDetailScreen extends StatefulWidget {
  final int gastoId;
  final String rol;

  const GastoDetailScreen({super.key, required this.gastoId, required this.rol});

  @override
  State<GastoDetailScreen> createState() => _GastoDetailScreenState();
}

class _GastoDetailScreenState extends State<GastoDetailScreen> {
  final _currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
  Gasto? _gasto;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  bool get _puedeEditar => ['administrador', 'gerente'].contains(widget.rol);
  bool get _puedeEliminar => ['administrador', 'gerente'].contains(widget.rol);

  @override
  void initState() {
    super.initState();
    _loadGasto();
  }

  Future<void> _loadGasto() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final gasto = await GastoService.obtener(widget.gastoId);
      if (!mounted) return;
      setState(() {
        _gasto = gasto;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Error inesperado al cargar el gasto.';
      });
    }
  }

  Future<void> _eliminar() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar gasto'),
        content: const Text('¿Deseas eliminar este gasto? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: AppColors.critical)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await GastoService.eliminar(widget.gastoId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gasto eliminado'), backgroundColor: AppColors.success),
      );
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.critical),
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
          'Detalle del Gasto',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textDark),
        ),
        iconTheme: const IconThemeData(color: AppColors.textDark),
        actions: [
          if (_gasto != null && _puedeEditar)
            IconButton(
              icon: const Icon(Icons.edit, color: AppColors.primary),
              onPressed: () async {
                final updated = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => EditarGastoScreen(gasto: _gasto!)),
                );
                if (updated == true) _loadGasto();
              },
            ),
          if (_gasto != null && _puedeEliminar)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.critical),
              onPressed: _eliminar,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError || _gasto == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 64, color: AppColors.border),
              const SizedBox(height: 16),
              Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMedium)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadGasto,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    final gasto = _gasto!;
    final fecha = DateTime.tryParse(gasto.fecha);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Text(
                  _currencyFormat.format(gasto.monto),
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const SizedBox(height: 4),
                Text(
                  fecha != null ? DateFormat('dd/MM/yyyy').format(fecha) : gasto.fecha,
                  style: const TextStyle(color: AppColors.textMedium),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildInfoTile(Icons.business, 'Proyecto', gasto.proyecto?.nombre ?? '—'),
          _buildInfoTile(Icons.category_outlined, 'Categoría', gasto.categoria?.nombre ?? '—'),
          if (gasto.proveedor != null)
            _buildInfoTile(Icons.storefront_outlined, 'Proveedor', gasto.proveedor!.nombre),
          _buildInfoTile(Icons.person_outline, 'Capturado por', gasto.usuario?.nombre ?? '—'),
          if (gasto.descripcion != null && gasto.descripcion!.isNotEmpty)
            _buildInfoTile(Icons.notes, 'Descripción', gasto.descripcion!),
          const SizedBox(height: 16),
          const Text('Comprobante', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ComprobanteWidget(url: gasto.comprobanteUrl),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.textMedium),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 15, color: AppColors.textDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
