import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../globe/presentation/widgets/baret_profile_avatar.dart';

/// Reusable widget for displaying a conversation member in a list
class MemberListTile extends StatelessWidget {
  final String name;
  final int cohortYear;
  final bool isAdmin;
  final VoidCallback? onTap;

  const MemberListTile({
    super.key,
    required this.name,
    required this.cohortYear,
    this.isAdmin = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cohortColor = AppColors.getCohortColor(cohortYear);

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: BaretProfileAvatar(
        name: name,
        backgroundColor: cohortColor,
        size: 48,
        borderWidth: 2,
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              name,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isAdmin) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accentGold,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'ADMIN',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        'Class of $cohortYear',
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textGray,
        ),
      ),
    );
  }
}
