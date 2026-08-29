import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_design_system/kitchen_design_system.dart';

void main() {
  testWidgets('通用弹窗暴露标题、统一颜色的多行正文和操作配置', (tester) async {
    var selected = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.forStyle(AppVisualStyle.scrapbook),
        home: Scaffold(
          body: AppDialog(
            title: '确定删除这个菜谱集？',
            content: '删除菜谱集不会删除其中的菜谱。\n这里只会删除集合关系。',
            actions: [
              AppDialogAction(title: '取消', onPressed: () {}),
              AppDialogAction(title: '确认删除', onPressed: () => selected = true),
            ],
          ),
        ),
      ),
    );

    expect(find.text('确定删除这个菜谱集？'), findsOneWidget);
    expect(find.textContaining('删除菜谱集不会删除其中的菜谱。'), findsOneWidget);
    expect(find.textContaining('这里只会删除集合关系。'), findsOneWidget);

    final content = tester.widget<Text>(find.textContaining('删除菜谱集不会删除其中的菜谱。'));
    expect(content.style?.color, AppColor.x7E756E);
    expect(content.softWrap, isTrue);

    expect(find.byType(AppScrapbookButton), findsNWidgets(2));
    expect(find.byType(TextButton), findsNothing);
    expect(find.byType(FilledButton), findsNothing);

    final normalAction = tester.widget<AppScrapbookButton>(
      find.byKey(const ValueKey('app-dialog-action-0')),
    );
    expect(normalAction.filled, isFalse);

    final emphasizedAction = tester.widget<AppScrapbookButton>(
      find.byKey(const ValueKey('app-dialog-action-1')),
    );
    expect(emphasizedAction.filled, isTrue);

    final normalActionRect = tester.getRect(
      find.byKey(const ValueKey('app-dialog-action-0')),
    );
    final emphasizedActionRect = tester.getRect(
      find.byKey(const ValueKey('app-dialog-action-1')),
    );
    final actionsAlignRect = tester.getRect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Align && widget.alignment == Alignment.centerRight,
      ),
    );
    expect(emphasizedActionRect.top, normalActionRect.top);
    expect(emphasizedActionRect.left, greaterThan(normalActionRect.right));
    expect(emphasizedActionRect.width, greaterThan(normalActionRect.width));
    expect(emphasizedActionRect.right, actionsAlignRect.right);

    final emphasizedDecoration = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byKey(const ValueKey('app-dialog-action-1')),
        matching: find.byType(DecoratedBox),
      ),
    );
    final shadow =
        (emphasizedDecoration.decoration as BoxDecoration).boxShadow!.single;
    expect(shadow.color, AppColor.xA94B3F);
    expect(shadow.offset, const Offset(3, 3));
    expect(shadow.blurRadius, 0);

    await tester.tap(find.text('确认删除'));
    expect(selected, isTrue);
  });

  testWidgets('弹窗最多接受三个操作', (tester) async {
    expect(
      () => AppDialog(
        title: '标题',
        content: '内容',
        actions: [
          AppDialogAction(title: '一', onPressed: () {}),
          AppDialogAction(title: '二', onPressed: () {}),
          AppDialogAction(title: '三', onPressed: () {}),
          AppDialogAction(title: '四', onPressed: () {}),
        ],
      ),
      throwsAssertionError,
    );
  });
}
