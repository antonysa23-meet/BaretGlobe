import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_tab_bar/MotionTabBar.dart';
import 'package:motion_tab_bar/MotionTabBarController.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/foreground_location_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../globe/presentation/globe_screen.dart';
import '../../../messaging/presentation/screens/conversations_list_screen.dart';
import '../../../settings/data/repositories/settings_repository.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../providers/navigation_provider.dart';

/// Home screen with bottom navigation
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final ForegroundLocationService _locationService =
      ForegroundLocationService();
  MotionTabBarController? _motionTabBarController;

  @override
  void initState() {
    super.initState();
    print('🏠 HomeScreen: initState - Setting navigation to Globe (index 1)');
    // Ensure navigation provider is set to Globe on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentNav = ref.read(navigationProvider);
      print('🏠 HomeScreen: Current navigation index before reset: $currentNav');
      ref.read(navigationProvider.notifier).state = 1;
      print('🏠 HomeScreen: Navigation index set to 1 (Globe)');
    });
    _motionTabBarController = MotionTabBarController(
      initialIndex: 1, // Start at Globe screen
      length: 3,
      vsync: this,
    );
    WidgetsBinding.instance.addObserver(this);
    _initializeLocationTracking();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _motionTabBarController?.dispose();
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
                print(
                    '🔵 HomeScreen: Location tracking enabled - starting service');
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

    // Sync MotionTabBarController with navigation provider
    if (_motionTabBarController != null &&
        _motionTabBarController!.index != currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _motionTabBarController?.index = currentIndex;
      });
    }

    final screens = [
      const ConversationsListScreen(),
      const GlobeScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: MotionTabBar(
        controller: _motionTabBarController,
        initialSelectedTab: "Globe",
        useSafeArea: true,
        labels: const ["Messages", "Globe", "Settings"],
        icons: const [Icons.message, Icons.public, Icons.settings],
        tabSize: 50,
        tabBarHeight: 65,
        textStyle: const TextStyle(
          fontSize: 12,
          color: AppColors.textGray,
          fontWeight: FontWeight.w500,
        ),
        tabIconColor: AppColors.textGray,
        tabIconSize: 28.0,
        tabIconSelectedSize: 26.0,
        tabSelectedColor: AppColors.accentGold,
        tabIconSelectedColor: Colors.white,
        tabBarColor: Colors.white,
        onTabItemSelected: (int value) {
          ref.read(navigationProvider.notifier).state = value;
        },
      ),
    );
  }
}
