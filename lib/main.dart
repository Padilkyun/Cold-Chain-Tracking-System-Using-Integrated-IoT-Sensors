import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/capsi_box_screen.dart';
import 'screens/tea_harvest_screen.dart';
import 'services/esp_service.dart';
import 'services/notification_service.dart';
import 'services/profile_service.dart';
import 'screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Services
  await NotificationService().init();
  await ProfileService().init();

  // Start polling in background
  EspService().startPolling();
  runApp(const CapsiBoxApp());
}

class CapsiBoxApp extends StatelessWidget {
  const CapsiBoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CapsiBox & Tea Cutter',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Slate 900
        primaryColor: const Color(0xFFEF4444), // Chili Red
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFEF4444),
          secondary: Color(0xFF10B981), // Tea Green
          surface: Color(0xFF1E293B), // Slate 800
          background: Color(0xFF0F172A),
          error: Color(0xFFF43F5E),
        ),
        textTheme: GoogleFonts.outfitTextTheme(
          ThemeData.dark().textTheme,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF0F172A),
          elevation: 0,
          titleTextStyle: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E293B),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/capsibox': (context) => const CapsiBoxScreen(),
        '/tea_harvest': (context) => const TeaHarvestScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
