import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:darak_wa_hayk/screens/scroll_world/scroll_world_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget host() => const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: ScrollWorldScreen()),
        ),
      );

  testWidgets('diorama screen builds and renders without exceptions',
      (tester) async {
    await tester.pumpWidget(host());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull,
        reason: 'opening the diorama must not throw');

    // The three mode tabs render (cinematic diorama default).
    expect(find.text('سينمائي'), findsOneWidget);
    expect(find.text('مقارنة'), findsOneWidget);
    expect(find.text('HUD'), findsOneWidget);
  });

  testWidgets('mode switching keeps the screen alive', (tester) async {
    await tester.pumpWidget(host());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('مقارنة'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('HUD'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('سينمائي'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);
  });
}
