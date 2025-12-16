import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'map_screen.dart';
import 'shopping_list_screen.dart';
import 'profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => MainNavigationScreenState();
}

// Public extension to allow child screens to switch tabs
extension MainNavigationExtension on BuildContext {
  void switchToMainTab(int index) {
    MainNavigationScreenState.navigateToTab(this, index);
  }
  
  MainNavigationScreenState? getMainNavigationState() {
    return findAncestorStateOfType<MainNavigationScreenState>();
  }
}

class MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  bool _isReady = false;

  // Lazy-loaded screens - only create when accessed
  final Map<int, Widget> _screenCache = {};

  @override
  void initState() {
    super.initState();
    // Delay initial screen creation until after navigation completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isReady = true;
        });
      }
    });
  }

  Widget _getScreen(int index) {
    // Return cached screen if exists, otherwise create lazy builder
    if (!_screenCache.containsKey(index)) {
      _screenCache[index] = _LazyScreenBuilder(
        index: index,
        onBuild: (Widget screen) {
          // Update cache with actual screen when it's built
          if (mounted) {
            setState(() {
              _screenCache[index] = screen;
            });
          }
        },
      );
    }
    return _screenCache[index]!;
  }

  void _onTabTapped(int index) {
    if (_isReady) {
      setState(() {
        _selectedIndex = index;
        // Lazy load the screen if not already cached
        _getScreen(index);
      });
    }
  }

  void switchToTab(int index) {
    if (index >= 0 && index < 4 && _isReady) {
      setState(() {
        _selectedIndex = index;
        // Lazy load the screen if not already cached
        _getScreen(index);
      });
    }
  }

  static void navigateToTab(BuildContext context, int index) {
    final state = context.getMainNavigationState();
    if (state != null) {
      state.switchToTab(index);
    } else {
      // If not in MainNavigationScreen, navigate to home
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Future<bool> _onWillPop() async {
    // Check if we're actually on a secondary screen route
    // If ModalRoute shows a different route, we're on a secondary screen
    final currentRoute = ModalRoute.of(context);
    if (currentRoute != null) {
      final routeSettings = currentRoute.settings;
      // If route name is not '/home', we're on a secondary screen
      if (routeSettings.name != '/home' && routeSettings.name != null) {
        return true; // Allow normal pop for secondary screens
      }
    }

    // Check if Navigator can pop (secondary screen is open)
    final navigator = Navigator.of(context, rootNavigator: false);
    if (navigator.canPop()) {
      // Double-check: if we can pop, we're likely on a secondary screen
      return true; // Allow normal pop for secondary screens
    }

    // We're at the main navigation level (no secondary screens open)
    if (_selectedIndex != 0) {
      // If not on Home tab, navigate to Home tab
      setState(() {
        _selectedIndex = 0;
      });
      return false; // Don't exit app, just switch tabs
    }
    
    // If on Home tab, show exit confirmation
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit App?'),
        content: const Text('Are you sure you want to exit Grocery Navigator?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    return shouldExit ?? false;
  }

  bool _isSecondaryScreenOpen() {
    // Check if a secondary screen is open by examining the route
    final currentRoute = ModalRoute.of(context);
    if (currentRoute != null) {
      final routeName = currentRoute.settings.name;
      // If route name exists and is not '/home', we're on a secondary screen
      if (routeName != null && routeName != '/home') {
        return true;
      }
    }
    // Also check if Navigator can pop (indicates secondary screen is on stack)
    return Navigator.canPop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Only apply PopScope when we're actually on the main navigation screen
    // Secondary screens should handle their own back button
    final isSecondaryOpen = _isSecondaryScreenOpen();
    
    Widget scaffold = Scaffold(
        body: _isReady
            ? IndexedStack(
                index: _selectedIndex,
                children: List.generate(4, (index) {
                  // Only create lazy builder for current tab or previously accessed tabs
                  if (index == _selectedIndex || _screenCache.containsKey(index)) {
                    return _getScreen(index);
                  }
                  // Return empty placeholder for unaccessed tabs
                  return const SizedBox.shrink();
                }),
              )
            : const Center(
                child: CircularProgressIndicator(),
              ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: AppTheme.textSecondary,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 12,
          ),
          backgroundColor: AppTheme.surfaceColor,
          elevation: AppTheme.elevation4,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map),
              activeIcon: Icon(Icons.map),
              label: 'Map',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_basket),
              activeIcon: Icon(Icons.shopping_basket),
              label: 'List',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      );

    // Only wrap with PopScope when on main navigation, not when secondary screen is open
    if (isSecondaryOpen) {
      // When secondary screen is open, don't intercept back button
      return scaffold;
    }
    
    // When on main navigation, wrap with PopScope to handle back button
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (!didPop) {
          try {
            // Double-check we're still on main navigation
            if (_isSecondaryScreenOpen()) {
              // Secondary screen opened while we were checking - allow normal pop
              if (context.mounted && Navigator.canPop(context)) {
                Navigator.of(context).pop();
              }
              return;
            }
            
            // Handle main navigation back button
            final shouldPop = await _onWillPop();
            if (shouldPop) {
              // User confirmed exit - actually exit the app
              SystemNavigator.pop();
            }
          } catch (e) {
            debugPrint('Error in PopScope: $e');
            // If there's an error, try to allow normal pop
            if (context.mounted && Navigator.canPop(context)) {
              Navigator.of(context).pop();
            }
          }
        }
      },
      child: scaffold,
    );
  }
}

// Lazy screen builder that only creates the screen when it becomes visible
class _LazyScreenBuilder extends StatefulWidget {
  final int index;
  final Function(Widget) onBuild;

  const _LazyScreenBuilder({
    required this.index,
    required this.onBuild,
  });

  @override
  State<_LazyScreenBuilder> createState() => _LazyScreenBuilderState();
}

class _LazyScreenBuilderState extends State<_LazyScreenBuilder> {
  Widget? _screen;

  @override
  void initState() {
    super.initState();
    // Delay screen creation to avoid blocking
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _createScreen();
      }
    });
  }

  void _createScreen() {
    if (_screen != null) return;

    Widget screen;
    switch (widget.index) {
      case 0:
        screen = const HomeScreen();
        break;
      case 1:
        screen = MapScreen(key: MapScreen.globalKey);
        break;
      case 2:
        screen = const ShoppingListScreen();
        break;
      case 3:
        screen = const ProfileScreen();
        break;
      default:
        screen = const SizedBox.shrink();
    }

    if (mounted) {
      setState(() {
        _screen = screen;
      });
      widget.onBuild(screen);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while screen is being created
    if (_screen == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    return _screen!;
  }
}
