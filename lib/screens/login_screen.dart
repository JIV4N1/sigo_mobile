import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/api_config.dart';
import '../widgets/sigo_button.dart';
import '../widgets/sigo_input.dart';
import '../widgets/sigo_logo.dart';
import 'projects_dashboard.dart';

/// Pantalla de inicio de sesión con autenticación real via Laravel Sanctum.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  // ─── Login ────────────────────────────────────────────────────────────────────

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Llamada real a /api/auth/login
      final response = await ApiService.post(
        ApiConfig.login,
        body: {
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        },
      );

      // La respuesta tiene: { "status": "success", "data": { "token": "...", "user": {...} } }
      final data = response['data'] as Map<String, dynamic>? ?? response;
      final token = data['token'] as String? ?? data['access_token'] as String?;
      final user = data['user'] as Map<String, dynamic>? ??
          data['usuario'] as Map<String, dynamic>? ?? {};

      if (token == null || token.isEmpty) {
        throw ApiException('La respuesta del servidor no contiene un token válido.');
      }

      // Guardar sesión
      await AuthService.saveSession(token: token, user: user);

      // Obtener el rol para navegar al dashboard correcto
      final rol = await AuthService.getRol();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ProjectsDashboard(rol: rol),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } catch (e) {
      if (!mounted) return;
      _showError('Error inesperado. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // ─── UI ───────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // El fondo mantiene la marca (azul SIGO) en ambos modos: es una
        // pantalla de splash/branding, no contenido que deba adaptarse.
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryLight],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Logo ────────────────────────────────────────────────
                      _buildLogo(),
                      const SizedBox(height: 48),
                      // ── Card de Login ────────────────────────────────────────
                      _buildLoginCard(),
                      const SizedBox(height: 24),
                      // ── Footer ───────────────────────────────────────────────
                      Text(
                        'Sistema Integral de Gestión de Obras v1.0',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        const SigoLogoBadge(size: 96),
        const SizedBox(height: 20),
        const Text(
          'SIGO',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Gestión de Obras',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.75),
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Iniciar Sesión',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ingresa con tus credenciales corporativas',
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 28),

            // ── Email ──────────────────────────────────────────────────────────
            SigoInput(
              controller: _emailController,
              label: 'Correo electrónico',
              hint: 'usuario@empresa.com',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              enabled: !_isLoading,
              autofillHints: const [AutofillHints.email],
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Ingresa tu correo electrónico';
                }
                if (!v.contains('@') || !v.contains('.')) {
                  return 'Correo electrónico no válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // ── Contraseña ─────────────────────────────────────────────────────
            SigoInput(
              controller: _passwordController,
              label: 'Contraseña',
              hint: '••••••••',
              obscureText: _obscurePassword,
              prefixIcon: Icons.lock_outline,
              textInputAction: TextInputAction.done,
              enabled: !_isLoading,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _handleLogin(),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                if (v.length < 6) {
                  return 'La contraseña debe tener al menos 6 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // ── Botón Login ────────────────────────────────────────────────────
            SigoButton(
              label: 'Iniciar Sesión',
              icon: Icons.arrow_forward_rounded,
              type: SigoButtonType.accent,
              expand: true,
              isLoading: _isLoading,
              onPressed: _handleLogin,
            ),
          ],
        ),
      ),
    );
  }
}
