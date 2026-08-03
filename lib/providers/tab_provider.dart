import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Index of the active bottom-navigation tab in [AppShell].
///
/// Shared so the "add property" tab can jump back to the home tab after a
/// successful save without coupling the screens.
final activeTabProvider = StateProvider<int>((ref) => 0);
