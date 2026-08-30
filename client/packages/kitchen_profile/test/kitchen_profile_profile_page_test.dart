import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_design_system/kitchen_design_system.dart';
import 'package:kitchen_profile/kitchen_profile.dart';
import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';

void main() {
  testWidgets('我的页面可以切换全局视觉风格', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ProfilePage()),
      ),
    );

    expect(container.read(visualStyleProvider), AppVisualStyle.scrapbook);
    await tester.tap(find.text('切换'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('极简'));
    await tester.pumpAndSettle();
    expect(container.read(visualStyleProvider), AppVisualStyle.minimal);
  });

  testWidgets('我的页面将本机资料放入隐私与帮助', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ProfilePage())),
    );
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('隐私与帮助'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('隐私与帮助'), findsOneWidget);
    expect(find.text('管理本机资料'), findsOneWidget);
    expect(find.text('数据管理'), findsNothing);
  });

  testWidgets('从个性化食谱进入分类管理并新增选项', (tester) async {
    final repository = _MemoryPersonalRecipeConfigRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileDependenciesProvider.overrideWithValue(
            ProfileDependencies(personalRecipeConfigRepository: repository),
          ),
        ],
        child: const MaterialApp(home: ProfilePage()),
      ),
    );

    await tester.tap(find.text('个性化食谱'));
    await tester.pumpAndSettle();
    expect(find.text('管理分类'), findsOneWidget);
    expect(find.text('管理标签'), findsOneWidget);
    expect(find.text('管理难度'), findsOneWidget);

    await tester.tap(find.text('管理分类'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('新增分类'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '低脂餐');
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    expect(repository.current.categories, contains('低脂餐'));
  });

  testWidgets('模拟手机号登录校验通过后调用回调', (tester) async {
    String? phone;
    String? code;
    final repository = _MemoryPersonalRecipeConfigRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileDependenciesProvider.overrideWithValue(
            ProfileDependencies(
              personalRecipeConfigRepository: repository,
              signInWithPhone: (value, verificationCode) async {
                phone = value;
                code = verificationCode;
                return true;
              },
            ),
          ),
        ],
        child: const MaterialApp(home: ProfilePage()),
      ),
    );

    await tester.pump();
    await tester.drag(
      find.byKey(const PageStorageKey('profile-scroll')),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('账号与安全'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('模拟手机号登录'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '13800138000');
    await tester.tap(find.widgetWithText(FilledButton, '登录'));
    await tester.pumpAndSettle();

    expect(phone, '13800138000');
    expect(code, '111111');
  });

  testWidgets('模拟手机号登录拒绝无效手机号且不调用回调', (tester) async {
    var called = false;
    final repository = _MemoryPersonalRecipeConfigRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileDependenciesProvider.overrideWithValue(
            ProfileDependencies(
              personalRecipeConfigRepository: repository,
              signInWithPhone: (_, _) async {
                called = true;
                return true;
              },
            ),
          ),
        ],
        child: const MaterialApp(home: ProfilePage()),
      ),
    );

    await tester.pump();
    await tester.drag(
      find.byKey(const PageStorageKey('profile-scroll')),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('账号与安全'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('模拟手机号登录'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '01012345678');
    await tester.tap(find.widgetWithText(FilledButton, '登录'));
    await tester.pumpAndSettle();

    expect(called, isFalse);
    expect(find.text('请输入有效的中国大陆手机号。'), findsOneWidget);
  });
}

class _MemoryPersonalRecipeConfigRepository
    implements PersonalRecipeConfigRepository {
  var current = PersonalRecipeConfigEntity.defaults;

  final _controller = StreamController<PersonalRecipeConfigEntity>.broadcast();

  @override
  Future<PersonalRecipeConfigEntity> getCached() async => current;

  @override
  Future<void> save(PersonalRecipeConfigEntity config) async {
    current = config.copyWith(syncPending: true);
    _controller.add(current);
  }

  @override
  Future<void> synchronize() async {}

  @override
  Stream<PersonalRecipeConfigEntity> watchCached() async* {
    yield current;
    yield* _controller.stream;
  }
}
