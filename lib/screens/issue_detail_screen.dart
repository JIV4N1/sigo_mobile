import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:map_launcher/map_launcher.dart';
import '../models/issue_model.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/incidencia_service.dart';
import '../config/api_config.dart';
import '../models/usuario_model.dart';
import '../widgets/severity_badge.dart';
import '../widgets/status_chip.dart';
import '../widgets/timeline_widget.dart';
import '../widgets/assign_engineer_bottom_sheet.dart';
import 'atender_incidencia_screen.dart';

class IssueDetailScreen extends StatefulWidget {
  final Issue issue;
  /// Rol del usuario autenticado para controlar acciones visibles.
  final String rol;
  /// Proyecto desde el que se abrió esta pantalla (si se conoce), usado como
  /// respaldo cuando la incidencia no trae `proyecto_id` en su JSON — p. ej.
  /// cuando viene de un listado de incidencias ya filtrado por proyecto.
  final int? fallbackProjectId;

  const IssueDetailScreen({
    super.key,
    required this.issue,
    this.rol = 'supervisor',
    this.fallbackProjectId,
  });

  @override
  State<IssueDetailScreen> createState() => _IssueDetailScreenState();
}

class _IssueDetailScreenState extends State<IssueDetailScreen> {
  static const Map<IssueStatus, String> _statusApiMap = {
    IssueStatus.open: 'abierta',
    IssueStatus.inProgress: 'en_progreso',
    IssueStatus.resolved: 'resuelta',
    IssueStatus.closed: 'cerrada',
  };

  late Issue _issue;
  bool _isUpdatingStatus = false;
  Usuario? _assignedUsuario;
  String? _currentUserName;

  // Controlador para agregar comentarios
  final TextEditingController _commentController = TextEditingController();
  bool _isSendingComment = false;

