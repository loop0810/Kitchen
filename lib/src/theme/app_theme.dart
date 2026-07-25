import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppVisualStyle { minimal, scrapbook }

class VisualStyleNotifier extends Notifier<AppVisualStyle> {
  @override
  AppVisualStyle build() => AppVisualStyle.scrapbook;

  void setStyle(AppVisualStyle style) => state = style;
}

final visualStyleProvider =
    NotifierProvider<VisualStyleNotifier, AppVisualStyle>(
      VisualStyleNotifier.new,
    );

abstract final class AppColors {
  static const paper = Color(0xFFFFFAF2);
  static const coral = Color(0xFFD96B58);
  static const butter = Color(0xFFF4DFA7);
  static const sage = Color(0xFFA9B9A2);
  static const ink = Color(0xFF403B37);
  static const mutedInk = Color(0xFF7E756E);
  static const blush = Color(0xFFF5DDD5);
}

abstract final class AppTheme {
  static ThemeData forStyle(AppVisualStyle style) {
    final scrapbook = style == AppVisualStyle.scrapbook;
    final scheme = ColorScheme.fromSeed(
      seedColor: scrapbook ? AppColors.coral : const Color(0xFF506E67),
      brightness: Brightness.light,
      surface: scrapbook ? AppColors.paper : const Color(0xFFF8FAF9),
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
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        titleTextStyle: const TextStyle(
          color: AppColors.ink,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: scrapbook ? 1 : 0,
        color: scrapbook ? const Color(0xFFFFFDF8) : Colors.white,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(scrapbook ? 18 : 14),
          side: BorderSide(
            color: scrapbook
                ? AppColors.butter.withValues(alpha: 0.6)
                : const Color(0xFFE6ECEA),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(
            color: scrapbook ? AppColors.butter : const Color(0xFFDDE5E2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: scrapbook ? AppColors.blush : scheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
