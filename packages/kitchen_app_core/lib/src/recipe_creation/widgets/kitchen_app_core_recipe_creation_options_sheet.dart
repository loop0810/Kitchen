import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../navigation/models/kitchen_app_core_app_route_names.dart';

enum RecipeCreationOption { manual, paste, images }

Future<void> showRecipeCreationOptions(BuildContext context) {
  return showRecipeCreationOptionsSheet(context);
}

Future<void> showRecipeCreationOptionsSheet(BuildContext context) async {
  final option = await showModalBottomSheet<RecipeCreationOption>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      // 最大高度配合滚动容器，系统大字体下三个选项仍能完整访问。
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.8,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '创建菜谱',
                style: Theme.of(sheetContext).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                '选择一种开始方式，整理结果都会由你确认后保存。',
                style: Theme.of(sheetContext).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              _OptionTile(
                icon: Icons.edit_note_rounded,
                title: '手动创建',
                subtitle: '从空白菜谱开始填写',
                onTap: () =>
                    Navigator.pop(sheetContext, RecipeCreationOption.manual),
              ),
              _OptionTile(
                icon: Icons.content_paste_rounded,
                title: '粘贴文章或链接',
                subtitle: '粘贴完整文章，或其中的公开 HTTPS 链接',
                onTap: () =>
                    Navigator.pop(sheetContext, RecipeCreationOption.paste),
              ),
              _OptionTile(
                icon: Icons.photo_library_outlined,
                title: '选择图片',
                subtitle: '从相册选择一张或多张图片',
                onTap: () =>
                    Navigator.pop(sheetContext, RecipeCreationOption.images),
              ),
            ],
          ),
        ),
      );
    },
  );
  if (!context.mounted || option == null) return;
  switch (option) {
    case RecipeCreationOption.manual:
      await context.pushNamed(AppRouteNames.createRecipe);
    case RecipeCreationOption.paste:
      await context.pushNamed(AppRouteNames.pasteImport);
    case RecipeCreationOption.images:
      await context.pushNamed(AppRouteNames.imageImport);
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        minVerticalPadding: 16,
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
