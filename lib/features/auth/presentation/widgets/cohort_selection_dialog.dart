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
    30,
    (index) => DateTime.now().year - index,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.school,
                      color: AppColors.primaryBlue,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Welcome to Baret Scholars!',
                        style: AppTextStyles.h3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Please tell us about your cohort to complete your profile.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textGray,
                  ),
                ),
                const SizedBox(height: 24),

                // Cohort Year Selection
                Text('Cohort Year', style: AppTextStyles.h4),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.textGray.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      hint: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Select your cohort year'),
                      ),
                      value: _selectedYear,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      borderRadius: BorderRadius.circular(8),
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
                const SizedBox(height: 24),

                // Cohort Region Selection
                Text('Cohort Region', style: AppTextStyles.h4),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.textGray.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Select your region'),
                      ),
                      value: _selectedRegion,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      borderRadius: BorderRadius.circular(8),
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
                const SizedBox(height: 32),

                // Info box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.softGray,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'This helps connect you with other scholars from your cohort.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textGray,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Submit button
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
                      backgroundColor: AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Continue',
                      style: AppTextStyles.button.copyWith(
                        color: Colors.white,
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
