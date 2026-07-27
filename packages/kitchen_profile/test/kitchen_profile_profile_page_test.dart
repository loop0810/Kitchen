import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_design_system/kitchen_design_system.dart';
import 'package:kitchen_profile/kitchen_profile.dart';

void main() {
  testWidgets('我的页面可以切换全局视觉风格', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ProfilePage()),
      ),
    );

    expect(container.read(visualStyleProvider), AppVisualStyle.scrapbook);
    await tester.tap(find.text('极简'));
    await tester.pump();
    expect(container.read(visualStyleProvider), AppVisualStyle.minimal);
  });
}
