import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/constants/api_constants.dart';
import 'core/services/background_location_service.dart';
import 'features/globe/data/repositories/location_repository.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style (status bar, navigation bar)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Initialize Supabase
  await Supabase.initialize(
    url: ApiConstants.supabaseUrl,
    anonKey: ApiConstants.supabaseAnonKey,
    realtimeClientOptions: const RealtimeClientOptions(
      eventsPerSecond: 10,
    ),
  );

  // Initialize background location service (will be started based on user preferences from database)
  try {
    final backgroundService = BackgroundLocationService();
    await backgroundService.initialize();
    debugPrint('✅ Background location service initialized');
  } catch (error) {
    debugPrint('⚠️ Failed to initialize background service: $error');
  }

  // Cleanup old location history on app start (12-month retention)
  try {
    final locationRepo = LocationRepository();
    await locationRepo.cleanupOldLocationHistory();
  } catch (error) {
    // Silently fail - cleanup will happen again next time
    debugPrint('Failed to cleanup old location history: $error');
  }

  // Run the app with Riverpod
  runApp(
    const ProviderScope(
      child: BaretScholarsApp(),
    ),
  );
}
