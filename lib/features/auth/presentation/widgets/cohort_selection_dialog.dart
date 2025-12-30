import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Dialog for selecting cohort year and region after first login
class CohortSelectionDialog extends StatefulWidget {
  const CohortSelectionDialog({super.key});

  @override
  State<CohortSelectionDialog> createState() => _CohortSelectionDialogState();
}

class _CohortSelectionDialogState extends State<CohortSelectionDialog> {
  int? _selectedYear;
  String? _selectedRegion;

  final List<int> _cohortYears = List.generate(
    35,
    (index) => 2025 + index,
  );

  final List<String> _cohortRegions = [
    'North America',
    'South America',
    'Europe',
    'Africa',
    'Middle East',
    'Asia',
    'Oceania',
  ];

  @override
  Widget build(BuildContext context) {
    final canSubmit = _selectedYear != null && _selectedRegion != null;

    return WillPopScope(
      onWillPop: () async => false, // Prevent dismissing
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section - more compact
                Row(
                  children: [
                    const Icon(
                      Icons.school,
                      color: AppColors.accentGold,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Before we start',
                        style: AppTextStyles.h4.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Tell us about your cohort to connect with other scholars.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textGray,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 24),

                // Cohort Year Selection
                Text(
                  'Cohort Year',
                  style: AppTextStyles.label.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: AppColors.textGray.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      hint: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'Select year',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 14,
                          ),
                        ),
                      ),
                      value: _selectedYear,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      borderRadius: BorderRadius.circular(8),
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 14,
                      ),
                      items: _cohortYears.map((year) {
                        return DropdownMenuItem<int>(
                          value: year,
                          child: Text(year.toString()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedYear = value;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Cohort Region Selection
                Text(
                  'Your Region',
                  style: AppTextStyles.label.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: AppColors.textGray.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'Select region',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 14,
                          ),
                        ),
                      ),
                      value: _selectedRegion,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      borderRadius: BorderRadius.circular(8),
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 14,
                      ),
                      items: _cohortRegions.map((region) {
                        return DropdownMenuItem<String>(
                          value: region,
                          child: Text(region),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedRegion = value;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Info box - more compact
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.accentGold.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppColors.accentGold.withOpacity(0.9),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your cohort information helps you discover and connect with other scholars.',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textGray,
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Submit button - more compact
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: canSubmit
                        ? () {
                            Navigator.pop(context, {
                              'year': _selectedYear,
                              'region': _selectedRegion,
                            });
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentGold,
                      foregroundColor: AppColors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      disabledBackgroundColor: AppColors.neutralGray200,
                      disabledForegroundColor: AppColors.neutralGray400,
                    ),
                    child: Text(
                      'Continue',
                      style: AppTextStyles.button.copyWith(
                        color: AppColors.black,
                        fontSize: 14,
                        letterSpacing: 2.0,
                      ),
                    ),
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
