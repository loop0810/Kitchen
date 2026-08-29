import 'package:flutter/material.dart';

import '../foundation/kitchen_design_app_color.dart';
import '../foundation/kitchen_design_app_radius.dart';
import '../foundation/kitchen_design_app_size.dart';
import '../foundation/kitchen_design_app_spacing.dart';
import '../foundation/kitchen_design_app_text.dart';
import 'models/kitchen_design_app_visual_style.dart';

abstract final class AppTheme {
  static ThemeData forStyle(AppVisualStyle style) {
    final scrapbook = style == AppVisualStyle.scrapbook;
    final scheme = ColorScheme.fromSeed(
      seedColor: scrapbook ? AppColor.xF26A58 : AppColor.x506E67,
      brightness: Brightness.light,
      surface: scrapbook ? AppColor.xFFFAF2 : AppColor.xF8FAF9,
    );
    final appBarSurface = scrapbook ? AppColor.xFFFAF2 : AppColor.xFFFFFF;
    final navigationSurface = scrapbook ? AppColor.xFFFDF8 : AppColor.xFFFFFF;
    final navigationIndicator = scrapbook
        ? AppColor.xF5DDD5
        : scheme.primaryContainer;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      fontFamilyFallback: const [
        'PingFang SC',
        'Noto Sans CJK SC',
        'Microsoft YaHei',
      ],
      textTheme: ThemeData.light().textTheme.apply(
        bodyColor: AppColor.x60483A,
        displayColor: AppColor.x60483A,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: appBarSurface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        foregroundColor: AppColor.x60483A,
        titleTextStyle: TextStyle(
          color: AppColor.x60483A,
          fontSize: AppText.title,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: scrapbook ? 1 : 0,
        color: scrapbook ? AppColor.xFFFDF8 : AppColor.xFFFFFF,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            scrapbook ? AppRadius.r18 : AppRadius.r14,
          ),
          side: BorderSide(
            color: scrapbook
                ? AppColor.xE8DAC1.withValues(alpha: 0.6)
                : AppColor.xE6ECEA,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColor.xFFFFFF,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s20,
          vertical: AppSpacing.s16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.r28),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.r28),
          borderSide: BorderSide(
            color: scrapbook ? AppColor.xE8DAC1 : AppColor.xDDE5E2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.r28),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: navigationSurface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        indicatorColor: navigationIndicator,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected && !scrapbook ? scheme.primary : AppColor.x60483A,
            fontSize: AppText.label,
            fontWeight: FontWeight.w600,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, AppSize.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.r16),
          ),
          textStyle: const TextStyle(
            fontSize: AppText.body,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
