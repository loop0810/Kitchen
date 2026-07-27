import 'package:flutter/material.dart';
import 'package:kitchen_app_core/kitchen_app_core.dart';
import 'package:kitchen_design_system/kitchen_design_system.dart';

class ImportInboxPage extends StatelessWidget {
  const ImportInboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('导入箱')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: AppSize.importIllustration,
              height: AppSize.importIllustration,
              decoration: const BoxDecoration(
                color: AppColor.blush,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inbox_rounded,
                size: AppSize.icon36,
                color: AppColor.coral,
              ),
            ),
            const SizedBox(height: AppSpacing.s20),
            Text(
              '把看到的菜谱收进来',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              '链接、文字和截图导入将在下一阶段接入。\n现在可以先手动创建自己的菜谱。',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColor.mutedInk,
                height: AppText.bodyLineHeight,
              ),
            ),
            const SizedBox(height: AppSpacing.s24),
            FilledButton.icon(
              onPressed: context.pushCreateRecipe,
              icon: const Icon(Icons.edit_note_rounded),
              label: const Text('手动创建'),
            ),
          ],
        ),
      ),
    );
  }
}
