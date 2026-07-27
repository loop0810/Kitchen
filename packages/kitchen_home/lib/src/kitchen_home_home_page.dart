import 'package:flutter/material.dart';
import 'package:kitchen_app_core/kitchen_app_core.dart';
import 'package:kitchen_design_system/kitchen_design_system.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search() {
    final query = _searchController.text.trim();
    context.pushSearch(query);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
        child: Column(
          children: [
            const Spacer(flex: 3),
            Container(
              width: AppSize.icon58,
              height: AppSize.icon58,
              decoration: const BoxDecoration(
                color: AppColor.blush,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.soup_kitchen_rounded,
                color: AppColor.coral,
                size: AppSize.icon30,
              ),
            ),
            const SizedBox(height: AppSpacing.s22),
            Text(
              '今天想吃点什么？',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: AppSpacing.s28),
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: '搜索菜名、食材或标签',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  tooltip: '搜索',
                  onPressed: _search,
                  icon: const Icon(Icons.arrow_forward_rounded),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s20),
            Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    icon: Icons.auto_awesome_rounded,
                    label: '快速导入',
                    onTap: context.goToImportInbox,
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.edit_note_rounded,
                    label: '手动创建',
                    onTap: context.pushCreateRecipe,
                  ),
                ),
              ],
            ),
            const Spacer(flex: 4),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: AppSize.icon20),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        foregroundColor: AppColor.ink,
        side: const BorderSide(color: AppColor.butter),
        backgroundColor: AppColor.white.withValues(alpha: 0.7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.r16),
        ),
      ),
    );
  }
}
