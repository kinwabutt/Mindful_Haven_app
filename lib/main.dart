import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/history_screen.dart';
import 'screens/breathing_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/emergency_support_screen.dart';
import 'services/auth_service.dart';
import 'widgets/background_wrapper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/theme_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
final AuthService authService = AuthService();
void main() async {
  // 1. Ensure initialization
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Load Environment Variables (.env file)
  try {
    await dotenv.load(fileName: ".env");
    debugPrint("✅ .env file loaded successfully");
  } catch (e) {
    debugPrint("❌ Error loading .env file: $e");
  }

  // 3. Initialize Firebase
  await Firebase.initializeApp();
  
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => ThemeProvider())],
      child: const MindfulHavenApp(),
    ),
  );
}

class MindfulHavenApp extends StatelessWidget {
  const MindfulHavenApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Yahan themeProvider listen ho raha hai
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Mindful Haven',
      debugShowCheckedModeBanner: false,

      // LIGHT THEME CONFIG
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        primaryColor: const Color(0xFF26C6DA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF26C6DA),
          brightness: Brightness.light,
        ),
      ),

      // DARK THEME CONFIG
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(
          0xFF0F172A,
        ), // Professional dark color
        primaryColor: const Color(0xFF26C6DA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF26C6DA),
          brightness: Brightness.dark,
        ),
      ),

      // YE LINE SABSE IMPORTANT HAI:
      // Agar themeProvider.isDarkMode true hai toh Dark Mode on ho jayega
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,

      home: ListenableBuilder(
        listenable: authService,
        builder: (context, _) => authService.isLoggedIn
            ? const MainNavigation()
            : const SplashScreen(),
      ),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/home':
            return MaterialPageRoute(builder: (_) => const MainNavigation());
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          default:
            return MaterialPageRoute(builder: (_) => const SplashScreen());
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

  @override
  Widget build(BuildContext context) {
    // Theme provider ko check kar rahe hain background color set karne ke liye
    final theme = Provider.of<ThemeProvider>(context);

    return Scaffold(
      // Body ka background theme ke mutabiq change hoga
      backgroundColor: theme.isDarkMode
          ? const Color(0xFF0F172A)
          : Colors.white,
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          HistoryScreen(),
          ChatScreen(),
          BreathingScreen(),
          InsightsScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        // Nav bar ka color bhi theme ke hisab se change hoga
        backgroundColor: theme.isDarkMode ? Colors.black : Colors.white,
        unselectedItemColor: theme.isDarkMode ? Colors.white60 : Colors.grey,
        selectedItemColor: const Color(0xFF26C6DA),
        currentIndex: _selectedIndex,
        onTap: (index) {
          HapticFeedback.lightImpact();
          setState(() => _selectedIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'HOME',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.connect_without_contact),
            label: 'CONNECT',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.air), label: 'BREATHE'),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights),
            label: 'INSIGHTS',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'PROFILE'),
        ],
      ),
    );
  }
}
