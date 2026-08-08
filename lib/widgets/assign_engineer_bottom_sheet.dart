import 'package:flutter/material.dart';
import '../models/usuario_model.dart';
import '../services/usuario_service.dart';
import '../services/api_service.dart';

class AssignEngineerBottomSheet extends StatefulWidget {
  final String issueId;
  final int proyectoId;
  final Function(Usuario) onAssign;

  const AssignEngineerBottomSheet({
    Key? key,
    required this.issueId,
    required this.proyectoId,
    required this.onAssign,
  }) : super(key: key);

  @override
  State<AssignEngineerBottomSheet> createState() => _AssignEngineerBottomSheetState();
}

class _AssignEngineerBottomSheetState extends State<AssignEngineerBottomSheet> {
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;
  List<Usuario> _usuarios = [];

  @override
  void initState() {
    super.initState();
    _loadUsuarios();
  }

  Future<void> _loadUsuarios() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final usuarios = await UsuarioService.getUsuariosPorProyecto(
        widget.proyectoId,
        rol: 'ingeniero',
      );
      if (!mounted) return;
      setState(() {
        _usuarios = usuarios;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'No se pudo cargar la lista de ingenieros.';
        _isLoading = false;
      });
    }
  }

  Future<void> _assignUsuario(Usuario usuario) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar asignación'),
        content: Text('¿Asignar a ${usuario.nombre} como responsable de esta incidencia?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6D00)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      widget.onAssign(usuario);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsuarios = _usuarios
        .where((u) => u.nombre.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Seleccionar Responsable',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar por nombre...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_errorMessage!, textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: _loadUsuarios,
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : filteredUsuarios.isEmpty
                        ? const Center(child: Text('No hay ingenieros disponibles en este proyecto.'))
                        : ListView.separated(
                            itemCount: filteredUsuarios.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (context, index) {
                              final usuario = filteredUsuarios[index];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFF1A237E).withOpacity(0.1),
                                  child: Text(
                                    usuario.nombre.isNotEmpty
                                        ? usuario.nombre.substring(0, usuario.nombre.length >= 2 ? 2 : 1).toUpperCase()
                                        : '?',
                                    style: const TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(usuario.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(usuario.email, style: const TextStyle(fontSize: 12)),
                                onTap: () => _assignUsuario(usuario),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
