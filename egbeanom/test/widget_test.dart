import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:egbeanom/main.dart';

void main() {
  testWidgets('storefront hides admin link before backend sign in', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(2400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const EgbeAnomStoreApp());

    expect(find.text('Shop'), findsOneWidget);
    expect(find.text('Cart'), findsOneWidget);

    expect(find.text('Admin'), findsNothing);

    await tester.tap(find.byTooltip('Account menu'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Admin sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Admin sign in'), findsOneWidget);
    expect(find.text('Marketplace admin'), findsNothing);
  });
}
