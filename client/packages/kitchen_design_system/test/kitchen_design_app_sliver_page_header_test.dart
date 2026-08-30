import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_design_system/kitchen_design_system.dart';

void main() {
  testWidgets('页面头部滚动时副标题淡出并收缩为固定顶部栏', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              AppSliverPageHeader(
                title: '菜谱集',
                subtitle: '慢慢做，认真吃',
                action: IconButton(
                  key: const Key('app-sliver-page-header-action'),
                  onPressed: () {},
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(
                  key: Key('app-sliver-page-header-content'),
                  height: 800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final subtitle = find.byKey(const Key('app-sliver-page-header-subtitle'));
    final navigation = find.byKey(
      const Key('app-sliver-page-header-navigation'),
    );
    expect(tester.widget<Opacity>(subtitle).opacity, closeTo(1, 0.01));
    expect(tester.widget<Opacity>(navigation).opacity, closeTo(0, 0.01));
    expect(
      tester
          .getTopLeft(find.byKey(const Key('app-sliver-page-header-title')))
          .dy,
      closeTo(AppSpacing.s12, 1),
    );
    expect(tester.getTopLeft(subtitle).dy, closeTo(50, 1));
    final action = find.byKey(const Key('app-sliver-page-header-action'));
    final actionTop = tester.getTopLeft(action).dy;
    expect(actionTop, closeTo(AppSpacing.s4, 1));
    expect(
      tester
          .getTopLeft(find.byKey(const Key('app-sliver-page-header-content')))
          .dy,
      closeTo(AppSize.pageHeaderExpandedHeight, 1),
    );

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -13));
    await tester.pump();

    expect(tester.widget<Opacity>(subtitle).opacity, closeTo(0.5, 0.01));
    expect(tester.widget<Opacity>(navigation).opacity, closeTo(0.5, 0.01));
    expect(tester.getTopLeft(action).dy, closeTo(actionTop, 1));

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -13));
    await tester.pump();

    expect(tester.widget<Opacity>(subtitle).opacity, closeTo(0, 0.01));
    expect(tester.widget<Opacity>(navigation).opacity, closeTo(1, 0.01));
    expect(tester.getTopLeft(action).dy, closeTo(actionTop, 1));
    final navigationSurface = tester.widget<DecoratedBox>(
      find.descendant(of: navigation, matching: find.byType(DecoratedBox)),
    );
    expect(
      (navigationSurface.decoration as BoxDecoration).color,
      isNot(Colors.transparent),
    );
    expect(
      tester
          .getTopLeft(find.byKey(const Key('app-sliver-page-header-surface')))
          .dy,
      closeTo(0, 1),
    );
  });
}
