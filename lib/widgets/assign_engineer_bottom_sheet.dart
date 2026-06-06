import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class Engineer {
  final String id;
  final String name;
  final String email;
  final String phone;
  final int activeIssues;

  Engineer({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.activeIssues,
  });
}

class AssignEngineerBottomSheet extends StatefulWidget {
  final String issueId;
  final Function(Engineer) onAssign;

  const AssignEngineerBottomSheet({
    Key? key,
    required this.issueId,
    required this.onAssign,
  }) : super(key: key);

  @override
  State<AssignEngineerBottomSheet> createState() => _AssignEngineerBottomSheetState();
}

class _AssignEngineerBottomSheetState extends State<AssignEngineerBottomSheet> {
  String _searchQuery = '';
  bool _isLoading = false;
  List<Engineer> _engineers = [];

  @override
  void initState() {
    super.initState();
    _loadEngineers();
  }

  // Simulación del endpoint GET /api/proyectos/{id}/usuarios?rol=ingeniero
  Future<void> _loadEngineers() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1)); // delay simulado
    setState(() {
      _engineers = [
        Engineer(id: 'E1', name: 'Miguel Ángel Rojas', email: 'miguel@sigo.com', phone: '+52 55 1234 5678', activeIssues: 2),
        Engineer(id: 'E2', name: 'Laura Mendoza', email: 'laura@sigo.com', phone: '+52 55 9876 5432', activeIssues: 5),
        Engineer(id: 'E3', name: 'Roberto Castillo', email: 'roberto.c@sigo.com', phone: '+52 55 5555 5555', activeIssues: 8),
      ];
      _isLoading = false;
    });
  }

  // Simulación del endpoint PUT /api/incidencias/{id}/asignar
  Future<void> _assignEngineer(Engineer engineer) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar asignación'),
        content: Text('¿Asignar a ${engineer.name} como responsable de ${widget.issueId}?'),
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
      widget.onAssign(engineer);
      if (mounted) Navigator.pop(context);
    }
  }

  Widget _buildLoadIndicator(int activeIssues) {
    Color color;
    if (activeIssues <= 3) {
      color = Colors.green;
    } else if (activeIssues <= 6) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 4),
          Text(
            '$activeIssues incidencias',
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredEngineers = _engineers
        .where((e) => e.name.toLowerCase().contains(_searchQuery.toLowerCase()))
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
                : ListView.separated(
                    itemCount: filteredEngineers.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final engineer = filteredEngineers[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF1A237E).withOpacity(0.1),
                          child: Text(
                            engineer.name.substring(0, 2).toUpperCase(),
                            style: const TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(engineer.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('${engineer.email} • ${engineer.phone}', style: const TextStyle(fontSize: 12)),
                            const SizedBox(height: 8),
                            _buildLoadIndicator(engineer.activeIssues),
                          ],
                        ),
                        onTap: () => _assignEngineer(engineer),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
