import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitchen_design_system/kitchen_design_system.dart';

class VisualStyleNotifier extends Notifier<AppVisualStyle> {
  @override
  AppVisualStyle build() => AppVisualStyle.scrapbook;

  void setStyle(AppVisualStyle style) => state = style;
}

final visualStyleProvider =
    NotifierProvider<VisualStyleNotifier, AppVisualStyle>(
      VisualStyleNotifier.new,
    );
