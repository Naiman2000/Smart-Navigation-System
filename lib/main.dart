// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Import your screen files
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/map_screen.dart';
import 'screens/add_list_screen.dart';
import 'screens/shopping_list_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/notification_preferences_screen.dart';
import 'screens/privacy_security_screen.dart';
import 'screens/help_support_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Check for placeholder credentials
  if (DefaultFirebaseOptions.currentPlatform.apiKey == 'YOUR_API_KEY_HERE') {
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red,
                    size: 64,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Firebase Not Configured',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'The app is using placeholder Firebase credentials.\n\n'
                    'Please run "flutterfire configure" or update "lib/firebase_options.dart" with your actual project keys.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return;
  }

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    // Continue without Firebase for development
  }

  runApp(const SmartNavigationApp());
}

class SmartNavigationApp extends StatelessWidget {
  const SmartNavigationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Grocery Navigator',
      theme: AppTheme.lightTheme,
      initialRoute: '/login',
      onGenerateRoute: _generateRoute,
    );
  }

  static Route<dynamic>? _generateRoute(RouteSettings settings) {
    Widget? screen;
    switch (settings.name) {
      case '/login':
        screen = const LoginScreen();
        break;
      case '/register':
        screen = const RegisterScreen();
        break;
      case '/home':
        screen = const MainNavigationScreen();
        break;
      case '/map':
        screen = const MapScreen();
        break;
      case '/addList':
        screen = const AddListScreen();
        break;
      case '/shoppingList':
        screen = const ShoppingListScreen();
        break;
      case '/profile':
        screen = const ProfileScreen();
        break;
      case '/editProfile':
        screen = const EditProfileScreen();
        break;
      case '/notificationPreferences':
        screen = const NotificationPreferencesScreen();
        break;
      case '/privacySecurity':
        screen = const PrivacySecurityScreen();
        break;
      case '/helpSupport':
        screen = const HelpSupportScreen();
        break;
      default:
        return null;
    }

    // Use custom page route without Hero animations for secondary screens
    final isSecondaryScreen = settings.name != '/login' && 
                              settings.name != '/register' && 
                              settings.name != '/home';
    
    if (isSecondaryScreen) {
      return PageRouteBuilder<dynamic>(
        settings: settings,
        pageBuilder: (context, animation, secondaryAnimation) => screen!,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 200),
        maintainState: true,
        opaque: true,
      );
    }
    
    return MaterialPageRoute<dynamic>(
      settings: settings,
      builder: (context) => screen!,
    );
  }
}
