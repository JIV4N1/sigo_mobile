import 'package:flutter/material.dart';
import '../models/user_profile_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../config/api_config.dart';
import '../widgets/profile/perfil_header.dart';
import '../widgets/profile/info_personal_card.dart';
import '../widgets/profile/proyectos_card.dart';
import '../widgets/profile/preferencias_card.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // ─── Carga de perfil ──────────────────────────────────────────────────────────

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Intentar primero con los datos locales guardados (respuesta instantánea)
      final localUser = await AuthService.getUsuarioMap();
      if (localUser != null && mounted) {
        setState(() {
          _userProfile = UserProfile.fromJson(localUser);
          _isLoading = false;
        });
      }

      // Luego recargar desde la API para tener datos frescos
      final response = await ApiService.get(ApiConfig.me);
      final data = response['data'] as Map<String, dynamic>? ?? response;
      final updatedProfile = UserProfile.fromJson(data);

      // Actualizar los datos guardados localmente
      await AuthService.saveSession(
        token: (await AuthService.getToken()) ?? '',
        user: data,
      );

      if (!mounted) return;
      setState(() {
        _userProfile = updatedProfile;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      // Si hay datos locales, no mostrar error (datos en cache)
      if (_userProfile != null) return;
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.message;
      });
    } catch (e) {
      if (_userProfile != null) return;
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Error inesperado al cargar el perfil.';
      });
    }
  }

  // ─── Actualizar perfil ────────────────────────────────────────────────────────

  Future<void> _actualizarPerfil(String nombre, String telefono) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await ApiService.put(
        ApiConfig.me,
        body: {'nombre': nombre, 'telefono': telefono},
      );
      final data = response['data'] as Map<String, dynamic>? ?? response;
      final updated = UserProfile.fromJson(data);

      await AuthService.saveSession(
        token: (await AuthService.getToken()) ?? '',
        user: data,
      );

      if (!mounted) return;
      Navigator.pop(context);
      setState(() => _userProfile = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado correctamente'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e.message),
            backgroundColor: const Color(0xFFC62828)),
      );
    } catch (_) {
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  // ─── Cerrar sesión ────────────────────────────────────────────────────────────

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content:
            const Text('¿Estás seguro de que deseas cerrar tu sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar Sesión',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Llamar al endpoint de logout para invalidar el token en el servidor
      await ApiService.post(ApiConfig.logout);
    } catch (_) {
      // Si falla la llamada, de todos modos limpiamos localmente
    }

    await AuthService.clearSession();

    if (!mounted) return;
    Navigator.pop(context); // Cerrar loader
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // ─── Foto de perfil ───────────────────────────────────────────────────────────

  Future<void> _cambiarFoto() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Funcionalidad de cambio de foto próximamente')),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _userProfile == null) {
      return const Scaffold(
        body: Center(
            child: CircularProgressIndicator(color: Color(0xFFFF6D00))),
      );
    }

    if (_hasError && _userProfile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Perfil')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 64, color: Color(0xFFC62828)),
                const SizedBox(height: 16),
                Text(_errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadUserProfile,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: RefreshIndicator(
        onRefresh: _loadUserProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(children: [
            PerfilHeader(
              user: _userProfile!,
              onAvatarTap: _cambiarFoto,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InfoPersonalCard(
                    nombreInicial: _userProfile!.nombreCompleto,
                    email: _userProfile!.email,
                    telefonoInicial: _userProfile!.telefono,
                    onGuardar: _actualizarPerfil,
                  ),
                  const SizedBox(height: 16),
                  ProyectosCard(proyectos: _userProfile!.proyectos),
                  const SizedBox(height: 16),
                  const PreferenciasCard(),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: const Column(children: [
                      ListTile(
                        leading: Icon(Icons.info_outline),
                        title: Text('Versión de la app'),
                        trailing: Text('v1.0.0',
                            style: TextStyle(color: Colors.grey)),
                      ),
                      Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.description_outlined),
                        title: Text('Términos y condiciones'),
                        trailing: Icon(Icons.chevron_right,
                            color: Colors.grey),
                      ),
                      Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.privacy_tip_outlined),
                        title: Text('Política de privacidad'),
                        trailing: Icon(Icons.chevron_right,
                            color: Colors.grey),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _cerrarSesion,
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text(
                      'Cerrar Sesión',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      padding:
                          const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
