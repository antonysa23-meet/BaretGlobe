import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/settings_repository.dart';
import '../providers/settings_provider.dart';
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
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.black,
        elevation: 0,
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Error loading settings', style: AppTextStyles.h4),
              const SizedBox(height: 8),
              Text('$error', style: AppTextStyles.bodySmall),
            ],
          ),
        ),
        data: (preferences) {
          if (preferences == null) {
            return const Center(child: Text('No preferences found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location Tracking Section
                _buildLocationTrackingSection(
                  context,
                  ref,
                  alumnusId,
                  preferences.locationTrackingEnabled,
                  lastUpdateAsync,
                ),
                const SizedBox(height: 24),

                // Manual Location Override Section
                _buildManualLocationSection(
                  context,
                  ref,
                  alumnusId,
                  preferences,
                ),
                const SizedBox(height: 24),

                // Visibility Section
                _buildVisibilitySection(
                  context,
                  ref,
                  alumnusId,
                  preferences.visibleOnGlobe,
                ),
                const SizedBox(height: 24),

                // About Section
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
    AsyncValue<DateTime?> lastUpdateAsync,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Location Tracking', style: AppTextStyles.h4),
            const SizedBox(height: 4),
            Text(
              'Share your location with the Baret Scholars community',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textGray),
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
                loading: () => const Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Loading...'),
                  ],
                ),
                error: (error, stack) => const SizedBox.shrink(),
                data: (lastUpdate) {
                  if (lastUpdate == null) {
                    return Row(
                      children: [
                        Icon(Icons.info_outline, size: 20, color: AppColors.textGray),
                        const SizedBox(width: 12),
                        Text(
                          'No location updates yet',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textGray,
                          ),
                        ),
                      ],
                    );
                  }

                  final timeAgo = _formatTimeAgo(lastUpdate);
                  return Row(
                    children: [
                      Icon(Icons.schedule, size: 20, color: AppColors.secondarySage),
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
                              DateFormat('MMM d, yyyy \'at\' h:mm a').format(lastUpdate),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textGray,
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
                  Icon(
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Manual Location Override', style: AppTextStyles.h4),
            const SizedBox(height: 4),
            Text(
              'Set a custom location instead of GPS tracking',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textGray),
            ),
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
                                content: Text('Manual location cleared - GPS tracking resumed'),
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
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: AppColors.primaryBlue,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      hasManualLocation
                          ? 'While active, automatic GPS tracking is paused. Your location will show as the manually set position.'
                          : 'Set a custom location that will be displayed instead of your actual GPS position. Choose how long it should last.',
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Globe Visibility', style: AppTextStyles.h4),
            const SizedBox(height: 4),
            Text(
              'Control whether you appear on the global alumni map',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textGray),
            ),
            const SizedBox(height: 16),

            // Toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                isVisible ? 'Visible on Globe' : 'Hidden from Globe',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                isVisible
                    ? 'Other alumni can see your location'
                    : 'Your location is hidden from others',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textGray,
                ),
              ),
              value: isVisible,
              activeColor: AppColors.secondarySage,
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
                        backgroundColor: value ? Colors.green : AppColors.textGray,
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
                  Icon(
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

  Widget _buildAboutSection(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('About', style: AppTextStyles.h4),
            const SizedBox(height: 16),

            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final version = snapshot.data?.version ?? '...';
                final buildNumber = snapshot.data?.buildNumber ?? '...';

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.info, color: AppColors.secondarySage),
                  title: const Text('Version'),
                  subtitle: Text('$version ($buildNumber)'),
                );
              },
            ),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.school, color: AppColors.secondarySage),
              title: const Text('About Baret Scholars'),
              subtitle: const Text('Learn more about our community'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // TODO: Open about page or website
              },
            ),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.privacy_tip, color: AppColors.secondarySage),
              title: const Text('Privacy Policy'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // TODO: Open privacy policy
              },
            ),
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
