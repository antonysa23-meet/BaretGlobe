import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/countries.dart';

/// Dialog for selecting country with IP-based detection
class CountrySelectionDialog extends StatefulWidget {
  final String? currentCountry;
  final Function(String selectedCountry) onCountrySelected;
  final bool enableIpDetection;

  const CountrySelectionDialog({
    super.key,
    this.currentCountry,
    required this.onCountrySelected,
    this.enableIpDetection = true,
  });

  @override
  State<CountrySelectionDialog> createState() => _CountrySelectionDialogState();
}

class _CountrySelectionDialogState extends State<CountrySelectionDialog> {
  final TextEditingController _searchController = TextEditingController();
  String? _detectedCountry;
  bool _isDetecting = false;
  bool _detectionFailed = false;
  List<String> _filteredCountries = Countries.all;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterCountries);
    if (widget.enableIpDetection) {
      _detectCountryFromIP();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Detect country from IP address using free API
  Future<void> _detectCountryFromIP() async {
    setState(() {
      _isDetecting = true;
      _detectionFailed = false;
    });

    try {
      final response = await http.get(
        Uri.parse('http://ip-api.com/json/'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final country = data['country'] as String?;

        if (country != null && country.isNotEmpty) {
          // Standardize the country name
          final standardized = Countries.standardize(country);
          if (standardized != null) {
            setState(() {
              _detectedCountry = standardized;
              _isDetecting = false;
            });
            return;
          }
        }
      }

      setState(() {
        _isDetecting = false;
        _detectionFailed = true;
      });
    } catch (e) {
      print('❌ Country detection from IP failed: $e');
      setState(() {
        _isDetecting = false;
        _detectionFailed = true;
      });
    }
  }

  void _filterCountries() {
    setState(() {
      _filteredCountries = Countries.search(_searchController.text);
    });
  }

  void _selectCountry(String country) {
    widget.onCountrySelected(country);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600, maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.public, color: AppColors.primary, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Select Your Country',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // IP Detection Result (only if enabled)
            if (widget.enableIpDetection && _isDetecting)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Detecting your location...',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            else if (widget.enableIpDetection && _detectedCountry != null)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.accentGold.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: AppColors.accentGold,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Detected from IP',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textGray,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _detectedCountry!,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _selectCountry(_detectedCountry!),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentGold,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: const Text('Select'),
                    ),
                  ],
                ),
              )
            else if (widget.enableIpDetection && _detectionFailed)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Could not detect location. Please search manually.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Divider
            if (widget.enableIpDetection && _detectedCountry != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Or search manually',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
              ),

            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search countries...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),

            // Country list
            Expanded(
              child: _filteredCountries.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No countries found',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredCountries.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final country = _filteredCountries[index];
                        final isSelected = country == widget.currentCountry;

                        return ListTile(
                          onTap: () => _selectCountry(country),
                          leading: Icon(
                            Icons.public,
                            color: isSelected
                                ? AppColors.primary
                                : Colors.grey[400],
                          ),
                          title: Text(
                            country,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.black,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: AppColors.primary,
                                )
                              : null,
                        );
                      },
                    ),
            ),

            // Bottom padding
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
