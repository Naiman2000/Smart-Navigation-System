import 'package:flutter/material.dart';

enum CustomListTileVariant {
  standard,
  shopping,
  settings,
  product,
}

class CustomListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final IconData? leadingIcon;
  final Color? leadingIconColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enabled;
  final CustomListTileVariant variant;
  final bool isCompleted;
  final EdgeInsetsGeometry? contentPadding;

  const CustomListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.leadingIcon,
    this.leadingIconColor,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
    this.variant = CustomListTileVariant.standard,
    this.isCompleted = false,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      color: _getBackgroundColor(),
      child: InkWell(
        onTap: enabled ? onTap : null,
        onLongPress: enabled ? onLongPress : null,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: contentPadding ??
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              if (leading != null || leadingIcon != null) ...[
                _buildLeading(),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isCompleted ? Colors.grey : Colors.black87,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 14,
                          color: isCompleted ? Colors.grey : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeading() {
    if (leading != null) {
      return leading!;
    }

    if (leadingIcon != null) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (leadingIconColor ?? Colors.green).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          leadingIcon,
          color: isCompleted
              ? Colors.grey
              : (leadingIconColor ?? Colors.green),
          size: 24,
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Color _getBackgroundColor() {
    if (!enabled) {
      return Colors.grey.shade100;
    }

    if (isCompleted) {
      return Colors.grey.shade200;
    }

    switch (variant) {
      case CustomListTileVariant.shopping:
        return Colors.white;
      case CustomListTileVariant.settings:
        return Colors.white;
      case CustomListTileVariant.product:
        return Colors.green.shade50;
      case CustomListTileVariant.standard:
        return Colors.white;
    }
  }
}

// Shopping List Tile with checkbox
class ShoppingListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isCompleted;
  final ValueChanged<bool?> onChanged;
  final VoidCallback? onDelete;

  const ShoppingListTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.isCompleted,
    required this.onChanged,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      color: isCompleted ? Colors.grey.shade200 : Colors.white,
      child: CheckboxListTile(
        value: isCompleted,
        onChanged: onChanged,
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isCompleted ? Colors.grey : Colors.black87,
            decoration:
                isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 14,
                  color: isCompleted ? Colors.grey : Colors.grey.shade600,
                ),
              )
            : null,
        secondary: Icon(
          Icons.shopping_basket,
          color: isCompleted ? Colors.grey : Colors.green,
        ),
        controlAffinity: ListTileControlAffinity.trailing,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        activeColor: Colors.green,
      ),
    );
  }
}

// Settings List Tile
class SettingsListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;

  const SettingsListTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? Colors.green),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

