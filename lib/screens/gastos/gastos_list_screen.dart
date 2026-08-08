import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/gasto_model.dart';
import '../../models/categoria_gasto.dart';
import '../../models/project_model.dart';
import '../../theme/app_colors.dart';
import '../../services/api_service.dart';
import '../../services/api_config.dart';
import '../../services/auth_service.dart';
import '../../services/gasto_service.dart';
import '../../widgets/shimmer_loading.dart';
import 'gasto_detail_screen.dart';
import 'nuevo_gasto_screen.dart';

class GastosListScreen extends StatefulWidget {
  /// Si se proporciona, la lista queda fija a este proyecto.
  final int? projectId;

  const GastosListScreen({super.key, this.projectId});

  @override
  State<GastosListScreen> createState() => _GastosListScreenState();
}

class _GastosListScreenState extends State<GastosListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final _currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
  final _dateFormat = DateFormat('dd/MM/yyyy');

  String _rol = 'supervisor';
  List<Gasto> _gastos = [];
  List<CategoriaGasto> _categorias = [];
  List<Project> _proyectos = [];

  int? _selectedProyectoId;
  int? _selectedCategoriaId;
  DateTime? _desde;
  DateTime? _hasta;

  int _page = 1;
  bool _hasMore = true;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasError = false;
  String _errorMessage = '';
  double _totalMonto = 0;

  @override
  void initState() {
    super.initState();
    _selectedProyectoId = widget.projectId;
    _scrollController.addListener(_onScroll);
    _init();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    _rol = await AuthService.getRol();
    await Future.wait([
      _loadCategorias(),
      if (widget.projectId == null) _loadProyectos(),
    ]);
    await _loadData();
  }

  Future<void> _loadCategorias() async {
    try {
      _categorias = await GastoService.listarCategorias();
    } catch (_) {
      // Los filtros de categoría quedan vacíos si falla la carga.
    }
  }

  Future<void> _loadProyectos() async {
    try {
      final response = await ApiService.get(ApiConfig.proyectos);
      final rawData = response['data'];
      final list = rawData is List
          ? rawData
          : (rawData is Map ? rawData['data'] as List<dynamic>? ?? [] : []);
      _proyectos = list.map((e) => Project.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      // Los filtros de proyecto quedan vacíos si falla la carga.
    }
  }

  void _onScroll() {
    if (!_hasMore || _isLoadingMore || _isLoading) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  String? _isoDate(DateTime? d) => d == null ? null : DateFormat('yyyy-MM-dd').format(d);

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
      _page = 1;
      _hasMore = true;
    });

    try {
      final result = await GastoService.listar(
        proyectoId: _selectedProyectoId,
        categoriaId: _selectedCategoriaId,
        desde: _isoDate(_desde),
        hasta: _isoDate(_hasta),
        search: _searchController.text.trim(),
        page: 1,
      );
      final resumen = await GastoService.resumen(
        proyectoId: _selectedProyectoId,
        desde: _isoDate(_desde),
        hasta: _isoDate(_hasta),
      );

      if (!mounted) return;
      setState(() {
        _gastos = result.gastos;
        _page = result.currentPage;
        _hasMore = result.hasMore;
        _totalMonto = (resumen['total'] as num?)?.toDouble() ??
            (resumen['monto_total'] as num?)?.toDouble() ??
            _gastos.fold<double>(0, (sum, g) => sum + g.monto);
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
        _errorMessage = 'Error inesperado al cargar gastos.';
      });
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    try {
      final result = await GastoService.listar(
        proyectoId: _selectedProyectoId,
        categoriaId: _selectedCategoriaId,
        desde: _isoDate(_desde),
        hasta: _isoDate(_hasta),
        search: _searchController.text.trim(),
        page: _page + 1,
      );
      if (!mounted) return;
      setState(() {
        _gastos.addAll(result.gastos);
        _page = result.currentPage;
        _hasMore = result.hasMore;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _desde != null && _hasta != null
          ? DateTimeRange(start: _desde!, end: _hasta!)
          : null,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (range != null) {
      setState(() {
        _desde = range.start;
        _hasta = range.end;
      });
      _loadData();
    }
  }

  void _clearDateRange() {
    setState(() {
      _desde = null;
      _hasta = null;
    });
    _loadData();
  }

  Future<void> _confirmDelete(Gasto gasto) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar gasto'),
        content: Text('¿Deseas eliminar el gasto de ${_currencyFormat.format(gasto.monto)}? Esta acción no se puede deshacer.'),
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
      await GastoService.eliminar(gasto.id);
      if (!mounted) return;
      setState(() {
        _gastos.removeWhere((g) => g.id == gasto.id);
        _totalMonto -= gasto.monto;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gasto eliminado'), backgroundColor: AppColors.success),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.critical),
      );
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final canCreate = ['administrador', 'gerente', 'supervisor', 'ingeniero'].contains(_rol);
    final canDelete = ['administrador', 'gerente'].contains(_rol);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Gastos de Obra',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.textDark),
        ),
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: Column(
        children: [
          _buildFilters(),
          if (!_isLoading && !_hasError) _buildTotalBar(),
          Expanded(child: _buildList(canDelete)),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.accent,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Nuevo gasto', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GastoFormScreen(proyectoIdFijo: widget.projectId),
                  ),
                );
                _loadData();
              },
            )
          : null,
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por proyecto o descripción...',
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onSubmitted: (_) => _loadData(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (widget.projectId == null && _proyectos.isNotEmpty)
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    value: _selectedProyectoId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: 'Proyecto',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todos')),
                      ..._proyectos.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name, overflow: TextOverflow.ellipsis))),
                    ],
                    onChanged: (v) {
                      setState(() => _selectedProyectoId = v);
                      _loadData();
                    },
                  ),
                ),
              if (widget.projectId == null && _proyectos.isNotEmpty) const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: _selectedCategoriaId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: 'Categoría',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todas')),
                    ..._categorias.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nombre, overflow: TextOverflow.ellipsis))),
                  ],
                  onChanged: (v) {
                    setState(() => _selectedCategoriaId = v);
                    _loadData();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDateRange,
                  icon: const Icon(Icons.date_range, size: 18),
                  label: Text(
                    _desde != null && _hasta != null
                        ? '${_dateFormat.format(_desde!)} - ${_dateFormat.format(_hasta!)}'
                        : 'Rango de fechas',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (_desde != null || _hasta != null)
                IconButton(
                  onPressed: _clearDateRange,
                  icon: const Icon(Icons.clear, color: AppColors.textMedium),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalBar() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Total filtrado', style: TextStyle(color: AppColors.textMedium, fontSize: 13)),
          Text(
            _currencyFormat.format(_totalMonto),
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildList(bool canDelete) {
    if (_hasError) {
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
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return ListView.builder(
        itemCount: 5,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemBuilder: (context, index) => const ShimmerLoadingCard(),
      );
    }

    if (_gastos.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.accent,
        child: ListView(children: const [
          SizedBox(height: 80),
          Icon(Icons.receipt_long, size: 80, color: AppColors.border),
          SizedBox(height: 16),
          Center(child: Text('No hay gastos que coincidan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
        ]),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.accent,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _gastos.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _gastos.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final gasto = _gastos[index];
          final card = _GastoCard(
            gasto: gasto,
            currencyFormat: _currencyFormat,
            dateFormat: _dateFormat,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => GastoDetailScreen(gastoId: gasto.id, rol: _rol)),
              );
              _loadData();
            },
          );

          if (!canDelete) return card;

          return Dismissible(
            key: ValueKey(gasto.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: AppColors.critical, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            confirmDismiss: (_) async {
              await _confirmDelete(gasto);
              return false;
            },
            child: card,
          );
        },
      ),
    );
  }
}

class _GastoCard extends StatelessWidget {
  final Gasto gasto;
  final NumberFormat currencyFormat;
  final DateFormat dateFormat;
  final VoidCallback onTap;

  const _GastoCard({
    required this.gasto,
    required this.currencyFormat,
    required this.dateFormat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fecha = DateTime.tryParse(gasto.fecha);
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.receipt_long, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gasto.proyecto?.nombre ?? 'Proyecto',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      gasto.categoria?.nombre ?? '',
                      style: const TextStyle(color: AppColors.textMedium, fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      fecha != null ? dateFormat.format(fecha) : gasto.fecha,
                      style: const TextStyle(color: AppColors.textMedium, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                currencyFormat.format(gasto.monto),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
