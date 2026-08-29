import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_design_system/kitchen_design_system.dart';

void main() {
  test('手账与极简主题保持各自的颜色和卡片形态', () {
    final scrapbook = AppTheme.forStyle(AppVisualStyle.scrapbook);
    final minimal = AppTheme.forStyle(AppVisualStyle.minimal);

    expect(scrapbook.scaffoldBackgroundColor, AppColor.xFFFAF2);
    expect(minimal.scaffoldBackgroundColor, AppColor.xF8FAF9);
    expect(scrapbook.cardTheme.elevation, 1);
    expect(minimal.cardTheme.elevation, 0);
  });

  test('导航壳复用两套主题的表面色和前景色', () {
    final scrapbook = AppTheme.forStyle(AppVisualStyle.scrapbook);
    final minimal = AppTheme.forStyle(AppVisualStyle.minimal);

    expect(scrapbook.appBarTheme.backgroundColor, AppColor.xFFFAF2);
    expect(scrapbook.appBarTheme.foregroundColor, AppColor.x60483A);
    expect(scrapbook.navigationBarTheme.backgroundColor, AppColor.xFFFDF8);
    expect(scrapbook.navigationBarTheme.indicatorColor, AppColor.xF5DDD5);
    expect(
      scrapbook.navigationBarTheme.labelTextStyle?.resolve({})?.color,
      AppColor.x60483A,
    );

    expect(minimal.appBarTheme.backgroundColor, AppColor.xFFFFFF);
    expect(minimal.appBarTheme.foregroundColor, AppColor.x60483A);
    expect(minimal.navigationBarTheme.backgroundColor, AppColor.xFFFFFF);
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
    expect(AppColor.xF26A58, const Color(0xFFF26A58));
    expect(AppSpacing.s16, 16);
    expect(AppRadius.r18, 18);
    expect(AppText.title, 22);
  });

  test('首页原型控件复用对应的颜色、尺寸和圆角', () {
    expect(AppColor.xFFFDF6, const Color(0xFFFFFDF6));
    expect(AppColor.xEADCC3, const Color(0xFFEADCC3));
    expect(AppColor.xA94B3F, const Color(0xFFA94B3F));
    expect(AppRadius.r22, 22);
    expect(AppSize.homeControlHeight, 56);
  });
}
