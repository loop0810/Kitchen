import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_recipe_template/kitchen_recipe_template.dart';

void main() {
  const data = TemplateRenderData(
    title: '番茄炒蛋',
    primaryIngredients: [
      TemplateIngredientData(name: '番茄', amountText: '2 个'),
      TemplateIngredientData(name: '鸡蛋', amountText: '3 个'),
    ],
    category: '家常菜',
    totalMinutes: 15,
    isIncomplete: false,
  );

  testWidgets('缩略和阅读模式复用模板且只在阅读模式显示详情提示', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 240,
            child: RecipeTemplateRendererWidget(
              definition: BuiltInTemplates.basicJournal,
              data: data,
              mode: TemplateRenderMode.thumbnail,
            ),
          ),
        ),
      ),
    );

    expect(find.text('番茄炒蛋'), findsOneWidget);
    expect(find.text('番茄'), findsOneWidget);
    expect(find.text('2 个'), findsOneWidget);
    expect(find.text('查看详情 →'), findsNothing);
    expect(find.bySemanticsLabel('番茄炒蛋。主要食材：番茄 2 个，鸡蛋 3 个'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 240,
            child: RecipeTemplateRendererWidget(
              definition: BuiltInTemplates.basicJournal,
              data: data,
              mode: TemplateRenderMode.reader,
            ),
          ),
        ),
      ),
    );

    expect(find.text('查看详细步骤 →'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('没有主要食材时显示可读降级文案并标记待完善', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 240,
            child: RecipeTemplateRendererWidget(
              definition: BuiltInTemplates.basicJournal,
              data: TemplateRenderData(
                title: '待补菜谱',
                primaryIngredients: [],
                category: '其他',
                totalMinutes: null,
                isIncomplete: true,
              ),
              mode: TemplateRenderMode.thumbnail,
            ),
          ),
        ),
      ),
    );

    expect(find.text('食材待补充'), findsOneWidget);
    expect(find.bySemanticsLabel('待补菜谱。主要食材：食材待补充，待完善'), findsOneWidget);
  });

  testWidgets('长标题和长食材名截断时仍保留食材数量', (tester) async {
    const longTitle = '这是一道名称非常非常长需要在手账摘要中截断但详情仍保留完整内容的菜谱';
    const longIngredient = '这是一项名称非常非常长的主要食材';
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 160,
            child: RecipeTemplateRendererWidget(
              definition: BuiltInTemplates.basicJournal,
              data: TemplateRenderData(
                title: longTitle,
                primaryIngredients: [
                  TemplateIngredientData(
                    name: longIngredient,
                    amountText: '250 克',
                  ),
                ],
                category: '家常菜',
                totalMinutes: null,
                isIncomplete: false,
              ),
              mode: TemplateRenderMode.thumbnail,
            ),
          ),
        ),
      ),
    );

    final title = tester.widget<Text>(find.text(longTitle));
    final ingredient = tester.widget<Text>(find.text(longIngredient));

    expect(title.maxLines, 2);
    expect(title.overflow, TextOverflow.ellipsis);
    expect(ingredient.overflow, TextOverflow.ellipsis);
    expect(find.text('250 克'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
