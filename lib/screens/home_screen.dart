import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    final user = _firebaseService.currentUser;
    final displayName = user?.displayName ?? 'User';

    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Smart Navigation'),
        actions: [
          Semantics(
            label: 'Profile button',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.person),
              onPressed: () => Navigator.pushNamed(context, '/profile'),
              tooltip: 'Profile',
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Card(
              elevation: AppTheme.elevation4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusL),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusL),
                ),
                padding: const EdgeInsets.all(AppTheme.spacingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.waving_hand,
                          color: AppTheme.textOnPrimary,
                          size: 32,
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back!',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: AppTheme.textOnPrimary.withOpacity(0.9),
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacingXS),
                              Text(
                                displayName,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textOnPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    Text(
                      'Your smart shopping assistant is here to help you navigate the store efficiently.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textOnPrimary.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppTheme.spacingL),

            // Features Section
            Text(
              'Features',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),

            // Features Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: AppTheme.spacingM,
              mainAxisSpacing: AppTheme.spacingM,
              childAspectRatio: 1.2, // Increased to prevent overflow
              children: [
                _buildFeatureCard(
                  context,
                  'Shopping List',
                  Icons.shopping_basket,
                  AppTheme.secondaryColor,
                  'View your lists',
                  '/shoppingList',
                ),
                _buildFeatureCard(
                  context,
                  'Add Items',
                  Icons.add_circle_outline,
                  AppTheme.accentColor,
                  'Create new list',
                  '/addList',
                ),
                _buildFeatureCard(
                  context,
                  'Store Map',
                  Icons.map_outlined,
                  const Color(0xFF9C27B0), // Purple
                  'Navigate store',
                  '/map',
                ),
                _buildFeatureCard(
                  context,
                  'Profile',
                  Icons.person_outline,
                  const Color(0xFF009688), // Teal
                  'Account settings',
                  '/profile',
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spacingL),

            // Quick Actions
            Text(
              'Quick Actions',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),

            Card(
              elevation: AppTheme.elevation2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: Column(
                children: [
                  Semantics(
                    label: 'Create shopping list',
                    button: true,
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(AppTheme.spacingS),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusS),
                        ),
                        child: const Icon(
                          Icons.shopping_cart,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      title: Text(
                        'Create Shopping List',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        'Start a new shopping list',
                        style: theme.textTheme.bodySmall,
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                      onTap: () => Navigator.pushNamed(context, '/addList'),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingM,
                        vertical: AppTheme.spacingS,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Semantics(
                    label: 'View store map',
                    button: true,
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(AppTheme.spacingS),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusS),
                        ),
                        child: const Icon(
                          Icons.map,
                          color: AppTheme.secondaryColor,
                        ),
                      ),
                      title: Text(
                        'View Store Map',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        'Navigate to products',
                        style: theme.textTheme.bodySmall,
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                      onTap: () => Navigator.pushNamed(context, '/map'),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingM,
                        vertical: AppTheme.spacingS,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacingXXL),
          ],
        ),
      ),
      floatingActionButton: Semantics(
        label: 'Create new shopping list',
        button: true,
        child: FloatingActionButton.extended(
          onPressed: () => Navigator.pushNamed(context, '/addList'),
          icon: const Icon(Icons.add),
          label: const Text('New List'),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String subtitle,
    String route,
  ) {
    final theme = Theme.of(context);
    
    return Semantics(
      label: '$title: $subtitle',
      button: true,
      child: Card(
        elevation: AppTheme.elevation2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, route),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingS),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                  child: Icon(
                    icon,
                    size: 28,
                    color: color,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
