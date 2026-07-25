import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_notes/src/app.dart';

void main() {
  testWidgets('首页展示核心搜索与创建入口', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: KitchenNotesApp()));
    await tester.pumpAndSettle();

    expect(find.text('今天想吃点什么？'), findsOneWidget);
    expect(find.text('快速导入'), findsOneWidget);
    expect(find.text('手动创建'), findsOneWidget);
  });
}
