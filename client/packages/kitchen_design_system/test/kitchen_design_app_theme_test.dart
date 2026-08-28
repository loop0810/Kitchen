import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_design_system/kitchen_design_system.dart';

void main() {
  test('手账与极简主题保持各自的颜色和卡片形态', () {
    final scrapbook = AppTheme.forStyle(AppVisualStyle.scrapbook);
    final minimal = AppTheme.forStyle(AppVisualStyle.minimal);

    expect(scrapbook.scaffoldBackgroundColor, AppColor.paper);
    expect(minimal.scaffoldBackgroundColor, AppColor.minimalSurface);
    expect(scrapbook.cardTheme.elevation, 1);
    expect(minimal.cardTheme.elevation, 0);
  });

  test('导航壳复用两套主题的表面色和前景色', () {
    final scrapbook = AppTheme.forStyle(AppVisualStyle.scrapbook);
    final minimal = AppTheme.forStyle(AppVisualStyle.minimal);

    expect(scrapbook.appBarTheme.backgroundColor, AppColor.paper);
    expect(scrapbook.appBarTheme.foregroundColor, AppColor.ink);
    expect(scrapbook.navigationBarTheme.backgroundColor, AppColor.card);
    expect(scrapbook.navigationBarTheme.indicatorColor, AppColor.blush);
    expect(
      scrapbook.navigationBarTheme.labelTextStyle?.resolve({})?.color,
      AppColor.ink,
    );

    expect(minimal.appBarTheme.backgroundColor, AppColor.white);
    expect(minimal.appBarTheme.foregroundColor, AppColor.ink);
    expect(minimal.navigationBarTheme.backgroundColor, AppColor.white);
    expect(
      minimal.navigationBarTheme.indicatorColor,
      minimal.colorScheme.primaryContainer,
    );
    expect(
      minimal.navigationBarTheme.labelTextStyle?.resolve({
        WidgetState.selected,
      })?.color,
      minimal.colorScheme.primary,
    );
  });

  test('核心视觉常量保持迁移前数值', () {
    expect(AppColor.coral, const Color(0xFFD96B58));
    expect(AppSpacing.s16, 16);
    expect(AppRadius.r18, 18);
    expect(AppText.title, 22);
  });
}
