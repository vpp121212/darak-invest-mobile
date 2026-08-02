import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:darak_wa_hayk/models/investment_opportunity.dart';
import 'package:darak_wa_hayk/widgets/neighborhood_radar_card.dart';

void main() {
  testWidgets('Radar card renders opportunity details', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: NeighborhoodRadarCard(
            opportunity: kInvestmentOpportunities.first,
            onViewDistrict: () {},
            onInvest: () {},
          ),
        ),
      ),
    );

    expect(find.text('حي الملقا - مربع الاستثمار'), findsOneWidget);
    expect(find.text('عقارات تجارية وسكنية فاخرة'), findsOneWidget);
    expect(find.text('+15.8%'), findsOneWidget);
    expect(find.text('75% (3,750,000 ر.س)'), findsOneWidget);
    expect(find.text('معاينة الحي بالتفصيل'), findsOneWidget);
    expect(find.text('استثمر بـ 1,000 ر.س'), findsOneWidget);
  });
}
