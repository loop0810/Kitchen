import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_design_system/kitchen_design_system.dart';
import 'package:kitchen_home/kitchen_home.dart';

void main() {
  testWidgets('首页展示搜索和统一创建入口', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HomePage())),
    );

    expect(find.text('今天想吃点什么'), findsOneWidget);
    expect(find.text('搜索菜名、食材或标签'), findsOneWidget);
    expect(find.text('创建菜谱'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/home_kitchen_illustration.png' &&
            (widget.image as AssetImage).package == 'kitchen_home',
      ),
      findsOneWidget,
    );
    expect(find.byType(SingleChildScrollView), findsNothing);

    final searchSurface = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byKey(const Key('home-search-surface')),
        matching: find.byType(DecoratedBox),
      ),
    );
    final searchDecoration = searchSurface.decoration as BoxDecoration;
    expect(searchDecoration.boxShadow!.single.offset, const Offset(3, 3));
    expect(searchDecoration.boxShadow!.single.blurRadius, 0);

    final searchSize = tester.getSize(
      find.byKey(const Key('home-search-field')),
    );
    expect(searchSize, const Size(337, 56));

    final createButton = tester.widget<AppImportButton>(
      find.byType(AppImportButton),
    );
    expect(createButton.label, '创建菜谱');
    expect(createButton.icon, Icons.add_circle_outline_rounded);
    expect(createButton.height, AppSize.homeControlHeight);

    final createSurface = tester.widgetList<DecoratedBox>(
      find.descendant(
        of: find.byKey(const Key('home-create-surface')),
        matching: find.byType(DecoratedBox),
      ),
    ).first;
    final createDecoration = createSurface.decoration as BoxDecoration;
    expect(createDecoration.boxShadow!.single.color, AppColor.xA94B3F);

    await tester.tap(find.text('创建菜谱'));
    await tester.pumpAndSettle();
    expect(find.text('选择一种开始方式'), findsOneWidget);
    expect(find.text('手动创建'), findsOneWidget);
    expect(find.text('粘贴文章或链接'), findsOneWidget);
    expect(find.text('选择图片'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/recipe_creation_manual.png' &&
            (widget.image as AssetImage).package == 'kitchen_home',
      ),
      findsOneWidget,
    );
  });
}
