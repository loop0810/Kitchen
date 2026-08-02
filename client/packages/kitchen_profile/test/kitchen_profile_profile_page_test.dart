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
    await tester.tap(find.text('极简'));
    await tester.pump();
    expect(container.read(visualStyleProvider), AppVisualStyle.minimal);
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
