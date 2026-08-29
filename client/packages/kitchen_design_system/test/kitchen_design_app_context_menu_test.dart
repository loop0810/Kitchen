import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_design_system/kitchen_design_system.dart';

void main() {
  testWidgets('长按锚点菜单支持图标、危险色和操作回调', (tester) async {
    String? selectedAction;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showAppContextMenu(
                  context: context,
                  anchorPosition: const Offset(100, 100),
                  actions: [
                    AppContextMenuAction(
                      icon: Icons.edit_outlined,
                      title: '编辑菜谱',
                      onTap: () => selectedAction = 'edit',
                    ),
                    AppContextMenuAction(
                      icon: Icons.delete_outline_rounded,
                      title: '移入回收站',
                      foregroundColor: Colors.red,
                      onTap: () => selectedAction = 'trash',
                    ),
                  ],
                );
              },
              child: const Text('打开菜单'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开菜单'));
    await tester.pumpAndSettle();

    expect(find.byType(AppContextMenu), findsOneWidget);
    expect(
      tester.getTopLeft(find.byType(AppContextMenu)),
      const Offset(100, 100),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('app-context-menu-action-0'))),
      const Size(144, 40),
    );
    final actionInkWell = tester.widget<InkWell>(
      find.byKey(const ValueKey('app-context-menu-action-0')),
    );
    expect(actionInkWell.borderRadius, BorderRadius.circular(AppRadius.r12));
    expect(
      actionInkWell.overlayColor?.resolve({WidgetState.pressed}),
      const Color(0xFFF5E8DA),
    );
    final actionText = tester.widget<Text>(find.text('编辑菜谱'));
    expect(actionText.style?.fontSize, 14);
    expect(actionText.style?.color, AppColor.x60483A);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    expect(find.text('编辑菜谱'), findsOneWidget);
    expect(find.text('移入回收站'), findsOneWidget);

    await tester.tap(find.text('移入回收站'));
    await tester.pumpAndSettle();
    expect(selectedAction, 'trash');
    expect(find.byType(AppContextMenu), findsNothing);
  });

  testWidgets('长按锚点菜单支持无图标布局', (tester) async {
    var selected = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppContextMenu(
            actions: [
              AppContextMenuAction(title: '编辑', onTap: () {}),
              AppContextMenuAction(title: '管理成员', onTap: () {}),
              AppContextMenuAction(title: '删除菜谱集', onTap: () {}),
            ],
            onSelected: (index) => selected = index == 0,
          ),
        ),
      ),
    );

    expect(find.byType(Icon), findsNothing);
    expect(find.text('编辑'), findsOneWidget);
    expect(find.text('管理成员'), findsOneWidget);
    expect(find.text('删除菜谱集'), findsOneWidget);

    for (var index = 0; index < 3; index++) {
      final actionInkWell = tester.widget<InkWell>(
        find.byKey(ValueKey('app-context-menu-action-$index')),
      );
      expect(
        actionInkWell.overlayColor?.resolve({WidgetState.pressed}),
        [
          const Color(0xFFF5E8DA),
          const Color(0xFFE9EFE5),
          const Color(0xFFF7E2DB),
        ][index],
      );
    }

    await tester.tap(find.text('编辑'));
    expect(selected, isTrue);
  });
}
