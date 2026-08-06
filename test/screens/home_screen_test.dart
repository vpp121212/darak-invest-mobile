import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:darak_wa_hayk/screens/home/home_screen.dart';

void main() {
  setUpAll(() {
    // Tests never fetch fonts over the network.
    GoogleFonts.config.allowRuntimeFetching = false;
    // SharedPreferences must be mocked or its getInstance() hangs in tests.
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('renders the app bar title', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: HomeScreen()),
        ),
      ),
    );

    // The header is rendered synchronously while data loads.
    expect(find.text('دارك وحيك'), findsOneWidget);

    // Bounded pumps: the fallback list contains network images whose loading
    // spinners animate forever, so pumpAndSettle would never settle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    // The offline banner is shown while the demo/fallback list stays usable.
    expect(find.text('تعذّر تحديث البيانات — تعرض نسخة محفوظة/تجريبية'), findsOneWidget);
    expect(find.text('أحدث العقارات'), findsOneWidget);
  });

  testWidgets('builds without exceptions when data load fails', (tester) async {
    // Network is blocked in widget tests, so we only verify the UI shell is
    // reachable without exceptions.
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: HomeScreen())),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    // Fallback list renders even though the API call failed.
    expect(find.text('أحدث العقارات'), findsOneWidget);
  });
}