  @override
  void initState() {
    super.initState();
    _issue = widget.issue;
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final nombre = await AuthService.getNombre();
    if (mounted) setState(() => _currentUserName = nombre);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  bool get _esAdminOGerente =>
      widget.rol == 'administrador' || widget.rol == 'gerente';
  bool get _esAsignado =>
      _currentUserName != null && _issue.assignedTo == _currentUserName;
  bool get _canChangeStatus =>
      widget.rol == 'ingeniero' || widget.rol == 'gerente' || widget.rol == 'supervisor';
  int? get _effectiveProjectId => _issue.projectId ?? widget.fallbackProjectId;

  // ─── Cambio de estado ─────────────────────────────────────────────────────────

  Future<void> _changeStatus(IssueStatus newStatus, {String? comentario}) async {
    setState(() => _isUpdatingStatus = true);

    try {
      await IncidenciaService.cambiarEstado(
        int.tryParse(_issue.id) ?? 0,
        estado: _statusApiMap[newStatus]!,
        comentario: comentario,
      );

      if (!mounted) return;
      setState(() {
        _isUpdatingStatus = false;
        _issue = Issue(
          id: _issue.id,
          title: _issue.title,
          description: _issue.description,
          category: _issue.category,
          location: _issue.location,
          severity: _issue.severity,
          status: newStatus,
          reportedAt: _issue.reportedAt,
          updatedAt: DateTime.now(),
          reporter: _issue.reporter,
          assignedTo: _issue.assignedTo,
          photos: _issue.photos,
          timeline: [
            IssueTimelineEntry(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              type: 'status_change',
              text: comentario == null
                  ? 'Estado cambiado a "${_getStatusLabel(newStatus)}"'
                  : 'Estado cambiado a "${_getStatusLabel(newStatus)}" — $comentario',
              author: 'Tú',
              timestamp: DateTime.now(),
            ),
            ..._issue.timeline,
          ],
          comments: _issue.comments,
          latitude: _issue.latitude,
          longitude: _issue.longitude,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Estado cambiado a ${_getStatusLabel(newStatus)}'),
          backgroundColor: AppColors.success,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isUpdatingStatus = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.critical),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isUpdatingStatus = false);
    }
  }

  String _getStatusLabel(IssueStatus status) {
    switch (status) {
      case IssueStatus.open:
        return 'Abierto';
      case IssueStatus.inProgress:
        return 'En Progreso';
      case IssueStatus.resolved:
        return 'Resuelto';
      case IssueStatus.closed:
        return 'Cerrado';
    }
  }

  // ─── Atender incidencia (descripción + fotos + comentario) ────────────────────

  Future<void> _navigateToAtender() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AtenderIncidenciaScreen(issue: _issue)),
    );
    if (result == true) {
      await _refreshIssue();
    }
  }

  Future<void> _refreshIssue() async {
    try {
      final updated = await IncidenciaService.getIncidencia(int.tryParse(_issue.id) ?? 0);
      if (!mounted) return;
      setState(() => _issue = updated);
    } catch (_) {
      // La incidencia ya se actualizó en el backend; si el refresco falla,
      // el usuario puede refrescar manualmente desde la lista.
    }
  }

  // ─── Asignación de ingeniero ──────────────────────────────────────────────────

  void _showAssignBottomSheet() {
    final proyectoId = _effectiveProjectId;
    if (proyectoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede asignar responsable: falta el proyecto de la incidencia.'),
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AssignEngineerBottomSheet(
        issueId: _issue.id,
        proyectoId: proyectoId,
        onAssign: _asignarResponsable,
      ),
    );
  }

  Future<void> _asignarResponsable(Usuario usuario) async {
    setState(() => _isUpdatingStatus = true);

    try {
      await IncidenciaService.cambiarEstado(
        int.tryParse(_issue.id) ?? 0,
        estado: _statusApiMap[_issue.status]!,
        asignadoA: usuario.id,
      );

      if (!mounted) return;
      setState(() {
        _isUpdatingStatus = false;
        _assignedUsuario = usuario;
        _issue = Issue(
          id: _issue.id,
          title: _issue.title,
          description: _issue.description,
          category: _issue.category,
          location: _issue.location,
          severity: _issue.severity,
          status: _issue.status,
          reportedAt: _issue.reportedAt,
          updatedAt: DateTime.now(),
          reporter: _issue.reporter,
          assignedTo: usuario.nombre,
          photos: _issue.photos,
          timeline: [
            IssueTimelineEntry(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              type: 'assignment',
              text: 'Asignado a ${usuario.nombre}',
              author: 'Tú',
              timestamp: DateTime.now(),
            ),
            ..._issue.timeline,
          ],
          comments: _issue.comments,
          latitude: _issue.latitude,
          longitude: _issue.longitude,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Responsable asignado: ${usuario.nombre}')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isUpdatingStatus = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.critical),
      );
    } catch (_) {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  // ─── Cierre de incidencia (solo admin/gerente) ────────────────────────────────

  Future<void> _cerrarIncidencia() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar incidencia'),
        content: const Text(
            '¿Confirmas que deseas cerrar esta incidencia? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _changeStatus(IssueStatus.closed,
          comentario: 'Incidencia cerrada por validación');
    }
  }

  // ─── Comentarios ──────────────────────────────────────────────────────────────

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSendingComment = true);

    try {
      await ApiService.post(
        ApiConfig.incidenciaComentarios(int.tryParse(_issue.id) ?? 0),
        body: {'comentario': text},
      );

      _commentController.clear();
      if (!mounted) return;

      // Agregar comentario optimistamente a la UI
      setState(() {
        _isSendingComment = false;
        _issue = Issue(
          id: _issue.id,
          title: _issue.title,
          description: _issue.description,
          category: _issue.category,
          location: _issue.location,
          severity: _issue.severity,
          status: _issue.status,
          reportedAt: _issue.reportedAt,
          updatedAt: _issue.updatedAt,
          reporter: _issue.reporter,
          assignedTo: _issue.assignedTo,
          photos: _issue.photos,
          timeline: _issue.timeline,
          comments: [
            IssueComment(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              author: 'Tú',
              text: text,
              timestamp: DateTime.now(),
            ),
            ..._issue.comments,
          ],
          latitude: _issue.latitude,
          longitude: _issue.longitude,
        );
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSendingComment = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.critical),
      );
    } catch (_) {
      if (mounted) setState(() => _isSendingComment = false);
    }
  }

  // ─── Mapa ─────────────────────────────────────────────────────────────────────

  Future<void> _openMap() async {
    if (_issue.latitude == null || _issue.longitude == null) return;
    final availableMaps = await MapLauncher.installedMaps;
    if (availableMaps.isNotEmpty) {
      await availableMaps.first.showMarker(
        coords: Coords(_issue.latitude!, _issue.longitude!),
        title: _issue.title,
        description: _issue.location,
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay apps de mapas instaladas')));
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        title: Text(
          'Incidencia #${_issue.id}',
          style: const TextStyle(color: AppColors.textDark, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Estado y Severidad ─────────────────────────────────────────────
            Row(children: [
              if (_canChangeStatus &&
                  _issue.status != IssueStatus.closed &&
                  _issue.status != IssueStatus.resolved)
                DropdownButtonHideUnderline(
                  child: DropdownButton<IssueStatus>(
                    value: _issue.status,
                    icon: _isUpdatingStatus
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.arrow_drop_down),
                    // "Resuelta" y "Cerrada" se excluyen del selector: la API
                    // exige un comentario obligatorio al resolver o cerrar,
                    // así que esas transiciones solo pueden hacerse desde el
                    // flujo dedicado ("Atender Incidencia" / "Cerrar
                    // Incidencia" más abajo), que sí lo recolecta.
                    items: IssueStatus.values
                        .where((s) =>
                            s != IssueStatus.closed && s != IssueStatus.resolved)
                        .map((s) {
                      return DropdownMenuItem(
                          value: s, child: StatusChip(status: s));
                    }).toList(),
                    onChanged: _isUpdatingStatus
                        ? null
                        : (s) {
                            if (s != null) _changeStatus(s);
                          },
                  ),
                )
              else
                StatusChip(status: _issue.status),
              const SizedBox(width: 16),
              SeverityBadge(severity: _issue.severity),
            ]),
            const SizedBox(height: 16),

            // ── Título ─────────────────────────────────────────────────────────
            Text(
              _issue.title,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark),
            ),
            const SizedBox(height: 8),

            // ── Timestamps ─────────────────────────────────────────────────────
            Text(
              'Reportado: ${timeago.format(_issue.reportedAt, locale: 'es')} por ${_issue.reporter}',
              style:
                  const TextStyle(color: AppColors.textMedium, fontSize: 13),
            ),
            Text(
              'Última actualización: ${timeago.format(_issue.updatedAt, locale: 'es')}',
              style:
                  const TextStyle(color: AppColors.textMedium, fontSize: 13),
            ),
            if (_issue.assignedTo != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Asignado a: ${_issue.assignedTo}',
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold),
                ),
              ),

            const SizedBox(height: 24),

            // ── Sección Responsable (solo admin/gerente) ───────────────────────
            if (_esAdminOGerente) ...[
              _buildResponsableSection(),
              const SizedBox(height: 24),
            ],

            // ── Cerrar incidencia (solo admin/gerente, estado resuelta) ────────
            if (_esAdminOGerente && _issue.status == IssueStatus.resolved) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isUpdatingStatus ? null : _cerrarIncidencia,
                  icon: const Icon(Icons.lock_outline),
                  label: const Text('Cerrar Incidencia',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ── Descripción ────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _issue.description,
                style: const TextStyle(
                    fontSize: 15, color: AppColors.textDark, height: 1.5),
              ),
            ),
            const SizedBox(height: 24),

            // ── Ubicación GPS ──────────────────────────────────────────────────
            if (_issue.latitude != null && _issue.longitude != null) ...[
              const Text('Ubicación',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark)),
              const SizedBox(height: 8),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const Icon(Icons.map,
                      color: AppColors.primary, size: 32),
                  title: Text(_issue.location,
                      style:
                          const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      '${_issue.latitude!.toStringAsFixed(4)}° N, ${_issue.longitude!.toStringAsFixed(4)}° W'),
                  trailing: OutlinedButton(
                    onPressed: _openMap,
                    child: const Text('Ver en mapa'),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ── Fotos ──────────────────────────────────────────────────────────
            if (_issue.photos.isNotEmpty) ...[
              const Text('Evidencia',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark)),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _issue.photos.length,
                itemBuilder: (context, index) {
                  final photo = _issue.photos[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: photo.path.startsWith('http')
                        ? Image.network(
                            photo.path,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.image,
                                  size: 40, color: Colors.grey),
                            ),
                          )
                        : Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.image,
                                size: 40, color: Colors.grey),
                          ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],

            // ── Timeline ───────────────────────────────────────────────────────
            const Text('Historial',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark)),
            const SizedBox(height: 16),
            TimelineWidget(entries: _issue.timeline),

            const SizedBox(height: 24),

            // ── Comentarios ────────────────────────────────────────────────────
            const Text('Comentarios',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark)),
            const SizedBox(height: 12),
            if (_issue.comments.isEmpty)
              const Text('Sin comentarios aún.',
                  style: TextStyle(
                      color: AppColors.textMedium, fontSize: 14)),
            ..._issue.comments.map((c) => _buildComment(c)),
            const SizedBox(height: 16),

            // ── Agregar comentario ──────────────────────────────────────────────
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: 'Escribe un comentario...',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _isSendingComment
                  ? const SizedBox(
                      width: 44,
                      height: 44,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : IconButton(
                      icon: const Icon(Icons.send, color: AppColors.primary),
                      onPressed: _sendComment,
                    ),
            ]),

            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              )
            ],
          ),
          child: Row(children: [
            if (_issue.severity == IssueSeverity.low ||
                _issue.severity == IssueSeverity.medium) ...[
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.critical,
                    side: const BorderSide(color: AppColors.critical),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {},
                  child: const Text('Escalar'),
                ),
              ),
              const SizedBox(width: 8),
            ],
            if ((_esAsignado || _esAdminOGerente) &&
                (_issue.status == IssueStatus.open ||
                    _issue.status == IssueStatus.inProgress))
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _isUpdatingStatus ? null : _navigateToAtender,
                  icon: const Icon(Icons.assignment_outlined),
                  label: const Text('Atender Incidencia',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
          ]),
        ),
      ),
    );
  }

  Widget _buildResponsableSection() {
    final hasAssignee = _issue.assignedTo != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Responsable',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(children: [
            CircleAvatar(
              backgroundColor: hasAssignee
                  ? AppColors.primary.withOpacity(0.1)
                  : Colors.grey[200],
              child: Icon(
                hasAssignee ? Icons.person : Icons.person_off,
                color:
                    hasAssignee ? AppColors.primary : Colors.grey,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasAssignee
                        ? _issue.assignedTo!
                        : 'Sin responsable asignado',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: hasAssignee ? Colors.black : Colors.grey,
                    ),
                  ),
                  if (hasAssignee && _assignedUsuario != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _assignedUsuario!.email,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey),
                    ),
                  ]
                ],
              ),
            ),
            if (_effectiveProjectId != null)
              if (!hasAssignee)
                ElevatedButton(
                  onPressed: _showAssignBottomSheet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Asignar',
                      style: TextStyle(color: Colors.white)),
                )
              else
                OutlinedButton(
                  onPressed: _showAssignBottomSheet,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Cambiar'),
                ),
          ]),
        ),
      ],
    );
  }

  Widget _buildComment(IssueComment comment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text(
              comment.author.isNotEmpty ? comment.author[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(comment.author,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                      Text(
                        timeago.format(comment.timestamp, locale: 'es'),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textMedium),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(comment.text,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textDark)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
