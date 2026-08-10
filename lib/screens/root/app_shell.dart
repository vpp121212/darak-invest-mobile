import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tab_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/floating_dock_nav.dart';
import '../home/home_screen.dart';
import '../profile/add_property_screen.dart';
import '../profile/profile_screen.dart';

@RoutePage(name: 'AppShellRoute')
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  static const _addTabIndex = 2;

  /// Real tab screens held by the [IndexedStack]. Dock indices 1 (الخريطة)
  /// and 3 (الرسائل) push full-screen routes instead of switching tabs.
  late final List<Widget> _tabs = const [
    HomeScreen(),
    AddPropertyScreen(),
    ProfileScreen(),
  ];

  static int _tabIndexForDock(int dockIndex) {
    switch (dockIndex) {
      case 2:
        return 1;
      case 4:
        return 2;
      default:
        return 0;
    }
  }

  void _onTabSelected(int index) {
    if (index == 1) {
      context.pushRoute(MapRoute());
      return;
    }
    if (index == 3) {
      context.pushRoute(const ConversationsRoute());
      return;
    }
    final loggedIn = ref.read(authProvider).isLoggedIn;
    if (index == _addTabIndex && !loggedIn) {
      // Publishing a property requires an account; redirect to login.
      context.pushRoute(const LoginRoute());
      return;
    }
    ref.read(activeTabProvider.notifier).state = index;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(activeTabProvider);
    return Scaffold(
      extendBody: true,
      backgroundColor: bgDark,
      body: IndexedStack(
        index: _tabIndexForDock(currentIndex),
        children: _tabs,
      ),
      bottomNavigationBar: FloatingDockNav(
        currentIndex: currentIndex,
        onTap: _onTabSelected,
      ),
    );
  }
}
