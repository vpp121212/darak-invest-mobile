import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/tab_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bottom_nav.dart';
import '../dashboard/dashboard_screen.dart';
import '../home/home_screen.dart';
import '../profile/add_property_screen.dart';
import '../profile/profile_screen.dart';
import '../search/search_screen.dart';

@RoutePage(name: 'AppShellRoute')
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  late final List<Widget> _tabs = const [
    HomeScreen(),
    SearchScreen(),
    AddPropertyScreen(),
    DashboardScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(activeTabProvider);
    return Scaffold(
      backgroundColor: bgDark,
      body: IndexedStack(index: currentIndex, children: _tabs),
      bottomNavigationBar: BottomNav(
        currentIndex: currentIndex,
        onTap: (index) => ref.read(activeTabProvider.notifier).state = index,
      ),
    );
  }
}
