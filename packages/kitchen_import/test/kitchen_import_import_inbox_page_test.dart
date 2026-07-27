import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_import/kitchen_import.dart';

void main() {
  testWidgets('导入箱展示占位说明与手动创建入口', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ImportInboxPage()));

    expect(find.text('导入箱'), findsOneWidget);
    expect(find.text('把看到的菜谱收进来'), findsOneWidget);
    expect(find.text('手动创建'), findsOneWidget);
  });
}
