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
        title: Row(
          children: [
            const Icon(Icons.shopping_cart, size: 24),
            const SizedBox(width: AppTheme.spacingS),
            const Text('Grocery Navigator'),
          ],
        ),
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
                    Row(
                      children: [
                        const Icon(
                          Icons.store,
                          color: AppTheme.textOnPrimary,
                          size: 20,
                        ),
                        const SizedBox(width: AppTheme.spacingS),
                        Expanded(
                          child: Text(
                            'Find your groceries faster with smart in-store navigation',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textOnPrimary.withOpacity(0.9),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppTheme.spacingL),

            // Features Section
            Row(
              children: [
                const Icon(
                  Icons.shopping_bag,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: AppTheme.spacingS),
                Text(
                  'Shopping Tools',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
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
                  'My Lists',
                  Icons.shopping_basket,
                  AppTheme.secondaryColor,
                  'View grocery lists',
                  '/shoppingList',
                ),
                _buildFeatureCard(
                  context,
                  'New List',
                  Icons.add_shopping_cart,
                  AppTheme.accentColor,
                  'Create grocery list',
                  '/addList',
                ),
                _buildFeatureCard(
                  context,
                  'Store Aisles',
                  Icons.storefront,
                  const Color(0xFF9C27B0), // Purple
                  'Find products',
                  '/map',
                ),
                _buildFeatureCard(
                  context,
                  'My Account',
                  Icons.person_outline,
                  const Color(0xFF009688), // Teal
                  'Settings & profile',
                  '/profile',
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spacingL),

            // Quick Actions
            Row(
              children: [
                const Icon(
                  Icons.flash_on,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: AppTheme.spacingS),
                Text(
                  'Quick Actions',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
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
                        'Create Grocery List',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        'Add items to your shopping list',
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
                        'Browse Store Aisles',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        'Find where products are located',
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
        label: 'Create new grocery list',
        button: true,
        child: FloatingActionButton.extended(
          onPressed: () => Navigator.pushNamed(context, '/addList'),
          icon: const Icon(Icons.shopping_cart),
          label: const Text('New Grocery List'),
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
