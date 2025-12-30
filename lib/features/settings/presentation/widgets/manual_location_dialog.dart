import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/countries.dart';
import '../../data/repositories/settings_repository.dart';
import 'country_selection_dialog.dart';

/// Dialog for setting manual location override
class ManualLocationDialog extends ConsumerStatefulWidget {
  final String alumnusId;

  const ManualLocationDialog({
    super.key,
    required this.alumnusId,
  });

  @override
  ConsumerState<ManualLocationDialog> createState() =>
      _ManualLocationDialogState();
}

class _ManualLocationDialogState extends ConsumerState<ManualLocationDialog> {
  final _cityController = TextEditingController();
  String? _selectedCountry;
  final _formKey = GlobalKey<FormState>();

  String? _selectedDuration = '1_day';
  bool _isLoading = false;

  final Map<String, Duration?> _durationOptions = {
    '1_minute': const Duration(minutes: 1), // For testing
    '1_hour': const Duration(hours: 1),
    '1_day': const Duration(days: 1),
    '1_week': const Duration(days: 7),
    '1_month': const Duration(days: 30),
    'forever': null,
  };

  final Map<String, String> _durationLabels = {
    '1_minute': '1 Minute (Testing)',
    '1_hour': '1 Hour',
    '1_day': '1 Day',
    '1_week': '1 Week',
    '1_month': '1 Month',
    'forever': 'Forever',
  };

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  void _showCountryPicker() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => CountrySelectionDialog(
        currentCountry: _selectedCountry,
        enableIpDetection: false, // No IP detection for manual location
        onCountrySelected: (selectedCountry) {
          setState(() {
            _selectedCountry = selectedCountry;
          });
        },
      ),
    );
  }

  /// Normalize city name input
  ///
  /// - Trims whitespace
  /// - Capitalizes first letter of each word
  /// - Removes extra spaces
  String _normalizeCity(String input) {
    // Trim and remove extra spaces
    final trimmed = input.trim().replaceAll(RegExp(r'\s+'), ' ');

    if (trimmed.isEmpty) return trimmed;

    // Capitalize first letter of each word
    final words = trimmed.split(' ');
    final capitalizedWords = words.map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    });

    return capitalizedWords.join(' ');
  }

  Future<void> _saveManualLocation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCountry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a country'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate that the country is in the official list
    if (!Countries.isValid(_selectedCountry)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid country: $_selectedCountry'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final settingsRepo = SettingsRepository();
      final duration = _durationOptions[_selectedDuration];

      // Normalize and standardize inputs
      final normalizedCity = _normalizeCity(_cityController.text);
      final standardizedCountry =
          Countries.standardize(_selectedCountry!) ?? _selectedCountry!;

      await settingsRepo.setManualLocation(
        alumnusId: widget.alumnusId,
        city: normalizedCity,
        country: standardizedCountry,
        duration: duration,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Manual location set for ${_durationLabels[_selectedDuration]}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error setting location: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set Manual Location',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Your location will be set to this city instead of GPS tracking',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 24),

                // Country selector
                InkWell(
                  onTap: _showCountryPicker,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Country',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.public),
                      suffixIcon: Icon(Icons.arrow_drop_down),
                    ),
                    child: Text(
                      _selectedCountry ?? 'Select a country',
                      style: TextStyle(
                        color: _selectedCountry != null
                            ? AppColors.black
                            : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // City
                TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    hintText: 'e.g., Jerusalem',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_city),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter city';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Duration selection
                Text(
                  'Duration',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ..._durationOptions.keys.map((key) {
                  return RadioListTile<String>(
                    title: Text(_durationLabels[key]!),
                    value: key,
                    groupValue: _selectedDuration,
                    onChanged: (value) {
                      setState(() {
                        _selectedDuration = value;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  );
                }),
                const SizedBox(height: 24),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveManualLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentGold,
                          foregroundColor: AppColors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.black),
                                ),
                              )
                            : const Text('Set Location'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
