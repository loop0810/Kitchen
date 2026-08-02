import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Domain 保持纯 Dart', () {
    final source = _librarySource('packages/kitchen_recipe_domain/lib');

    for (final forbidden in [
      'package:flutter',
      'riverpod',
      'drift',
      'path_provider',
    ]) {
      expect(source, isNot(contains(forbidden)), reason: forbidden);
    }
  });

  test('组件依赖方向符合架构边界', () {
    final featurePackages = [
      'kitchen_home',
      'kitchen_import',
      'kitchen_profile',
      'kitchen_recipe_editor',
      'kitchen_recipe_library',
    ];
    for (final package in featurePackages) {
      final manifest = File(
        'packages/$package/pubspec.yaml',
      ).readAsStringSync();
      expect(manifest, isNot(contains('kitchen_recipe_data')));
      expect(manifest, isNot(contains('kitchen_notes')));
      for (final otherFeature in featurePackages.where(
        (name) => name != package,
      )) {
        expect(manifest, isNot(contains('$otherFeature:')));
      }
    }

    final dataSource = _librarySource('packages/kitchen_recipe_data/lib');
    expect(dataSource, isNot(contains('kitchen_design_system')));
    expect(dataSource, isNot(contains('kitchen_recipe_library')));
    expect(dataSource, isNot(contains('package:flutter/material.dart')));
    expect(dataSource, isNot(contains('package:flutter/widgets.dart')));

    final templateSource = _librarySource(
      'packages/kitchen_recipe_template/lib',
    );
    expect(templateSource, isNot(contains('kitchen_recipe_data')));
    expect(templateSource, isNot(contains('kitchen_recipe_library')));
    expect(templateSource, isNot(contains('kitchen_recipe_editor')));

    final coreSource = _librarySource('packages/kitchen_app_core/lib');
    expect(coreSource, isNot(contains('kitchen_recipe_domain')));

    for (final package in featurePackages) {
      final source = _librarySource('packages/$package/lib');
      expect(source, isNot(contains('package:drift')), reason: package);
      expect(source, isNot(contains('Companion')), reason: package);
      expect(source, isNot(contains('RecipeDetailData')), reason: package);
    }
  });

  test('根 App 只保留组合根、路由和导航壳', () {
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .map((file) => file.path)
        .toSet();

    expect(files, {
      'lib/main.dart',
      'lib/src/kitchen_notes_app.dart',
      'lib/src/navigation/kitchen_notes_app_router.dart',
      'lib/src/navigation/kitchen_notes_main_shell.dart',
    });
    final source = _librarySource('lib');
    expect(source, isNot(contains('package:drift')));
    expect(source, isNot(contains('AppDatabase')));
  });

  test('跨 package 生产代码只导入公共 barrel', () {
    final packageLibraries = Directory('packages')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => file.path.contains('/lib/'));
    final rootLibraries = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in [...packageLibraries, ...rootLibraries]) {
      final source = file.readAsStringSync();
      expect(
        RegExp(r"package:kitchen_(?!notes/)[^/]+/src/").hasMatch(source),
        isFalse,
        reason: file.path,
      );
    }
  });

  test('组件内 Dart 文件使用唯一且统一的前缀', () {
    const prefixes = {
      'kitchen_app_core': 'kitchen_app_core_',
      'kitchen_design_system': 'kitchen_design_',
      'kitchen_home': 'kitchen_home_',
      'kitchen_import': 'kitchen_import_',
      'kitchen_profile': 'kitchen_profile_',
      'kitchen_recipe_data': 'kitchen_recipe_data_',
      'kitchen_recipe_domain': 'kitchen_recipe_domain_',
      'kitchen_recipe_editor': 'kitchen_recipe_editor_',
      'kitchen_recipe_library': 'kitchen_recipe_library_',
      'kitchen_recipe_template': 'kitchen_recipe_template_',
    };

    for (final MapEntry(key: package, value: prefix) in prefixes.entries) {
      final files = Directory('packages/$package')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .where((file) => !file.path.contains('/.dart_tool/'));
      for (final file in files) {
        final name = file.uri.pathSegments.last;
        final isBarrel =
            file.path.endsWith('/lib/$package.dart') && name == '$package.dart';
        expect(isBarrel || name.startsWith(prefix), isTrue, reason: file.path);
      }
    }

    final rootFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    for (final file in rootFiles) {
      final name = file.uri.pathSegments.last;
      expect(
        name == 'main.dart' || name.startsWith('kitchen_notes_'),
        isTrue,
        reason: file.path,
      );
    }

    final rootTests = Directory('test')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    for (final file in rootTests) {
      expect(
        file.uri.pathSegments.last.startsWith('kitchen_notes_'),
        isTrue,
        reason: file.path,
      );
    }
  });
}

String _librarySource(String path) {
  return Directory(path)
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .map((file) => file.readAsStringSync())
      .join('\n');
}
