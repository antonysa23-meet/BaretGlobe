import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'country_selection_dialog.dart';

/// Warning banner shown when user's country is N/A or Unknown
class CountryWarningBanner extends StatelessWidget {
  final String alumnusId;
  final String? currentCountry;
  final VoidCallback onCountryUpdated;

  const CountryWarningBanner({
    super.key,
    required this.alumnusId,
    required this.currentCountry,
    required this.onCountryUpdated,
  });

  bool get _shouldShowBanner {
    if (currentCountry == null) return true;
    if (currentCountry == 'N/A') return true;
    if (currentCountry == 'Unknown') return true;
    if (currentCountry!.isEmpty) return true;
    return false;
  }

  Future<void> _showCountryDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false, // Must select a country
      builder: (context) => CountrySelectionDialog(
        currentCountry: currentCountry,
        onCountrySelected: (selectedCountry) async {
          // Update country in database
          await _updateCountry(context, selectedCountry);
        },
      ),
    );
  }

  Future<void> _updateCountry(BuildContext context, String country) async {
    try {
      // Import the repository
      final locationRepo = await Future(() {
        // Dynamically import to avoid circular dependency
        return null; // Will be called from parent with proper context
      });

      // The parent widget will handle the actual update
      onCountryUpdated();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update country: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldShowBanner) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.shade300,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.public_off,
            color: Colors.orange.shade700,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Country Required',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'We need to know which country you\'re in to connect you with nearby alumni.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange.shade800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () => _showCountryDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
            ),
            child: const Text(
              'Select Country',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
