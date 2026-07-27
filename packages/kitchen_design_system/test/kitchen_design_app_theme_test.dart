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

  test('核心视觉常量保持迁移前数值', () {
    expect(AppColor.coral, const Color(0xFFD96B58));
    expect(AppSpacing.s16, 16);
    expect(AppRadius.r18, 18);
    expect(AppText.title, 22);
  });
}
