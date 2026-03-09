import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/history_screen.dart';
import 'screens/breathing_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/emergency_support_screen.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const MindfulHavenApp());
}

// Global key to access the MainNavigation state
final GlobalKey<MainNavigationState> navigationKey = GlobalKey<MainNavigationState>();

class MindfulHavenApp extends StatelessWidget {
  const MindfulHavenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mindful Haven',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light.copyWith(
        textTheme: GoogleFonts.outfitTextTheme().copyWith(
          headlineLarge: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textDark),
          headlineMedium: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textDark),
          headlineSmall: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textDark),
          bodyMedium: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w400, color: AppTheme.textDark),
          bodySmall: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w400, color: AppTheme.textDark),
        ),
      ),
      initialRoute: '/', // Starts at Splash Screen
      onGenerateRoute: (settings) {
        final auth = AuthService();
        
        // Protection Logic: Restricted access to /home if not logged in
        if (settings.name == '/home' && !auth.isLoggedIn) {
          return MaterialPageRoute(builder: (context) => const LoginScreen());
        }
        
        // Default Routes
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (context) => const SplashScreen());
          case '/login':
            return MaterialPageRoute(builder: (context) => const LoginScreen());
          case '/home':
            return MaterialPageRoute(builder: (context) => MainNavigation(key: navigationKey));
          case '/emergency':
            return MaterialPageRoute(builder: (context) => const EmergencySupportScreen());
          default:
            return MaterialPageRoute(builder: (context) => const SplashScreen());
        }
      },
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => MainNavigationState();
}

class MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  void setIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  static final List<Widget> _widgetOptions = <Widget>[
    const HistoryScreen(),
    const ChatScreen(),
    const BreathingScreen(),
    const InsightsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: _widgetOptions,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 10,
        unselectedItemColor: AppTheme.textLight,
        selectedItemColor: AppTheme.primaryTeal,
        currentIndex: _selectedIndex,
        onTap: setIndex,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Connect',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.self_improvement_outlined),
            activeIcon: Icon(Icons.self_improvement),
            label: 'Breathe',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights_outlined),
            activeIcon: Icon(Icons.insights),
            label: 'Insights',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
