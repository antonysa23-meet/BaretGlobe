import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for managing bottom navigation tab selection
///
/// 0 = Messages
/// 1 = Globe (default)
/// 2 = Settings
final navigationProvider = StateProvider<int>((ref) => 1);
