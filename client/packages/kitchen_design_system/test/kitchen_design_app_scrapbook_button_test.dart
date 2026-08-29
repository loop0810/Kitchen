import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_design_system/kitchen_design_system.dart';

void main() {
  testWidgets('AppScrapbookButton 可独立使用并按 filled 切换两种视觉状态', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.forStyle(AppVisualStyle.scrapbook),
        home: const Scaffold(
          body: AppScrapbookButton(label: '操作', filled: true, onPressed: _noop),
        ),
      ),
    );

    final filledButton = tester.widget<AppScrapbookButton>(
      find.byType(AppScrapbookButton),
    );
    expect(filledButton.filled, isTrue);
    final filledDecoration = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byType(AppScrapbookButton),
        matching: find.byType(DecoratedBox),
      ),
    );
    final filledBoxDecoration = filledDecoration.decoration as BoxDecoration;
    expect(filledBoxDecoration.boxShadow, hasLength(1));
    expect(filledBoxDecoration.boxShadow!.single.offset, const Offset(3, 3));
    expect(filledBoxDecoration.boxShadow!.single.blurRadius, 0);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.forStyle(AppVisualStyle.scrapbook),
        home: const Scaffold(
          body: AppScrapbookButton(
            label: '操作',
            filled: false,
            onPressed: _noop,
          ),
        ),
      ),
    );

    final outlinedDecoration = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byType(AppScrapbookButton),
        matching: find.byType(DecoratedBox),
      ),
    );
    final outlinedBoxDecoration =
        outlinedDecoration.decoration as BoxDecoration;
    expect(outlinedBoxDecoration.boxShadow, isNull);
    final outlinedMaterial = tester.widget<Material>(
      find.descendant(
        of: find.byType(AppScrapbookButton),
        matching: find.byType(Material),
      ),
    );
    expect(outlinedMaterial.color, Colors.transparent);
    final outlinedShape = outlinedMaterial.shape! as RoundedRectangleBorder;
    expect(outlinedShape.borderRadius, BorderRadius.circular(AppRadius.r12));
    expect(outlinedShape.side.color, AppColor.xE8DAC1);
  });
}

void _noop() {}
