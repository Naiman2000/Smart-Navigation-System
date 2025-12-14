import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/store_layout_model.dart';
import '../services/navigation_service.dart' show NavigationService, Position;
import '../theme/app_theme.dart';

/// Widget for displaying turn-by-turn navigation guidance
class NavigationGuidanceWidget extends StatelessWidget {
  final Point? userPosition;
  final ProductModel? nextItem;
  final double? distance;

  const NavigationGuidanceWidget({
    super.key,
    this.userPosition,
    this.nextItem,
    this.distance,
  });

  @override
  Widget build(BuildContext context) {
    if (nextItem == null || userPosition == null) {
      return const SizedBox.shrink();
    }

    final navigationService = NavigationService();
    final itemPoint = Point(
      x: nextItem!.location.coordinates.x,
      y: nextItem!.location.coordinates.y,
    );

    // Calculate bearing and direction
    final bearing = navigationService.getBearing(userPosition!, itemPoint);
    final directionInstruction = navigationService.getDirectionInstruction(bearing);
    final calculatedDistance = distance ?? 
        navigationService.calculateDistance(
          Position(x: userPosition!.x, y: userPosition!.y),
          Position(x: itemPoint.x, y: itemPoint.y),
        );

    // Estimate time (walking speed ~1.4 m/s)
    final estimatedTime = Duration(seconds: (calculatedDistance / 1.4).round());

    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingM),
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Next item name
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.navigation,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Next Item',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      nextItem!.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingM),

          // Direction and distance
          Row(
            children: [
              // Direction icon
              _getDirectionIcon(bearing),
              const SizedBox(width: AppTheme.spacingS),
              
              // Instruction
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      directionInstruction,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.straighten,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDistance(calculatedDistance),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDuration(estimatedTime),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Location details
          if (nextItem!.location.aisle.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingS),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingS,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.store,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${nextItem!.location.aisle} • Shelf ${nextItem!.location.shelf}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _getDirectionIcon(double bearing) {
    IconData icon;
    double rotation = 0;

    if (bearing >= 337.5 || bearing < 22.5) {
      icon = Icons.arrow_upward;
      rotation = 0;
    } else if (bearing >= 22.5 && bearing < 67.5) {
      icon = Icons.arrow_upward;
      rotation = 45;
    } else if (bearing >= 67.5 && bearing < 112.5) {
      icon = Icons.arrow_forward;
      rotation = 90;
    } else if (bearing >= 112.5 && bearing < 157.5) {
      icon = Icons.arrow_downward;
      rotation = 135;
    } else if (bearing >= 157.5 && bearing < 202.5) {
      icon = Icons.arrow_downward;
      rotation = 180;
    } else if (bearing >= 202.5 && bearing < 247.5) {
      icon = Icons.arrow_downward;
      rotation = 225;
    } else if (bearing >= 247.5 && bearing < 292.5) {
      icon = Icons.arrow_back;
      rotation = 270;
    } else {
      icon = Icons.arrow_upward;
      rotation = 315;
    }

    return Transform.rotate(
      angle: rotation * 3.14159 / 180,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 24,
        ),
      ),
    );
  }

  String _formatDistance(double distance) {
    if (distance < 1.0) {
      return '${(distance * 100).round()} cm';
    }
    return '${distance.toStringAsFixed(1)} m';
  }

  String _formatDuration(Duration duration) {
    if (duration.inSeconds < 60) {
      return '${duration.inSeconds}s';
    }
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (seconds == 0) {
      return '${minutes}m';
    }
    return '${minutes}m ${seconds}s';
  }
}

