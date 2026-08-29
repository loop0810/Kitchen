import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_design_system/kitchen_design_system.dart';

void main() {
  testWidgets('通用底部选择面板暴露标题、副标题和操作配置', (tester) async {
    String? selectedAction;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.forStyle(AppVisualStyle.scrapbook),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showAppActionSheet(
                  context: context,
                  title: '创建菜谱',
                  subtitle: '选择一种开始方式',
                  actions: [
                    AppActionSheetAction(
                      icon: Icons.edit_note_rounded,
                      title: '手动创建',
                      onTap: () => selectedAction = 'manual',
                    ),
                    AppActionSheetAction(
                      icon: Icons.photo_library_outlined,
                      title: '选择图片',
                      onTap: () => selectedAction = 'images',
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

    expect(find.text('创建菜谱'), findsOneWidget);
    expect(find.text('选择一种开始方式'), findsOneWidget);
    expect(find.text('手动创建'), findsOneWidget);
    expect(find.text('选择图片'), findsOneWidget);
    expect(find.byTooltip('关闭'), findsOneWidget);

    final firstActionTile = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('app-action-sheet-action-0')),
    );
    final firstActionShadow =
        (firstActionTile.decoration as BoxDecoration).boxShadow!.single;
    expect(firstActionShadow.offset, const Offset(3, 3));
    expect(firstActionShadow.blurRadius, 0);
    expect(firstActionShadow.spreadRadius, 0);

    await tester.tap(find.text('选择图片'));
    await tester.pumpAndSettle();
    expect(selectedAction, 'images');
  });

  testWidgets('关闭按钮可以取消选择且不会执行操作回调', (tester) async {
    var selected = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.forStyle(AppVisualStyle.scrapbook),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showAppActionSheet(
                  context: context,
                  title: '选择',
                  actions: [
                    AppActionSheetAction(
                      icon: Icons.check,
                      title: '确定',
                      onTap: () => selected = true,
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
    await tester.tap(find.byTooltip('关闭'));
    await tester.pumpAndSettle();

    expect(selected, isFalse);
  });
}
