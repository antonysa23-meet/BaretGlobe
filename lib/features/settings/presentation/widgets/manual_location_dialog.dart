import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/geocoding_service.dart';
import '../../data/repositories/settings_repository.dart';

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
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _selectedDuration = '1_day';
  bool _isLoading = false;
  bool _isGeocodingLoading = false;

  final Map<String, Duration?> _durationOptions = {
    '1_hour': const Duration(hours: 1),
    '1_day': const Duration(days: 1),
    '1_week': const Duration(days: 7),
    '1_month': const Duration(days: 30),
    'forever': null,
  };

  final Map<String, String> _durationLabels = {
    '1_hour': '1 Hour',
    '1_day': '1 Day',
    '1_week': '1 Week',
    '1_month': '1 Month',
    'forever': 'Forever',
  };

  @override
  void dispose() {
    _latitudeController.dispose();
    _longitudeController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _geocodeLocation() async {
    if (_latitudeController.text.isEmpty ||
        _longitudeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter latitude and longitude first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isGeocodingLoading = true;
    });

    try {
      final lat = double.parse(_latitudeController.text);
      final lng = double.parse(_longitudeController.text);

      final geocodingService = GeocodingService();
      final city = await geocodingService.approximateToNearestCity(lat, lng);
      final country = await geocodingService.getCountry(lat, lng);

      setState(() {
        _cityController.text = city ?? 'Unknown';
        _countryController.text = country ?? 'to be determined';
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error geocoding: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isGeocodingLoading = false;
      });
    }
  }

  Future<void> _saveManualLocation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final settingsRepo = SettingsRepository();
      final duration = _durationOptions[_selectedDuration];

      await settingsRepo.setManualLocation(
        alumnusId: widget.alumnusId,
        latitude: double.parse(_latitudeController.text),
        longitude: double.parse(_longitudeController.text),
        city: _cityController.text,
        country: _countryController.text,
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
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
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
                  'Your location will be set to this position instead of GPS tracking',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 24),

                // Latitude
                TextFormField(
                  controller: _latitudeController,
                  decoration: const InputDecoration(
                    labelText: 'Latitude',
                    hintText: 'e.g., 31.7683',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter latitude';
                    }
                    final lat = double.tryParse(value);
                    if (lat == null || lat < -90 || lat > 90) {
                      return 'Invalid latitude (-90 to 90)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Longitude
                TextFormField(
                  controller: _longitudeController,
                  decoration: const InputDecoration(
                    labelText: 'Longitude',
                    hintText: 'e.g., 35.2137',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter longitude';
                    }
                    final lng = double.tryParse(value);
                    if (lng == null || lng < -180 || lng > 180) {
                      return 'Invalid longitude (-180 to 180)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Geocode button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isGeocodingLoading ? null : _geocodeLocation,
                    icon: _isGeocodingLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search),
                    label: Text(_isGeocodingLoading
                        ? 'Finding city...'
                        : 'Find city from coordinates'),
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
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter city';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Country
                TextFormField(
                  controller: _countryController,
                  decoration: const InputDecoration(
                    labelText: 'Country',
                    hintText: 'e.g., Israel',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter country';
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
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveManualLocation,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Set Location'),
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
