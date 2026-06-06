import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'services/navigation_service.dart';
import 'screens/login_screen.dart';
import 'screens/projects_dashboard.dart';

void main() async {
  // Necesario antes de usar plugins como SharedPreferences
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SigoApp());
}

class SigoApp extends StatelessWidget {
  const SigoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIGO',
      debugShowCheckedModeBanner: false,
      // navigatorKey global para manejo de logout desde ApiService
      navigatorKey: NavigationService.navigatorKey,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A237E),
          primary: const Color(0xFF1A237E),
          secondary: const Color(0xFFFF6D00),
          error: const Color(0xFFD32F2F),
          surface: Colors.white,
        ),
      ),
      home: const SplashRouter(),
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
    // Splash mínimo mientras se verifica la sesión
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.apartment, size: 80, color: Color(0xFF1A237E)),
            SizedBox(height: 16),
            Text(
              'SIGO',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E),
              ),
            ),
            SizedBox(height: 32),
            CircularProgressIndicator(color: Color(0xFFFF6D00)),
          ],
        ),
      ),
    );
  }
}
