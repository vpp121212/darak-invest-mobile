import 'package:go_router/go_router.dart';

import '../../data/mock_properties.dart';
import '../../models/property.dart';
import '../../screens/ai/estimate_screen.dart';
import '../../screens/ai/pulse_screen.dart';
import '../../screens/ai/roi_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/property/property_detail_screen.dart';
import '../../screens/root/app_shell.dart';
import '../../screens/search/search_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const AppShell(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const AppShell(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) => const SearchScreen(),
    ),
    // هذه الشاشات تقرأ الوسائط عبر ModalRoute.of(context).settings.arguments
    // فتمرر الحجج عبر state.extra كما كان يفعل Navigator.pushNamed
    GoRoute(
      path: '/estimate',
      builder: (context, state) => const EstimateScreen(),
    ),
    GoRoute(
      path: '/roi',
      builder: (context, state) => const RoiScreen(),
    ),
    GoRoute(
      path: '/pulse',
      builder: (context, state) => const PulseScreen(),
    ),
    GoRoute(
      path: '/property',
      builder: (context, state) {
        final extra = state.extra;
        final property = extra is Property ? extra : null;
        return PropertyDetailScreen(property: property ?? MockProperties.demo);
      },
    ),
  ],
);
