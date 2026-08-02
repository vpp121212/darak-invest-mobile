import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:darak_wa_hayk/screens/home/home_screen.dart';

void main() {
  setUpAll(() {
    // Tests never fetch fonts over the network.
    GoogleFonts.config.allowRuntimeFetching = false;
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

    // Allow the initial load (HTTP is blocked in tests → error state) to settle.
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    expect(find.text('تعذّر تحميل العقارات'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
  });

  testWidgets('builds without exceptions when data load fails', (tester) async {
    // Network is blocked in widget tests, so we only verify the UI shell is
    // reachable without exceptions.
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: HomeScreen())),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    expect(find.text('إعادة المحاولة'), findsOneWidget);
  });
}
