import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:darak_wa_hayk/widgets/ken_burns_image.dart';

void main() {
  testWidgets('camera motion keeps animating over time', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              height: 200,
              child: KenBurnsImage(src: 'assets/images/prop_villa_pool.jpg'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    Matrix4 matrixAt(WidgetTester t) => t
        .widget<Transform>(find.byKey(const Key('ken-burns-transform')))
        .transform;

    final first = matrixAt(tester);
    await tester.pump(const Duration(seconds: 2));
    final second = matrixAt(tester);
    await tester.pump(const Duration(seconds: 2));
    final third = matrixAt(tester);

    expect(second, isNot(equals(first)),
        reason: 'the camera transform must change as time passes');
    expect(third, isNot(equals(second)),
        reason: 'the camera transform keeps moving');

    final s0 = first.getMaxScaleOnAxis();
    final s2 = third.getMaxScaleOnAxis();
    expect(s2, greaterThan(s0),
        reason: 'the zoom amplitude must be clearly visible over time');
  });
}
