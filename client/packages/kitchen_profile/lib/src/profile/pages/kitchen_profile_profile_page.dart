import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitchen_design_system/kitchen_design_system.dart';

import '../providers/kitchen_profile_personal_recipe_config_provider.dart';
import '../providers/kitchen_profile_visual_style_provider.dart';
import 'kitchen_profile_personal_recipe_page.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  String? _lastExportPath;

  @override
  Widget build(BuildContext context) {
    final style = ref.watch(visualStyleProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s16,
          AppSpacing.s8,
          AppSpacing.s16,
          AppSpacing.s24,
        ),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '默认菜谱风格',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s14),
                  SegmentedButton<AppVisualStyle>(
                    segments: const [
                      ButtonSegment(
                        value: AppVisualStyle.scrapbook,
                        icon: Icon(Icons.auto_awesome_rounded),
                        label: Text('手账'),
                      ),
                      ButtonSegment(
                        value: AppVisualStyle.minimal,
                        icon: Icon(Icons.crop_square_rounded),
                        label: Text('极简'),
                      ),
                    ],
                    selected: {style},
                    onSelectionChanged: (value) => ref
                        .read(visualStyleProvider.notifier)
                        .setStyle(value.first),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.tune_rounded),
              title: const Text('个性化食谱'),
              subtitle: const Text('管理分类、标签与难度'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const PersonalRecipePage(),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.auto_awesome_rounded),
                  title: const Text('云端智能整理'),
                  subtitle: const Text('本周期剩余次数将在接入服务后显示'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {},
                ),
                const Divider(height: AppSpacing.s1, indent: AppSpacing.s56),
                ListTile(
                  leading: const Icon(Icons.ondemand_video_rounded),
                  title: const Text('观看广告获取次数'),
                  subtitle: const Text('广告能力尚未接入'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud_outlined),
                  title: const Text('备份与同步'),
                  subtitle: const Text('当前所有数据仅保存在本机'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showLocalDataDialog(context, ref),
                ),
                const Divider(height: AppSpacing.s1, indent: AppSpacing.s56),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('隐私与数据'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showLocalDataDialog(BuildContext context, WidgetRef ref) async {
    final dependencies = ref.read(profileDependenciesProvider);
    final clearLocalData = dependencies.clearLocalData;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('本机资料与备份'),
        content: Text(
          '登录不会自动备份、上传或转移本机菜谱。换设备登录也不会自动恢复旧资料，只有使用受支持的备份并主动恢复后才可以恢复。\n\n'
          '当前版本不提供同一设备内的多账号资料隔离；账号删除默认保留本机资料。'
          '${_lastExportPath == null ? '' : '\n\n最近一次导出：$_lastExportPath'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('知道了'),
          ),
          if (clearLocalData != null)
            FilledButton.tonal(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (confirmContext) => AlertDialog(
                    title: const Text('清除本机全部资料？'),
                    content: const Text(
                      '这会删除本机菜谱、菜谱集、导入草稿和受控图片，且不会删除服务端账号。此操作不可撤销，请先确认已有备份。',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () =>
                            Navigator.of(confirmContext).pop(false),
                        child: const Text('取消'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(confirmContext).pop(true),
                        child: const Text('确认清除'),
                      ),
                    ],
                  ),
                );
                if (confirmed != true || !context.mounted) return;
                try {
                  await clearLocalData();
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('本机资料已清除。')));
                  }
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('本机资料未完全清除，请稍后重试。')),
                    );
                  }
                }
              },
              child: const Text('清除本机资料'),
            ),
          if (dependencies.exportBackup != null)
            FilledButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  final path = await dependencies.exportBackup!();
                  if (mounted) setState(() => _lastExportPath = path);
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('备份已生成：$path')));
                  }
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('备份生成失败，请检查本机空间。')),
                    );
                  }
                }
              },
              child: const Text('导出本机备份'),
            ),
          if (dependencies.restoreBackup != null)
            TextButton(
              onPressed: () async {
                final controller = TextEditingController();
                final path = await showDialog<String>(
                  context: context,
                  builder: (restoreContext) => AlertDialog(
                    title: const Text('覆盖恢复本机备份'),
                    content: TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        labelText: '备份文件路径',
                        hintText: '粘贴 .zip 文件路径',
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(restoreContext).pop(),
                        child: const Text('取消'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(
                          restoreContext,
                        ).pop(controller.text.trim()),
                        child: const Text('下一步'),
                      ),
                    ],
                  ),
                );
                controller.dispose();
                if (path == null || path.isEmpty || !context.mounted) return;
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (confirmContext) => AlertDialog(
                    title: const Text('确认覆盖本机资料？'),
                    content: const Text(
                      '恢复会替换当前菜谱、菜谱集、导入草稿和图片。损坏或不兼容的备份不会修改当前资料。',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () =>
                            Navigator.of(confirmContext).pop(false),
                        child: const Text('取消'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(confirmContext).pop(true),
                        child: const Text('确认覆盖'),
                      ),
                    ],
                  ),
                );
                if (confirmed != true || !context.mounted) return;
                try {
                  await dependencies.restoreBackup!(path);
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('本机备份已恢复。')));
                  }
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('恢复失败，当前资料保持不变。')),
                    );
                  }
                }
              },
              child: const Text('覆盖恢复'),
            ),
        ],
      ),
    );
  }
}
