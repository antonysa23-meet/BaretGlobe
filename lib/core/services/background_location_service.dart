import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/api_constants.dart';
import 'geocoding_service.dart';

/// Service for managing background location tracking
/// Uses flutter_background_service for continuous background updates
class BackgroundLocationService {
  static const String taskName = 'location_tracking';
  static const int updateIntervalMinutes = 30; // Update every 30 minutes

  final FlutterBackgroundService _service = FlutterBackgroundService();

  /// Initialize the background service
  Future<void> initialize() async {
    final service = FlutterBackgroundService();

    // Configure notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'location_tracking_channel',
      'Location Tracking',
      description: 'Tracks your location for the Baret Scholars Globe',
      importance: Importance.low,
    );

    final FlutterLocalNotificationsPlugin notificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'location_tracking_channel',
        initialNotificationTitle: 'Baret Scholars',
        initialNotificationContent: 'Location tracking is active',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    debugPrint('✅ BackgroundLocationService: Initialized');
  }

  /// Enable background location tracking
  Future<void> enable() async {
    try {
      final service = FlutterBackgroundService();
      final isRunning = await service.isRunning();

      if (!isRunning) {
        await service.startService();
        debugPrint('✅ BackgroundLocationService: Started');
      } else {
        debugPrint('ℹ️ BackgroundLocationService: Already running');
      }
    } catch (error) {
      debugPrint('❌ BackgroundLocationService: Error enabling - $error');
      rethrow;
    }
  }

  /// Disable background location tracking
  Future<void> disable() async {
    try {
      final service = FlutterBackgroundService();
      final isRunning = await service.isRunning();

      if (isRunning) {
        service.invoke('stopService');
        debugPrint('✅ BackgroundLocationService: Stopped');
      } else {
        debugPrint('ℹ️ BackgroundLocationService: Not running');
      }
    } catch (error) {
      debugPrint('❌ BackgroundLocationService: Error disabling - $error');
      rethrow;
    }
  }

  /// Check if background service is running
  Future<bool> isRunning() async {
    return await _service.isRunning();
  }

  /// iOS background handler
  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  /// Main background service entry point
  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    // Initialize Supabase
    await Supabase.initialize(
      url: ApiConstants.supabaseUrl,
      anonKey: ApiConstants.supabaseAnonKey,
    );

    // Get alumnus ID from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final alumnusId = prefs.getString('current_alumnus_id');

    if (alumnusId == null) {
      debugPrint('❌ BackgroundLocationService: No alumnus ID found');
      service.stopSelf();
      return;
    }

    // Periodic location update timer
    Timer.periodic(const Duration(minutes: updateIntervalMinutes), (timer) async {
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          await _performLocationUpdate(alumnusId, service);
        }
      } else {
        await _performLocationUpdate(alumnusId, service);
      }
    });

    // Perform initial update
    await _performLocationUpdate(alumnusId, service);
  }

  /// Perform a location update
  static Future<void> _performLocationUpdate(
    String alumnusId,
    ServiceInstance service,
  ) async {
    try {
      debugPrint('🔵 BackgroundLocationService: Starting location update...');

      // Check if we should update (avoid too frequent updates)
      final prefs = await SharedPreferences.getInstance();
      final lastUpdateStr = prefs.getString('last_background_update');
      if (lastUpdateStr != null) {
        final lastUpdate = DateTime.parse(lastUpdateStr);
        final timeSinceUpdate = DateTime.now().difference(lastUpdate);

        if (timeSinceUpdate.inMinutes < updateIntervalMinutes - 5) {
          debugPrint('ℹ️ BackgroundLocationService: Too soon since last update');
          return;
        }
      }

      // Check permission
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('❌ BackgroundLocationService: Location permission denied');
        return;
      }

      // Get current location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 30),
      );

      debugPrint('📍 BackgroundLocationService: Got position: ${position.latitude}, ${position.longitude}');

      // Geocode to city
      final geocodingService = GeocodingService();
      final city = await geocodingService.approximateToNearestCity(
        position.latitude,
        position.longitude,
      );
      final country = await geocodingService.getCountry(
        position.latitude,
        position.longitude,
      );

      debugPrint('🏙️ BackgroundLocationService: City: $city, Country: $country');

      // Update location in Supabase
      final supabase = Supabase.instance.client;

      // Call the update_current_location function
      await supabase.rpc(
        'update_current_location',
        params: {
          'p_alumnus_id': alumnusId,
          'p_latitude': position.latitude,
          'p_longitude': position.longitude,
          'p_city': city,
          'p_country': country ?? 'Unknown',
          'p_location_type': 'background',
          'p_notes': 'Automatic background update',
        },
      );

      debugPrint('✅ BackgroundLocationService: Location updated successfully');

      // Save last update time
      await prefs.setString('last_background_update', DateTime.now().toIso8601String());

      // Update notification
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: 'Baret Scholars',
          content: 'Location updated ${city ?? country ?? 'successfully'}',
        );
      }
    } catch (error) {
      debugPrint('❌ BackgroundLocationService: Error updating location - $error');
    }
  }
}
