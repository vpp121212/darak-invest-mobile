import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

import '../../models/property.dart';
import '../../screens/agents/agents_screen.dart';
import '../../screens/ai/estimate_screen.dart';
import '../../screens/ai/pulse_screen.dart';
import '../../screens/ai/roi_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/booking/booking_screen.dart';
import '../../screens/booking/my_brokerage_screen.dart';
import '../../screens/booking/offer_screen.dart';
import '../../screens/compare/compare_screen.dart';
import '../../screens/favorites/favorites_screen.dart';
import '../../screens/finance/finance_screen.dart';
import '../../screens/legal/legal_screen.dart';
import '../../screens/map/map_screen.dart';
import '../../screens/market/market_report_screen.dart';
import '../../screens/management/management_screen.dart';
import '../../screens/messages/chat_screen.dart';
import '../../screens/messages/conversations_screen.dart';
import '../../screens/neighborhood/neighborhood_detail_screen.dart';
import '../../screens/notifications/notifications_screen.dart';
import '../../screens/payments/subscription_screen.dart';
import '../../screens/property/property_detail_screen.dart';
import '../../screens/profile/settings_screen.dart';
import '../../screens/root/app_shell.dart';
import '../../screens/search/search_screen.dart';
import '../../screens/scroll_world/scroll_world_screen.dart';

part 'app_router.gr.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: AppShellRoute.page, initial: true),
        AutoRoute(page: LoginRoute.page),
        AutoRoute(page: RegisterRoute.page),
        AutoRoute(page: SearchRoute.page),
        AutoRoute(page: EstimateRoute.page),
        AutoRoute(page: RoiRoute.page),
        AutoRoute(page: PulseRoute.page),
        AutoRoute(page: PropertyDetailRoute.page),
        AutoRoute(page: MapRoute.page),
        AutoRoute(page: ScrollWorldRoute.page),
        AutoRoute(page: NeighborhoodDetailRoute.page),
        AutoRoute(page: FavoritesRoute.page),
        AutoRoute(page: FinanceRoute.page),
        AutoRoute(page: CompareRoute.page),
        AutoRoute(page: MarketReportRoute.page),
        AutoRoute(page: AgentsRoute.page),
        AutoRoute(page: LegalRoute.page),
        AutoRoute(page: BookingRoute.page),
        AutoRoute(page: OfferRoute.page),
        AutoRoute(page: MyBrokerageRoute.page),
        AutoRoute(page: ConversationsRoute.page),
        AutoRoute(page: ChatRoute.page),
        AutoRoute(page: NotificationsRoute.page),
        AutoRoute(page: SubscriptionRoute.page),
        AutoRoute(page: ManagementRoute.page),
        AutoRoute(page: SettingsRoute.page),
      ];
}

final appRouter = AppRouter();
