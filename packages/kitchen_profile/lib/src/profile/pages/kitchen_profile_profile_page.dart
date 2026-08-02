import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitchen_design_system/kitchen_design_system.dart';

import '../providers/kitchen_profile_visual_style_provider.dart';
import 'kitchen_profile_personal_recipe_page.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  onTap: () {},
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
}
