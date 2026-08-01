import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'kitchen_recipe_template_decoration_layer.dart';
import 'kitchen_recipe_template_definition.dart';
import 'kitchen_recipe_template_rect_value_object.dart';
import 'kitchen_recipe_template_render_data.dart';
import 'kitchen_recipe_template_slot.dart';
import 'kitchen_recipe_template_text_style_value_object.dart';

class RecipeTemplateRendererWidget extends StatelessWidget {
  const RecipeTemplateRendererWidget({
    super.key,
    required this.definition,
    required this.data,
    required this.mode,
  });

  final TemplateDefinition definition;
  final TemplateRenderData data;
  final TemplateRenderMode mode;

  @override
  Widget build(BuildContext context) {
    // 模板内部元素很多，但无障碍用户需要的是菜谱摘要而非每个装饰节点。
    // 外层提供一条完整语义，内部通过 ExcludeSemantics 避免重复朗读。
    return Semantics(
      container: true,
      label: _semanticLabel,
      child: ExcludeSemantics(
        // 模板卡片经常出现在滚动列表中，RepaintBoundary 将其绘制与周围 UI 隔离。
        child: RepaintBoundary(
          child: AspectRatio(
            aspectRatio: definition.aspectRatio,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 模板以固定设计宽度定义字号，渲染时按实际卡片宽度同比缩放。
                final fontScale = constraints.maxWidth / definition.designWidth;
                return ColoredBox(
                  color: Color(definition.canvasColorValue),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (final decoration in definition.decorationLayers)
                        if (mode == TemplateRenderMode.reader ||
                            decoration.visibleInThumbnail)
                          _positioned(
                            decoration.rect,
                            constraints,
                            IgnorePointer(
                              child: ExcludeSemantics(
                                child: _DecorationWidget(
                                  decoration: decoration,
                                  scale: fontScale,
                                ),
                              ),
                            ),
                          ),
                      for (final slot in definition.slots)
                        if (mode == TemplateRenderMode.reader ||
                            slot.visibleInThumbnail)
                          _positioned(
                            slot.rect,
                            constraints,
                            _SlotWidget(
                              slot: slot,
                              data: data,
                              mode: mode,
                              fontScale: fontScale,
                            ),
                          ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  String get _semanticLabel {
    final ingredients = data.primaryIngredients.isEmpty
        ? '食材待补充'
        : data.primaryIngredients
              .map(
                (ingredient) => '${ingredient.name} ${ingredient.amountText}',
              )
              .join('，');
    final status = data.isIncomplete ? '，待完善' : '';
    return '${data.title}。主要食材：$ingredients$status';
  }

  Widget _positioned(
    TemplateRectValueObject rect,
    BoxConstraints constraints,
    Widget child,
  ) {
    // 槽位使用 0～1 标准化坐标，同一模板因此能适配详情预览和较小的列表缩略图。
    return Positioned(
      left: constraints.maxWidth * rect.left,
      top: constraints.maxHeight * rect.top,
      width: constraints.maxWidth * rect.width,
      height: constraints.maxHeight * rect.height,
      child: child,
    );
  }
}

class _DecorationWidget extends StatelessWidget {
  const _DecorationWidget({required this.decoration, required this.scale});

  final TemplateDecorationLayer decoration;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: decoration.rotationDegrees * math.pi / 180,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Color(decoration.colorValue),
          borderRadius: BorderRadius.circular(decoration.borderRadius * scale),
        ),
      ),
    );
  }
}

class _SlotWidget extends StatelessWidget {
  const _SlotWidget({
    required this.slot,
    required this.data,
    required this.mode,
    required this.fontScale,
  });

  final TemplateSlot slot;
  final TemplateRenderData data;
  final TemplateRenderMode mode;
  final double fontScale;

  @override
  Widget build(BuildContext context) {
    final content = switch (slot.kind) {
      TemplateSlotKind.recipeTitle => _text(data.title),
      TemplateSlotKind.primaryIngredients => _ingredients(),
      TemplateSlotKind.detailAction => _text(
        mode == TemplateRenderMode.reader ? '查看详细步骤 →' : '查看详情 →',
      ),
      TemplateSlotKind.category => _text(data.category),
      TemplateSlotKind.totalTime => _text(
        data.totalMinutes == null ? '时间待补充' : '${data.totalMinutes} 分钟',
      ),
    };
    return Align(alignment: _alignment(slot.alignment), child: content);
  }

  Widget _ingredients() {
    if (data.primaryIngredients.isEmpty) {
      return _text('食材待补充');
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final ingredient in data.primaryIngredients.take(slot.maxLines))
          LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                children: [
                  Expanded(
                    child: Text(
                      ingredient.name,
                      maxLines: 1,
                      overflow: _overflow,
                      style: _style,
                    ),
                  ),
                  SizedBox(width: 6 * fontScale),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      // 限制用量列宽，优先给更有识别价值的食材名称留空间。
                      maxWidth: constraints.maxWidth * 0.42,
                    ),
                    child: Text(
                      ingredient.amountText,
                      maxLines: 1,
                      overflow: _overflow,
                      textAlign: TextAlign.end,
                      style: _style,
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _text(String value) {
    return Text(
      value,
      maxLines: slot.maxLines,
      overflow: _overflow,
      textAlign: _textAlign,
      style: _style,
    );
  }

  TextStyle get _style {
    return TextStyle(
      color: Color(slot.textStyle.colorValue),
      fontSize: slot.textStyle.fontSize * fontScale,
      fontWeight:
          FontWeight.values[(slot.textStyle.fontWeight ~/ 100 - 1).clamp(0, 8)],
      height: 1.25,
    );
  }

  TextOverflow get _overflow {
    return switch (slot.overflowRule) {
      TemplateOverflowRule.ellipsis => TextOverflow.ellipsis,
      TemplateOverflowRule.clip => TextOverflow.clip,
    };
  }

  TextAlign get _textAlign {
    return switch (slot.textStyle.alignment) {
      TemplateTextAlignment.start => TextAlign.start,
      TemplateTextAlignment.center => TextAlign.center,
      TemplateTextAlignment.end => TextAlign.end,
    };
  }

  Alignment _alignment(TemplateContentAlignment alignment) {
    return switch (alignment) {
      TemplateContentAlignment.topLeft => Alignment.topLeft,
      TemplateContentAlignment.topCenter => Alignment.topCenter,
      TemplateContentAlignment.topRight => Alignment.topRight,
      TemplateContentAlignment.centerLeft => Alignment.centerLeft,
      TemplateContentAlignment.center => Alignment.center,
      TemplateContentAlignment.centerRight => Alignment.centerRight,
      TemplateContentAlignment.bottomLeft => Alignment.bottomLeft,
      TemplateContentAlignment.bottomCenter => Alignment.bottomCenter,
      TemplateContentAlignment.bottomRight => Alignment.bottomRight,
    };
  }
}
