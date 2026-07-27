import 'package:flutter/material.dart';

import 'kitchen_design_app_color.dart';
import 'kitchen_design_app_radius.dart';
import 'kitchen_design_app_size.dart';
import 'kitchen_design_app_spacing.dart';
import 'kitchen_design_app_text.dart';
import 'kitchen_design_app_visual_style.dart';

abstract final class AppTheme {
  static ThemeData forStyle(AppVisualStyle style) {
    final scrapbook = style == AppVisualStyle.scrapbook;
    final scheme = ColorScheme.fromSeed(
      seedColor: scrapbook ? AppColor.coral : AppColor.minimalSeed,
      brightness: Brightness.light,
      surface: scrapbook ? AppColor.paper : AppColor.minimalSurface,
    );

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
        bodyColor: AppColor.ink,
        displayColor: AppColor.ink,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColor.ink,
        titleTextStyle: TextStyle(
          color: AppColor.ink,
          fontSize: AppText.title,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: scrapbook ? 1 : 0,
        color: scrapbook ? AppColor.card : Colors.white,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            scrapbook ? AppRadius.r18 : AppRadius.r14,
          ),
          side: BorderSide(
            color: scrapbook
                ? AppColor.butter.withValues(alpha: 0.6)
                : AppColor.minimalBorder,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
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
            color: scrapbook ? AppColor.butter : AppColor.minimalInputBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.r28),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: scrapbook ? AppColor.blush : scheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: AppText.label, fontWeight: FontWeight.w600),
        ),
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
