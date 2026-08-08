import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/auth_service.dart';
import 'services/navigation_service.dart';
import 'services/theme_controller.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/projects_dashboard.dart';

void main() async {
  // Necesario antes de usar plugins como SharedPreferences
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar localizaciones para fechas en español
  await initializeDateFormatting('es_ES', null);

  // Cargar preferencia de modo oscuro persistida
  await ThemeController.instance.loadThemeMode();

  runApp(const SigoApp());
}

class SigoApp extends StatelessWidget {
  const SigoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'SIGO',
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('es', 'ES'), // Español
            Locale('en', 'US'), // Inglés
          ],
          // navigatorKey global para manejo de logout desde ApiService
          navigatorKey: NavigationService.navigatorKey,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeController.instance.themeMode,
          home: const SplashRouter(),
        );
      },
    );
  }
}

/// Pantalla de enrutamiento inicial.
/// Verifica si hay sesión activa y navega al destino correspondiente.
class SplashRouter extends StatefulWidget {
  const SplashRouter({super.key});

  @override
  State<SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<SplashRouter> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // Pequeño delay para que se pinte el splash antes de navegar
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    final isLoggedIn = await AuthService.isLoggedIn();

    if (!mounted) return;

    if (isLoggedIn) {
      final rol = await AuthService.getRol();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ProjectsDashboard(rol: rol),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Splash mínimo mientras se verifica la sesión
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.apartment, size: 80, color: colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'SIGO',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            CircularProgressIndicator(color: colorScheme.secondary),
          ],
        ),
      ),
    );
  }
}
