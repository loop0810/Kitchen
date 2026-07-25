import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kitchen_notes/src/theme/app_theme.dart';

class ImportInboxScreen extends StatelessWidget {
  const ImportInboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('导入箱')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.blush,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inbox_rounded,
                size: 36,
                color: AppColors.coral,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '把看到的菜谱收进来',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              '链接、文字和截图导入将在下一阶段接入。\n现在可以先手动创建自己的菜谱。',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.mutedInk,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push('/recipes/new'),
              icon: const Icon(Icons.edit_note_rounded),
              label: const Text('手动创建'),
            ),
          ],
        ),
      ),
    );
  }
}
