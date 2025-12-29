import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/foreground_location_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../globe/presentation/globe_screen.dart';
import '../../../messaging/presentation/screens/messaging_screen.dart';
import '../../../settings/data/repositories/settings_repository.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../providers/navigation_provider.dart';

/// Home screen with bottom navigation
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  final ForegroundLocationService _locationService = ForegroundLocationService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeLocationTracking();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _locationService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came to foreground - start tracking
      _startLocationTracking();
    } else if (state == AppLifecycleState.paused) {
      // App went to background - stop tracking
      _locationService.stopTracking();
    }
  }

  /// Initialize location tracking when app starts
  Future<void> _initializeLocationTracking() async {
    // Wait a moment for the UI to settle
    await Future.delayed(const Duration(milliseconds: 500));
    _startLocationTracking();
  }

  /// Start location tracking if enabled in settings
  Future<void> _startLocationTracking() async {
    try {
      // Get current auth state
      final authState = ref.read(authStateProvider);

      await authState.when(
        loading: () async {},
        error: (error, stack) async {},
        data: (state) async {
          await state.when(
            authenticated: (user, alumnusId) async {
              if (alumnusId == null) return;

              // Check if location tracking is enabled
              final settingsRepo = SettingsRepository();
              final prefs = await settingsRepo.getUserPreferences(alumnusId);

              if (prefs?.locationTrackingEnabled == true) {
                print('🔵 HomeScreen: Location tracking enabled - starting service');
                await _locationService.startTracking();
              } else {
                print('⏸️ HomeScreen: Location tracking disabled');
              }
            },
            unauthenticated: () async {},
            loading: () async {},
            error: (message, code) async {},
          );
        },
      );
    } catch (error) {
      print('❌ HomeScreen: Error starting location tracking - $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navigationProvider);

    final screens = [
      const MessagingScreen(),
      const GlobeScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          ref.read(navigationProvider.notifier).state = index;
        },
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.textGray,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.public),
            label: 'Globe',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
