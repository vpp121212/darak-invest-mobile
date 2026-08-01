import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_theme.dart';
import '../../widgets/bottom_nav.dart';
import '../dashboard/dashboard_screen.dart';
import '../home/home_screen.dart';
import '../profile/add_property_screen.dart';
import '../profile/profile_screen.dart';
import '../search/search_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _currentIndex = 0;

  late final List<Widget> _tabs = const [
    HomeScreen(),
    SearchScreen(),
    AddPropertyScreen(),
    DashboardScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: BottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
