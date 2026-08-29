import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_design_system/kitchen_design_system.dart';

void main() {
  testWidgets('分段按钮组选中项填充并带阴影，未选中项仅保留边框', (tester) async {
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.forStyle(AppVisualStyle.scrapbook),
        home: Scaffold(
          body: AppSegmentedButtonGroup<String>(
            options: const [
              AppSegmentedButtonOption(value: 'all', label: '全部'),
              AppSegmentedButtonOption(value: 'favorite', label: '收藏'),
              AppSegmentedButtonOption(value: 'pending', label: '待核对'),
            ],
            selected: 'all',
            onChanged: (value) => selected = value,
          ),
        ),
      ),
    );

    expect(find.byType(AppScrapbookButton), findsNWidgets(3));
    final selectedButton = tester.widget<AppScrapbookButton>(
      find.byKey(const ValueKey('app-scrapbook-button-0')),
    );
    expect(selectedButton.filled, isTrue);
    final selectedMaterial = tester.widget<Material>(
      find.descendant(
        of: find.byKey(const ValueKey('app-scrapbook-button-0')),
        matching: find.byType(Material),
      ),
    );
    expect(selectedMaterial.color, AppColor.xF26A58);
    final selectedShape = selectedMaterial.shape! as RoundedRectangleBorder;
    expect(selectedShape.side.color, AppColor.xA94B3F);

    final unselectedButton = tester.widget<AppScrapbookButton>(
      find.byKey(const ValueKey('app-scrapbook-button-1')),
    );
    expect(unselectedButton.filled, isFalse);
    final unselectedMaterial = tester.widget<Material>(
      find.descendant(
        of: find.byKey(const ValueKey('app-scrapbook-button-1')),
        matching: find.byType(Material),
      ),
    );
    expect(unselectedMaterial.color, Colors.transparent);
    final unselectedShape = unselectedMaterial.shape! as RoundedRectangleBorder;
    expect(unselectedShape.side.color, AppColor.xE8DAC1);
    expect(find.byType(Icon), findsNothing);

    await tester.tap(find.text('待核对'));
    expect(selected, 'pending');
  });
}
