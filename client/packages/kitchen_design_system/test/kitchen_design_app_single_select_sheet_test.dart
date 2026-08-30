import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_design_system/kitchen_design_system.dart';

enum _SortOrder { recentlyUpdated, recentlySaved }

void main() {
  testWidgets('单选面板展示标题、副标题、图标和当前选中状态', (tester) async {
    late Future<_SortOrder?> result;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.forStyle(AppVisualStyle.scrapbook),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                result = showAppSingleSelectSheet<_SortOrder>(
                  context: context,
                  title: '选择排序方式',
                  subtitle: '更容易找到这一刻想做的菜',
                  selected: _SortOrder.recentlyUpdated,
                  options: const [
                    AppSingleSelectSheetOption<_SortOrder>(
                      value: _SortOrder.recentlyUpdated,
                      title: '最近更新',
                      subtitle: '刚添加的新灵感排在前面',
                      icon: Icons.sync_rounded,
                    ),
                    AppSingleSelectSheetOption<_SortOrder>(
                      value: _SortOrder.recentlySaved,
                      title: '最近保存',
                      subtitle: '先看看你收藏的好味道',
                      icon: Icons.bookmark_rounded,
                    ),
                  ],
                );
              },
              child: const Text('打开面板'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开面板'));
    await tester.pumpAndSettle();

    expect(find.text('选择排序方式'), findsOneWidget);
    expect(find.text('更容易找到这一刻想做的菜'), findsOneWidget);
    expect(find.text('最近更新'), findsOneWidget);
    expect(find.text('刚添加的新灵感排在前面'), findsOneWidget);
    expect(find.byType(Radio<_SortOrder>), findsNWidgets(2));
    expect(find.byTooltip('关闭'), findsOneWidget);

    final selectedTile = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('app-single-select-sheet-option-0')),
    );
    final selectedShadow =
        (selectedTile.decoration as BoxDecoration).boxShadow!.single;
    expect(selectedShadow.offset, const Offset(3, 3));
    expect(selectedShadow.blurRadius, 0);

    final radioGroup = tester.widget<RadioGroup<_SortOrder>>(
      find.byType(RadioGroup<_SortOrder>),
    );
    expect(radioGroup.groupValue, _SortOrder.recentlyUpdated);

    await tester.tap(find.text('最近保存'));
    await tester.pumpAndSettle();
    expect(await result, _SortOrder.recentlySaved);
  });

  testWidgets('标题和副标题为空时不渲染空文本，仍可关闭面板', (tester) async {
    late Future<String?> result;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.forStyle(AppVisualStyle.scrapbook),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                result = showAppSingleSelectSheet<String>(
                  context: context,
                  title: '',
                  subtitle: '   ',
                  options: const [
                    AppSingleSelectSheetOption<String>(
                      value: 'only',
                      title: '唯一选项',
                    ),
                  ],
                );
              },
              child: const Text('打开'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();

    expect(find.text('唯一选项'), findsOneWidget);
    expect(find.byTooltip('关闭'), findsOneWidget);
    expect(find.text('   '), findsNothing);

    await tester.tap(find.byTooltip('关闭'));
    await tester.pumpAndSettle();
    expect(await result, isNull);
  });
}
