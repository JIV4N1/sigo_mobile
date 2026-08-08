import 'package:flutter/material.dart';
import '../sigo_button.dart';

class InfoPersonalCard extends StatefulWidget {
  final String nombreInicial;
  final String email;
  final String telefonoInicial;
  final Function(String nombre, String telefono) onGuardar;

  const InfoPersonalCard({
    Key? key,
    required this.nombreInicial,
    required this.email,
    required this.telefonoInicial,
    required this.onGuardar,
  }) : super(key: key);

  @override
  State<InfoPersonalCard> createState() => _InfoPersonalCardState();
}

class _InfoPersonalCardState extends State<InfoPersonalCard> {
  late TextEditingController _nombreController;
  late TextEditingController _telefonoController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.nombreInicial);
    _telefonoController = TextEditingController(text: widget.telefonoInicial);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Información Personal',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => v == null || v.isEmpty ? 'El nombre es obligatorio' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: widget.email,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefonoController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (v) => v == null || v.isEmpty ? 'El teléfono es obligatorio' : null,
              ),
              const SizedBox(height: 24),
              SigoButton(
                label: 'Guardar Cambios',
                type: SigoButtonType.accent,
                expand: true,
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    widget.onGuardar(_nombreController.text, _telefonoController.text);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
