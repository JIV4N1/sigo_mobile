// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/user_profile_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../config/api_config.dart';
import '../theme/app_colors.dart';
import '../widgets/profile/perfil_header.dart';
import '../widgets/profile/info_personal_card.dart';
import '../widgets/profile/proyectos_card.dart';
import '../widgets/profile/preferencias_card.dart';
import '../widgets/sigo_button.dart';
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
  String _appVersion = '1.0.0';
  bool _showFullImage = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _cargarVersionApp();
  }

  // ─── Cargar versión de la app ───────────────────────────────────────────────

  Future<void> _cargarVersionApp() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
      });
    } catch (e) {
      // Si falla, usar versión por defecto
      setState(() {
        _appVersion = '1.0.0';
      });
    }
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
          backgroundColor: AppColors.success,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
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
        content: const Text('¿Estás seguro de que deseas cerrar tu sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          SigoButton(
            label: 'Cerrar Sesión',
            type: SigoButtonType.danger,
            onPressed: () => Navigator.pop(context, true),
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
        content: Text('Funcionalidad de cambio de foto próximamente'),
      ),
    );
  }

  // ─── Mostrar imagen en grande al hacer doble tap ────────────────────────────

  void _mostrarImagenCompleta() {
    setState(() {
      _showFullImage = !_showFullImage;
    });

    if (_showFullImage) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _showFullImage = false;
              });
              Navigator.pop(context);
            },
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Título
                  Text(
                    'SIGO',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Imagen grande
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/hola.jpg',
                      height: 200,
                      width: 200,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          width: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.construction,
                            size: 80,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Texto de versión
                  Text(
                    'Versión $_appVersion',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Año
                  const Text(
                    '© 2026 SIGO - Todos los derechos reservados',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Botón cerrar
                  SigoButton(
                    label: 'Cerrar',
                    type: SigoButtonType.accent,
                    onPressed: () {
                      setState(() {
                        _showFullImage = false;
                      });
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }

  // ─── Widget de versión con imagen y doble tap ──────────────────────────────

  Widget _buildVersionItem() {
    final theme = Theme.of(context);
    return GestureDetector(
      onDoubleTap: _mostrarImagenCompleta,
      child: ListTile(
        leading: const Icon(Icons.info_outline),
        title: const Text('Versión de la app'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Imagen pequeña junto al texto de versión
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.asset(
                'assets/images/hola.jpg',
                height: 20,
                width: 20,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 20,
                    width: 20,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.construction,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'v$_appVersion',
              style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.info_outline,
              size: 16,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ],
        ),
        onTap: () {
          // Un solo tap muestra la imagen en pequeño (ya está visible)
          // o podría mostrar un SnackBar
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Haz doble tap para ver la imagen completa'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading && _userProfile == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: theme.colorScheme.secondary),
        ),
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
                Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
                const SizedBox(height: 16),
                Text(_errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 16),
                SigoButton(label: 'Reintentar', onPressed: _loadUserProfile),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
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
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        // Versión con imagen y doble tap
                        _buildVersionItem(),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.description_outlined),
                          title: const Text('Términos y condiciones'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            // TODO: Navegar a términos y condiciones
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.privacy_tip_outlined),
                          title: const Text('Política de privacidad'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            // TODO: Navegar a política de privacidad
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SigoButton(
                    label: 'Cerrar Sesión',
                    icon: Icons.logout,
                    type: SigoButtonType.danger,
                    expand: true,
                    onPressed: _cerrarSesion,
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