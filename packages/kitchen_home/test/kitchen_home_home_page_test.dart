import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_home/kitchen_home.dart';

void main() {
  testWidgets('首页展示搜索和两个核心入口', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HomePage())),
    );

    expect(find.text('今天想吃点什么？'), findsOneWidget);
    expect(find.text('搜索菜名、食材或标签'), findsOneWidget);
    expect(find.text('快速导入'), findsOneWidget);
    expect(find.text('手动创建'), findsOneWidget);
  });
}
