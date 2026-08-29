import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_design_system/kitchen_design_system.dart';

void main() {
  testWidgets('导入按钮无图标时不保留图标槽位，图标可显示在文字右侧', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.forStyle(AppVisualStyle.scrapbook),
        home: const Scaffold(body: AppImportButton(onPressed: _noop)),
      ),
    );

    final textOnlySize = tester.getSize(find.byType(AppImportButton));
    expect(find.byType(Icon), findsNothing);
    final textOnlyButton = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byType(AppImportButton),
        matching: find.byType(DecoratedBox),
      ),
    );
    final textOnlyDecoration = textOnlyButton.decoration as BoxDecoration;
    expect(textOnlyDecoration.boxShadow!.single.offset, const Offset(3, 3));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.forStyle(AppVisualStyle.scrapbook),
        home: const Scaffold(
          body: AppImportButton(
            onPressed: _noop,
            icon: Icons.add_circle_outline_rounded,
            iconPosition: AppImportButtonIconPosition.trailing,
          ),
        ),
      ),
    );

    final iconButtonSize = tester.getSize(find.byType(AppImportButton));
    expect(iconButtonSize.width, greaterThan(textOnlySize.width));
    expect(find.byIcon(Icons.add_circle_outline_rounded), findsOneWidget);
    final labelCenter = tester.getCenter(find.text('导入菜谱'));
    final iconCenter = tester.getCenter(
      find.byIcon(Icons.add_circle_outline_rounded),
    );
    expect(iconCenter.dx, greaterThan(labelCenter.dx));

    final importButton = tester.widget<Material>(
      find.descendant(
        of: find.byType(AppImportButton),
        matching: find.byType(Material),
      ),
    );
    expect(importButton.color, AppColor.xF26A58);
    final importShape = importButton.shape! as RoundedRectangleBorder;
    expect(importShape.borderRadius, BorderRadius.circular(AppRadius.r12));
    expect(importShape.side.color, AppColor.xA94B3F);
  });
}

void _noop() {}
