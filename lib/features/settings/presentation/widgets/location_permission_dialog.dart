import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Dialog to explain and request location permission on first sign-in
class LocationPermissionDialog {
  /// Show the location permission dialog
  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.public, color: AppColors.accentGold, size: 32),
            SizedBox(width: 12),
            Text('Share Your Location'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome to Baret Scholars Globe!',
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const Text(
              'See where alumni are around the world and let others see where you are.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 16),
            _buildFeatureItem(
              Icons.map,
              'Appear on the global alumni map',
            ),
            const SizedBox(height: 8),
            _buildFeatureItem(
              Icons.update,
              'Automatic background updates (daily)',
            ),
            const SizedBox(height: 8),
            _buildFeatureItem(
              Icons.privacy_tip_outlined,
              'Your exact location is kept private',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.neutralGray100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.neutralGray200,
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 22,
                    color: AppColors.primaryBlue,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You can change this setting anytime in Settings.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textGray,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.neutralGray400,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentGold,
              foregroundColor: AppColors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text('Enable Location'),
          ),
        ],
      ),
    );
  }

  static Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.secondarySage),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmall,
          ),
        ),
      ],
    );
  }
}
