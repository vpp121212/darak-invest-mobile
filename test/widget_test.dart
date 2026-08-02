import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:darak_wa_hayk/main.dart';

void main() {
  testWidgets('App builds and shows home title', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: DarakApp()));
    await tester.pump();

    expect(find.text('دارك وحيك'), findsWidgets);
  });
}
