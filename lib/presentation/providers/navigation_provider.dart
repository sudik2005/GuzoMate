import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to manage the current tab index of the HomeScreen
final homeTabIndexProvider = StateProvider<int>((ref) => 0);
