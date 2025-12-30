import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/countries.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../globe/data/repositories/location_repository.dart';
import '../../../globe/presentation/providers/globe_provider.dart';
import '../../../home/presentation/providers/navigation_provider.dart';
import '../../data/repositories/settings_repository.dart';
import '../providers/settings_provider.dart';
import '../widgets/country_selection_dialog.dart';
import '../widgets/location_tracking_toggle.dart';
import '../widgets/manual_location_dialog.dart';

/// Settings screen for managing app preferences
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
      data: (state) {
        return state.when(
          authenticated: (user, alumnusId) {
            if (alumnusId == null) {
              return const Scaffold(
                body: Center(child: Text('Loading profile...')),
              );
            }
            return _buildAuthenticatedView(context, ref, alumnusId);
          },
          unauthenticated: () => const Scaffold(
            body: Center(child: Text('Please sign in to view settings')),
          ),
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (message, code) => Scaffold(
            body: Center(child: Text('Error: $message')),
          ),
        );
      },
    );
  }

  Widget _buildAuthenticatedView(
    BuildContext context,
    WidgetRef ref,
    String alumnusId,
  ) {
    final settingsAsync = ref.watch(settingsProvider(alumnusId));
    final lastUpdateAsync = ref.watch(lastLocationUpdateProvider(alumnusId));

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          title: Padding(
            padding: const EdgeInsets.all(5),
            child: Image.asset(
              'assets/images/Baret.png',
              height: 50,
              fit: BoxFit.contain,
            ),
          ),
          centerTitle: true,
          toolbarHeight: 80,
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.black,
          elevation: 0,
        ),
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              const Text('Error loading settings', style: AppTextStyles.h4),
              const SizedBox(height: 8),
              Text('$error', style: AppTextStyles.bodySmall),
            ],
          ),
        ),
        data: (preferences) {
          if (preferences == null) {
            return const Center(child: Text('No preferences found'));
          }

          final currentLocationAsync = ref.watch(
            currentUserLocationProvider(alumnusId),
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Country Warning Banner
                currentLocationAsync.when(
                  data: (location) => _buildCountryBanner(
                    context,
                    ref,
                    alumnusId,
                    location?.country,
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                // Manual Location Override Section
                _buildManualLocationSection(
                  context,
                  ref,
                  alumnusId,
                  preferences,
                ),
                const SizedBox(height: 24),

                // Location Tracking Section (with visibility toggle)
                _buildLocationTrackingSection(
                  context,
                  ref,
                  alumnusId,
                  preferences.locationTrackingEnabled,
                  preferences.visibleOnGlobe,
                  lastUpdateAsync,
                ),
                const SizedBox(height: 24),

                // About Section (at the bottom)
                _buildAboutSection(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLocationTrackingSection(
    BuildContext context,
    WidgetRef ref,
    String alumnusId,
    bool isEnabled,
    bool visibleOnGlobe,
    AsyncValue<DateTime?> lastUpdateAsync,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Location Tracking', style: AppTextStyles.h4),
            const SizedBox(height: 4),
            Text(
              'Share your location with the Baret Scholars community',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textGray,
                fontStyle: FontStyle.normal,
              ),
            ),
            const SizedBox(height: 16),

            // Toggle
            LocationTrackingToggle(
              enabled: isEnabled,
              onChanged: (value) async {
                final provider = ref.read(settingsProvider(alumnusId).notifier);
                await provider.toggleLocationTracking(value);
              },
            ),

            // Last update time
            if (isEnabled) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              lastUpdateAsync.when(
                loading: () => Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Loading...',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                  ],
                ),
                error: (error, stack) => const SizedBox.shrink(),
                data: (lastUpdate) {
                  if (lastUpdate == null) {
                    return Row(
                      children: [
                        const Icon(Icons.info_outline,
                            size: 20, color: AppColors.textGray),
                        const SizedBox(width: 12),
                        Text(
                          'No location updates yet',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textGray,
                            fontStyle: FontStyle.normal,
                          ),
                        ),
                      ],
                    );
                  }

                  final timeAgo = _formatTimeAgo(lastUpdate);
                  return Row(
                    children: [
                      const Icon(Icons.schedule,
                          size: 20, color: AppColors.secondarySage),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Last updated $timeAgo',
                              style: AppTextStyles.bodyMedium,
                            ),
                            Text(
                              DateFormat('MMM d, yyyy \'at\' h:mm a')
                                  .format(lastUpdate),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textGray,
                                fontStyle: FontStyle.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],

            // Visibility Toggle
            if (isEnabled) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    visibleOnGlobe ? Icons.visibility : Icons.visibility_off,
                    size: 24,
                    color: visibleOnGlobe
                        ? AppColors.secondarySage
                        : AppColors.textGray,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Visible on Globe',
                          style: AppTextStyles.bodyLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          visibleOnGlobe
                              ? 'Others can see your location on the map'
                              : 'Your location is hidden from the map',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textGray,
                            fontStyle: FontStyle.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: visibleOnGlobe,
                    onChanged: (value) async {
                      final settingsRepo = ref.read(settingsRepositoryProvider);
                      await settingsRepo.updateVisibility(alumnusId, value);
                      ref.invalidate(settingsProvider(alumnusId));
                    },
                    activeTrackColor: AppColors.secondarySage.withOpacity(0.5),
                    activeThumbColor: AppColors.secondarySage,
                  ),
                ],
              ),
            ],

            // Info text
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.softGray,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 20,
                    color: AppColors.primaryBlue,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isEnabled
                          ? 'Your location is tracked continuously, even when the app is closed. Updates happen automatically every 30 minutes.'
                          : 'Enable location tracking to appear on the global alumni map.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textGray,
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualLocationSection(
    BuildContext context,
    WidgetRef ref,
    String alumnusId,
    dynamic preferences,
  ) {
    final hasManualLocation = preferences.manualLocationLatitude != null &&
        preferences.manualLocationLongitude != null;

    String? statusText;
    Color? statusColor;

    if (hasManualLocation) {
      final city = preferences.manualLocationCity ?? 'Unknown';
      final country = preferences.manualLocationCountry ?? 'Unknown';
      final expiresAt = preferences.manualLocationExpiresAt;

      if (expiresAt == null) {
        statusText = 'Set to $city, $country (Forever)';
        statusColor = AppColors.secondarySage;
      } else {
        final timeLeft = expiresAt.difference(DateTime.now());
        if (timeLeft.isNegative) {
          statusText = 'Expired - GPS tracking resumed';
          statusColor = AppColors.error;
        } else {
          final hoursLeft = timeLeft.inHours;
          final daysLeft = timeLeft.inDays;
          String durationText;

          if (daysLeft > 0) {
            durationText = '$daysLeft ${daysLeft == 1 ? 'day' : 'days'}';
          } else if (hoursLeft > 0) {
            durationText = '$hoursLeft ${hoursLeft == 1 ? 'hour' : 'hours'}';
          } else {
            durationText = '${timeLeft.inMinutes} minutes';
          }

          statusText = 'Set to $city, $country ($durationText left)';
          statusColor = AppColors.primaryBlue;
        }
      }
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Manually Set my Location', style: AppTextStyles.h4),
            const SizedBox(height: 16),

            // Status
            if (hasManualLocation) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor?.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: statusColor ?? AppColors.textGray,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_pin,
                      size: 20,
                      color: statusColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        statusText ?? '',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final result = await showDialog<bool>(
                        context: context,
                        builder: (context) => ManualLocationDialog(
                          alumnusId: alumnusId,
                        ),
                      );

                      if (result == true) {
                        // Refresh settings
                        ref.invalidate(settingsProvider(alumnusId));
                      }
                    },
                    icon: Icon(
                      hasManualLocation ? Icons.edit : Icons.add_location,
                    ),
                    label: Text(
                      hasManualLocation ? 'Change Location' : 'Set Location',
                    ),
                  ),
                ),
                if (hasManualLocation) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Clear Manual Location?'),
                            content: const Text(
                              'This will resume automatic GPS tracking.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.error,
                                ),
                                child: const Text('Clear'),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true) {
                          final settingsRepo = SettingsRepository();
                          await settingsRepo.clearManualLocation(alumnusId);
                          ref.invalidate(settingsProvider(alumnusId));

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Manual location cleared - GPS tracking resumed'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisibilitySection(
    BuildContext context,
    WidgetRef ref,
    String alumnusId,
    bool isVisible,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                isVisible ? 'Visible on Globe' : 'Hidden from Globe',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.normal,
                ),
              ),
              subtitle: Text(
                isVisible
                    ? 'Other alumni can see your location'
                    : 'Your location is hidden from others',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textGray,
                  fontStyle: FontStyle.normal,
                ),
              ),
              value: isVisible,
              activeThumbColor: AppColors.accentGold,
              onChanged: (value) async {
                // Show confirmation dialog when disabling
                if (!value) {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Hide from Globe?'),
                      content: const Text(
                        'Are you sure you want to hide yourself from the global alumni map? '
                        'Other scholars will not be able to see your location.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                          ),
                          child: const Text('Hide'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed != true) return;
                }

                // Update visibility
                try {
                  final settingsRepo = SettingsRepository();
                  await settingsRepo.updateVisibility(alumnusId, value);
                  ref.invalidate(settingsProvider(alumnusId));

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          value
                              ? 'You are now visible on the globe'
                              : 'You are now hidden from the globe',
                        ),
                        backgroundColor:
                            value ? Colors.green : AppColors.textGray,
                      ),
                    );
                  }
                } catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error updating visibility: $error'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
            ),

            // Info text
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.softGray,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 20,
                    color: AppColors.primaryBlue,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isVisible
                          ? 'Your location is currently visible to all Baret Scholars. You can hide it at any time for privacy.'
                          : 'Your location is currently hidden. You can make it visible again at any time to reconnect with other scholars.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textGray,
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountryBanner(
    BuildContext context,
    WidgetRef ref,
    String alumnusId,
    String? currentCountry,
  ) {
    // Check if country is invalid
    final bool shouldShowBanner = currentCountry == null ||
        currentCountry == 'N/A' ||
        currentCountry == 'Unknown' ||
        currentCountry.isEmpty;

    if (!shouldShowBanner) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
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
                    fontFamily: 'GuyotHeadline',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.normal,
                    color: Colors.orange.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'We need to know which country you\'re in to connect you with nearby alumni.',
                  style: TextStyle(
                    fontFamily: 'GuyotHeadline',
                    fontSize: 14,
                    fontStyle: FontStyle.normal,
                    color: Colors.orange.shade800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () => _showCountrySelectionDialog(
              context,
              ref,
              alumnusId,
              currentCountry,
            ),
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

  Future<void> _showCountrySelectionDialog(
    BuildContext context,
    WidgetRef ref,
    String alumnusId,
    String? currentCountry,
  ) async {
    await showDialog(
      context: context,
      barrierDismissible: false, // Must select a country
      builder: (dialogContext) => CountrySelectionDialog(
        currentCountry: currentCountry,
        onCountrySelected: (selectedCountry) async {
          try {
            // Validate that the country is in the official list
            if (!Countries.isValid(selectedCountry)) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Invalid country: $selectedCountry'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
              return;
            }

            // Standardize the country name before saving
            final standardizedCountry =
                Countries.standardize(selectedCountry) ?? selectedCountry;

            // Update country in database
            final locationRepo = LocationRepository();
            await locationRepo.updateManualCountry(
              alumnusId: alumnusId,
              country: standardizedCountry,
            );

            // Refresh the location provider
            ref.invalidate(currentUserLocationProvider(alumnusId));

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Country updated to $standardizedCountry'),
                  backgroundColor: AppColors.success,
                ),
              );
            }
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
        },
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('About', style: AppTextStyles.h4),
            const SizedBox(height: 16),
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final version = snapshot.data?.version ?? '...';
                final buildNumber = snapshot.data?.buildNumber ?? '...';

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:
                      const Icon(Icons.info, color: AppColors.secondarySage),
                  title: const Text('Version'),
                  subtitle: Text('$version ($buildNumber)'),
                );
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.school, color: AppColors.secondarySage),
              title: const Text('About Baret Scholars'),
              subtitle: const Text('Learn more about our community'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // TODO: Open about page or website
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading:
                  const Icon(Icons.privacy_tip, color: AppColors.secondarySage),
              title: const Text('Privacy Policy'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // TODO: Open privacy policy
              },
            ),

            const SizedBox(height: 32),

            // Log Out Button
            Consumer(
              builder: (context, consumerRef, child) {
                final authRepository = consumerRef.read(authRepositoryProvider);

                return Center(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      // Show confirmation dialog
                      final shouldLogout = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Log Out'),
                          content:
                              const Text('Are you sure you want to log out?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Log Out'),
                            ),
                          ],
                        ),
                      );

                      if (shouldLogout == true && context.mounted) {
                        try {
                          // Call logout (this triggers Supabase auth state change)
                          await authRepository.signOut();

                          // Reset navigation to Globe screen for next login
                          consumerRef.read(navigationProvider.notifier).state = 1;

                          // Force refresh the auth state provider
                          // This ensures the app navigates back to login screen
                          consumerRef.invalidate(authStateProvider);
                        } catch (e) {
                          if (context.mounted) {
                            // Show error
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error logging out: $e'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Log Out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 16,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'just now';
    }
  }
}
