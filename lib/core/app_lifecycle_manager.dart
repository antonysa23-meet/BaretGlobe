import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/globe/data/repositories/location_repository.dart';
import '../features/settings/data/repositories/settings_repository.dart';
import '../features/settings/presentation/providers/settings_provider.dart';
import 'services/background_location_service.dart';

/// Manages app lifecycle to start/stop location tracking based on database settings
class AppLifecycleManager extends StatefulWidget {
  final Widget child;

  const AppLifecycleManager({
    super.key,
    required this.child,
  });

  @override
  State<AppLifecycleManager> createState() => _AppLifecycleManagerState();
}

class _AppLifecycleManagerState extends State<AppLifecycleManager>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Start tracking when app launches if enabled in database
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startTrackingIfEnabled();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('🔵 AppLifecycle: State changed to $state');

    if (state == AppLifecycleState.resumed) {
      // App came to foreground - start tracking if enabled
      _startTrackingIfEnabled();
    } else if (state == AppLifecycleState.paused) {
      // App went to background - stop foreground tracking (background continues)
      _stopForegroundTracking();
    }
  }

  /// Start location tracking services based on database preferences
  Future<void> _startTrackingIfEnabled() async {
    try {
      print('🔵 AppLifecycle: _startTrackingIfEnabled() called');

      // Get current authenticated user from Supabase
      final authUser = Supabase.instance.client.auth.currentUser;
      if (authUser == null) {
        print('⚠️ AppLifecycle: No authenticated user, skipping tracking');
        return;
      }
      print('✅ AppLifecycle: Authenticated user found: ${authUser.id}');

      // Get alumnus from database
      final locationRepo = LocationRepository();
      final alumnus = await locationRepo.getAlumnusByAuthUserId(authUser.id);

      if (alumnus == null) {
        print('⚠️ AppLifecycle: No alumnus found for auth user ${authUser.id}, skipping tracking');
        return;
      }
      print('✅ AppLifecycle: Alumnus found: ${alumnus.id} (${alumnus.name})');

      // Save alumnus ID to SharedPreferences for background service
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_alumnus_id', alumnus.id);
      print('✅ AppLifecycle: Saved alumnus ID to SharedPreferences');

      // Check if location tracking is enabled from database
      final settingsRepo = SettingsRepository();
      final userPrefs = await settingsRepo.getUserPreferences(alumnus.id);

      if (userPrefs == null) {
        print('❌ AppLifecycle: Failed to get/create user preferences');
        return;
      }

      print('📊 AppLifecycle: User preferences from database:');
      print('   - location_tracking_enabled: ${userPrefs.locationTrackingEnabled}');
      print('   - location_tracking_frequency: ${userPrefs.locationTrackingFrequency}');
      print('   - notifications_enabled: ${userPrefs.notificationsEnabled}');

      if (userPrefs.locationTrackingEnabled == true) {
        print('🔵 AppLifecycle: Location tracking enabled in database, starting services...');

        final container = ProviderScope.containerOf(context, listen: false);

        // Start background service (runs continuously even when app is closed)
        final backgroundService = container.read(backgroundLocationServiceProvider);
        final isRunning = await backgroundService.isRunning();
        if (!isRunning) {
          await backgroundService.enable();
          print('✅ AppLifecycle: Background service started');
        } else {
          print('ℹ️ AppLifecycle: Background service already running');
        }

        // Start foreground tracking (more frequent updates while app is open)
        final foregroundService = container.read(foregroundLocationServiceProvider);
        await foregroundService.startTracking();
        print('✅ AppLifecycle: Foreground tracking started');
      } else {
        print('⚠️ AppLifecycle: Location tracking disabled in database (locationTrackingEnabled = ${userPrefs.locationTrackingEnabled}), skipping');
      }
    } catch (error, stackTrace) {
      print('❌ AppLifecycle: Error starting tracking - $error');
      print('Stack trace: $stackTrace');
    }
  }

  void _stopForegroundTracking() {
    try {
      print('🔵 AppLifecycle: Stopping foreground tracking...');

      // Get the foreground location service
      final container = ProviderScope.containerOf(context, listen: false);
      final foregroundService = container.read(foregroundLocationServiceProvider);

      foregroundService.stopTracking();

      print('✅ AppLifecycle: Foreground tracking stopped (background continues)');
    } catch (error) {
      print('❌ AppLifecycle: Error stopping foreground tracking - $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
