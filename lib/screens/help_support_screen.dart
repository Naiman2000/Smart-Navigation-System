import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final List<FAQItem> _faqs = [
    FAQItem(
      question: 'How do I create a grocery list?',
      answer:
          'Tap the "New List" button on the home screen or shopping lists screen. Enter a name for your list, then add items with their quantities and units. Tap "Save Grocery List" when done.',
    ),
    FAQItem(
      question: 'How do I add items to an existing list?',
      answer:
          'Go to "My Grocery Lists", find your list, and tap the edit icon (blue pencil). Add new items and tap "Update List" to save.',
    ),
    FAQItem(
      question: 'How does store navigation work?',
      answer:
          'The app uses Bluetooth beacons to detect your location in the store. Tap "Store Aisles" to view the store map and start navigation. Make sure Bluetooth is enabled on your device.',
    ),
    FAQItem(
      question: 'Can I use the app offline?',
      answer:
          'You can view your saved lists offline, but you\'ll need an internet connection to create new lists, sync data, and use navigation features.',
    ),
    FAQItem(
      question: 'How do I change my password?',
      answer:
          'Go to Profile > Privacy & Security > Change Password. Enter your current password, then your new password twice. Your password must be at least 8 characters with uppercase, lowercase, and numbers.',
    ),
    FAQItem(
      question: 'How do I delete a shopping list?',
      answer:
          'Go to "My Grocery Lists", find the list you want to delete, and tap the red delete icon. Confirm the deletion in the dialog.',
    ),
    FAQItem(
      question: 'The app is not detecting beacons. What should I do?',
      answer:
          'Make sure Bluetooth is enabled on your device. Go to Store Aisles screen and tap the play button to start scanning. If issues persist, try restarting the app or checking your device\'s Bluetooth settings.',
    ),
    FAQItem(
      question: 'How do I update my profile information?',
      answer:
          'Go to Profile > Edit Profile. You can update your name and phone number. Email cannot be changed for security reasons.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome Card
            Card(
              elevation: AppTheme.elevation2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withValues(alpha: 0.1),
                      AppTheme.primaryLight.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                padding: const EdgeInsets.all(AppTheme.spacingL),
                child: Column(
                  children: [
                    Icon(
                      Icons.help_outline,
                      size: 48,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    Text(
                      'How can we help you?',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    Text(
                      'Find answers to common questions or contact our support team',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
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

            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    context,
                    'Contact Support',
                    Icons.support_agent,
                    AppTheme.primaryColor,
                    () => _showContactSupportDialog(context),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: _buildQuickActionCard(
                    context,
                    'Report Issue',
                    Icons.bug_report,
                    AppTheme.errorColor,
                    () => _showReportIssueDialog(context),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spacingL),

            // FAQ Section
            Row(
              children: [
                Icon(
                  Icons.quiz,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: AppTheme.spacingS),
                Text(
                  'Frequently Asked Questions',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),

            // FAQ List
            ..._faqs.map((faq) => _buildFAQCard(context, faq)),

            const SizedBox(height: AppTheme.spacingL),

            // Contact Information
            Card(
              elevation: AppTheme.elevation2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.contact_support,
                          color: AppTheme.primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: AppTheme.spacingS),
                        Text(
                          'Contact Information',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    _buildContactRow(
                      context,
                      Icons.email,
                      'Email Support',
                      'support@grocerynavigator.com',
                      () => _launchEmail('support@grocerynavigator.com'),
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    _buildContactRow(
                      context,
                      Icons.phone,
                      'Phone Support',
                      '+1 (555) 123-4567',
                      () => _launchPhone('+15551234567'),
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    _buildContactRow(
                      context,
                      Icons.language,
                      'Website',
                      'www.grocerynavigator.com',
                      () => _launchURL('https://www.grocerynavigator.com'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppTheme.spacingL),

            // App Information
            Card(
              elevation: AppTheme.elevation1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                child: Column(
                  children: [
                    Text(
                      'Grocery Navigator',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXS),
                    Text(
                      'Version 1.0.0',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXS),
                    Text(
                      'Your smart grocery shopping assistant',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppTheme.spacingXL),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: AppTheme.elevation2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: AppTheme.spacingS),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQCard(BuildContext context, FAQItem faq) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      elevation: AppTheme.elevation1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: ExpansionTile(
        leading: Icon(
          Icons.help_outline,
          color: AppTheme.primaryColor,
        ),
        title: Text(
          faq.question,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Text(
              faq.answer,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingS),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.textSecondary),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  void _showContactSupportDialog(BuildContext context) {
    final emailController = TextEditingController();
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Your Email',
                  hintText: 'your.email@example.com',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppTheme.spacingM),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  hintText: 'Describe your issue...',
                  prefixIcon: Icon(Icons.message),
                ),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (emailController.text.isNotEmpty &&
                  messageController.text.isNotEmpty) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Support request sent! We\'ll get back to you soon.'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: AppTheme.textOnPrimary,
            ),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showReportIssueDialog(BuildContext context) {
    final issueController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report an Issue'),
        content: TextField(
          controller: issueController,
          decoration: const InputDecoration(
            labelText: 'Describe the issue',
            hintText: 'What went wrong?',
            prefixIcon: Icon(Icons.bug_report),
          ),
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (issueController.text.isNotEmpty) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Issue reported! Thank you for your feedback.'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: AppTheme.textOnPrimary,
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email?subject=Grocery Navigator Support');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not launch email app. Email: $email'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: Could not open email. Email: $email'),
          ),
        );
      }
    }
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not launch phone app'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Could not open phone app'),
          ),
        );
      }
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not launch website'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Could not open website'),
          ),
        );
      }
    }
  }
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({
    required this.question,
    required this.answer,
  });
}

