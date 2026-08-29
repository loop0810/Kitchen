import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitchen_design_system/kitchen_design_system.dart';
import 'package:kitchen_auth_domain/kitchen_auth_domain.dart';

import '../providers/kitchen_profile_personal_recipe_config_provider.dart';
import '../providers/kitchen_profile_visual_style_provider.dart';
import 'kitchen_profile_personal_recipe_page.dart';

const _profileChefAsset = 'assets/images/profile_hero_chef.png';
const _profileDefaultStyleAsset =
    'assets/images/profile_default_recipe_style.png';
const _profilePersonalizedRecipeAsset =
    'assets/images/profile_personalized_recipe.png';
const _profileLocalDataAsset = 'assets/images/profile_local_data.png';
const _profileAccountSecurityAsset =
    'assets/images/profile_account_security.png';
const _profilePrivacyPolicyAsset = 'assets/images/profile_privacy_policy.png';
const _profileUserAgreementAsset = 'assets/images/profile_user_agreement.png';
const _profileAboutInfoAsset = 'assets/images/profile_about_info.png';
const _profileFeedbackAsset = 'assets/images/profile_feedback.png';
const _profileNoteBookAsset = 'assets/images/profile_notebook.png';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  String? _lastExportPath;
  _ProfilePreviewMode? _previewMode;

  @override
  Widget build(BuildContext context) {
    final style = ref.watch(visualStyleProvider);
    // 视觉风格测试和极简嵌入场景可以不装配账号服务；真正需要本地资料操作时，
    // 仍由对应入口读取组合根依赖并给出明确错误。
    ProfileDependencies? dependencies;
    try {
      dependencies = ref.read(profileDependenciesProvider);
    } catch (_) {
      dependencies = null;
    }
    final authRepository = dependencies?.authSessionRepository;
    final signInWithApple = dependencies?.signInWithApple;
    final session = authRepository == null
        ? const AsyncValue<AuthSessionState>.data(AuthSessionState.anonymous())
        : ref.watch(_profileSessionProvider(authRepository));
    final previewMode = _previewMode ?? _profilePreviewModeForSession(session);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s24,
            AppSpacing.s12,
            AppSpacing.s24,
            AppSpacing.s24,
          ),
          children: [
            const _ProfileHeader(),
            const SizedBox(height: AppSpacing.s28),
            _ProfilePreviewSelector(
              selected: previewMode,
              onSelected: (value) => setState(() => _previewMode = value),
            ),
            const SizedBox(height: AppSpacing.s16),
            _LocalUseCard(
              mode: previewMode,
              onTap: () => _showAccountSheet(
                session: session,
                repository: authRepository,
                signInWithApple: signInWithApple,
                signInWithPhone: dependencies?.signInWithPhone,
              ),
            ),
            const SizedBox(height: AppSpacing.s20),
            _ProfileSection(
              title: '菜谱偏好',
              child: _ProfileOptionList(
                children: [
                  _ProfileOptionRow(
                    assetPath: _profileDefaultStyleAsset,
                    title: '默认菜谱风格',
                    trailing: _StyleValue(
                      style: style,
                      onTap: () => _showStylePicker(style),
                    ),
                    onTap: () => _showStylePicker(style),
                  ),
                  _ProfileOptionRow(
                    assetPath: _profilePersonalizedRecipeAsset,
                    title: '个性化食谱',
                    subtitle: '管理分类、标签与难度',
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => const PersonalRecipePage(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s20),
            _ProfileSection(
              title: '隐私与帮助',
              child: _ProfileOptionList(
                children: [
                  _ProfileOptionRow(
                    assetPath: _profileLocalDataAsset,
                    title: '管理本机资料',
                    // subtitle: '导出、恢复或清除本机菜谱',
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _showLocalDataDialog(context, ref),
                  ),
                  _ProfileOptionRow(
                    assetPath: _profileAccountSecurityAsset,
                    title: '账号与安全',
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _showAccountSheet(
                      session: session,
                      repository: authRepository,
                      signInWithApple: signInWithApple,
                      signInWithPhone: dependencies?.signInWithPhone,
                    ),
                  ),
                  _ProfileOptionRow(
                    assetPath: _profilePrivacyPolicyAsset,
                    title: '隐私政策',
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {},
                  ),
                  _ProfileOptionRow(
                    assetPath: _profileUserAgreementAsset,
                    title: '用户协议',
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {},
                  ),
                  _ProfileOptionRow(
                    assetPath: _profileAboutInfoAsset,
                    title: '权限与数据说明',
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {},
                  ),
                  _ProfileOptionRow(
                    assetPath: _profileFeedbackAsset,
                    title: '意见反馈 / 联系我们',
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {},
                  ),
                  _ProfileOptionRow(
                    assetPath: _profileNoteBookAsset,
                    title: '关于厨房手记',
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {},
                  ),
                  
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s20),
            // const _AboutKitchenNotes(),
          ],
        ),
      ),
    );
  }

  Future<void> _showStylePicker(AppVisualStyle currentStyle) async {
    final selected = await showModalBottomSheet<AppVisualStyle>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppVisualStyle.values
              .map(
                (value) => ListTile(
                  leading: Icon(
                    value == currentStyle
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                  ),
                  title: Text(_visualStyleLabel(value)),
                  onTap: () => Navigator.of(context).pop(value),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (selected != null && mounted) {
      ref.read(visualStyleProvider.notifier).setStyle(selected);
    }
  }

  Future<void> _showAccountSheet({
    required AsyncValue<AuthSessionState> session,
    required AuthSessionRepository? repository,
    required Future<bool> Function()? signInWithApple,
    required Future<bool> Function(String phone, String code)? signInWithPhone,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: _AccountCard(
            session: session,
            repository: repository,
            signInWithApple: signInWithApple,
            signInWithPhone: signInWithPhone,
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    AuthSessionRepository repository,
  ) async {
    var clearLocalData = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('删除账号'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('删除账号会撤销全部设备会话并进入服务端清理流程。此操作与清除本机菜谱相互独立。'),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: clearLocalData,
                onChanged: (value) =>
                    setState(() => clearLocalData = value ?? false),
                title: const Text('同时清除本机资料'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('确认删除'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await repository.deleteAccount(clearLocalData: clearLocalData);
      if (clearLocalData) {
        await ref.read(profileDependenciesProvider).clearLocalData?.call();
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('账号删除请求失败，请稍后重试。')));
      }
    }
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

enum _ProfilePreviewMode { loggedOut, loggedIn, local }

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '我的厨房',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: AppColor.x60483A,
            fontSize: AppText.libraryTitle,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        const Text(
          '记录每一顿认真的饭',
          style: TextStyle(
            color: AppColor.x7E756E,
            fontSize: AppText.body,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _ProfilePreviewSelector extends StatelessWidget {
  const _ProfilePreviewSelector({
    required this.selected,
    required this.onSelected,
  });

  final _ProfilePreviewMode selected;
  final ValueChanged<_ProfilePreviewMode> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          '预览状态',
          style: TextStyle(
            color: AppColor.x7E756E,
            fontSize: AppText.body,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: AppSpacing.s12),
        Expanded(
          child: _ProfileSegmentedControl<_ProfilePreviewMode>(
            value: selected,
            values: _ProfilePreviewMode.values,
            labelBuilder: _profilePreviewModeLabel,
            onChanged: onSelected,
          ),
        ),
      ],
    );
  }
}

class _ProfileSegmentedControl<T> extends StatelessWidget {
  const _ProfileSegmentedControl({
    required this.value,
    required this.values,
    required this.labelBuilder,
    required this.onChanged,
  });

  final T value;
  final List<T> values;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColor.xE8DAC1, width: 2),
        borderRadius: BorderRadius.circular(AppRadius.r22),
      ),
      child: Row(
        children: [
          for (final item in values)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(item),
                behavior: HitTestBehavior.opaque,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: item == value
                        ? AppColor.xF5DDD5
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.r16),
                  ),
                  child: Center(
                    child: Text(
                      labelBuilder(item),
                      style: TextStyle(
                        color: item == value
                            ? AppColor.xA94B3F
                            : AppColor.x7E756E,
                        fontSize: AppText.body,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LocalUseCard extends StatelessWidget {
  const _LocalUseCard({required this.mode, required this.onTap});

  final _ProfilePreviewMode mode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _ProfileSurface(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.r28),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s20,
            AppSpacing.s20,
            AppSpacing.s20,
            AppSpacing.s16,
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    _profileChefAsset,
                    package: 'kitchen_profile',
                    width: 64,
                    height: 64,
                    fit: BoxFit.contain,
                    semanticLabel: '厨房手记插图',
                  ),
                  const SizedBox(width: AppSpacing.s16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                _profilePreviewModeTitle(mode),
                                style: const TextStyle(
                                  color: AppColor.x60483A,
                                  fontSize: AppText.title,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.s8),
                            _ProfileStatusChip(
                              label: _profilePreviewModeBadge(mode),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s8),
                        Text(
                          _profilePreviewModeSubtitle(mode),
                          style: const TextStyle(
                            color: AppColor.x7E756E,
                            fontSize: AppText.body,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColor.xA98B7C,
                    size: AppSize.icon30,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s20),
              const Row(
                children: [
                  Expanded(
                    child: _ProfileStat(
                      value: '12',
                      label: '本机收藏',
                      color: Color(0xFFD05B4B),
                    ),
                  ),
                  _ProfileStatDivider(),
                  Expanded(
                    child: _ProfileStat(
                      value: '8',
                      label: '本周做过',
                      color: Color(0xFFD99418),
                    ),
                  ),
                  _ProfileStatDivider(),
                  Expanded(
                    child: _ProfileStat(
                      value: '3',
                      label: '待核对',
                      color: Color(0xFF75A05A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s16),
              const _ProfileDashedDivider(),
              const SizedBox(height: AppSpacing.s12),
              const Text(
                '以上数据仅来自这台设备的本地菜谱',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColor.xA98B7C,
                  fontSize: AppText.detail,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: AppText.title,
            fontWeight: FontWeight.w700,
          ).copyWith(color: color),
        ),
        const SizedBox(height: AppSpacing.s4),
        Text(
          label,
          style: const TextStyle(
            color: AppColor.x7E756E,
            fontSize: AppText.detail,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ProfileStatDivider extends StatelessWidget {
  const _ProfileStatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 52, color: AppColor.xEADCC3);
  }
}

class _ProfileDashedDivider extends StatelessWidget {
  const _ProfileDashedDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      width: double.infinity,
      child: CustomPaint(painter: _ProfileDashedLinePainter()),
    );
  }
}

class _ProfileDashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColor.xEADCC3
      ..strokeWidth = 1.5;
    const dashWidth = 5.0;
    const gap = 4.0;
    var start = 0.0;
    while (start < size.width) {
      canvas.drawLine(
        Offset(start, 0),
        Offset((start + dashWidth).clamp(0, size.width), 0),
        paint,
      );
      start += dashWidth + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ProfileStatusChip extends StatelessWidget {
  const _ProfileStatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColor.xF5DDD5,
        borderRadius: BorderRadius.circular(AppRadius.r10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s10,
          vertical: AppSpacing.s4,
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColor.xA94B3F,
            fontSize: AppText.detail,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _ProfileSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s20,
              AppSpacing.s20,
              AppSpacing.s20,
              AppSpacing.s8,
            ),
            child: Text(
              title,
              style: const TextStyle(
                color: AppColor.xA98B7C,
                fontSize: AppText.body,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _ProfileSurface extends StatelessWidget {
  const _ProfileSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.r28);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColor.xFFFDF8,
        border: Border.all(color: AppColor.xE8DAC1, width: 2),
        borderRadius: radius,
        boxShadow: const [
          BoxShadow(color: AppColor.xEADCC3, offset: Offset(0, 4)),
        ],
      ),
      child: ClipRRect(borderRadius: radius, child: child),
    );
  }
}

class _ProfileOptionList extends StatelessWidget {
  const _ProfileOptionList({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < children.length; index++) ...[
          children[index],
          if (index < children.length - 1)
            const Divider(height: AppSpacing.s1, indent: AppSpacing.s56),
        ],
      ],
    );
  }
}

class _ProfileOptionRow extends StatelessWidget {
  const _ProfileOptionRow({
    required this.assetPath,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.highlighted = false,
  });

  final String assetPath;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s16,
        AppSpacing.s12,
        AppSpacing.s12,
        AppSpacing.s12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _ProfileIcon(assetPath: assetPath),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColor.x60483A,
                    fontSize: AppText.body,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: AppColor.x7E756E,
                      fontSize: AppText.detail,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.s8),
            trailing!,
          ],
        ],
      ),
    );
    if (!highlighted) {
      return InkWell(onTap: onTap, child: content);
    }
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Color(0xFFFFF2D7),
            borderRadius: BorderRadius.circular(AppRadius.r16),
          ),
          child: content,
        ),
      ),
    );
  }
}

class _ProfileIcon extends StatelessWidget {
  const _ProfileIcon({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      package: 'kitchen_profile',
      width: AppSize.icon20,
      height: AppSize.icon20,
      fit: BoxFit.contain,
      excludeFromSemantics: true,
    );
  }
}

class _StyleValue extends StatelessWidget {
  const _StyleValue({required this.style, required this.onTap});

  final AppVisualStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.r10),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s8,
          vertical: AppSpacing.s4,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _visualStyleLabel(style),
              style: const TextStyle(
                color: AppColor.x7E756E,
                fontSize: AppText.detail,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
            const Text(
              '切换',
              style: TextStyle(
                color: AppColor.xA94B3F,
                fontSize: AppText.detail,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutKitchenNotes extends StatelessWidget {
  const _AboutKitchenNotes();

  @override
  Widget build(BuildContext context) {
    return _ProfileSurface(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '关于厨房手记',
              style: TextStyle(
                color: AppColor.x60483A,
                fontSize: AppText.body,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              '登录只用于账号能力，本地菜谱的创建、导入、编辑与查看无需登录。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColor.x7E756E,
                fontSize: AppText.detail,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

_ProfilePreviewMode _profilePreviewModeForSession(
  AsyncValue<AuthSessionState> session,
) {
  return switch (session.valueOrNull?.status) {
    AuthSessionStatus.authenticated ||
    AuthSessionStatus.refreshing => _ProfilePreviewMode.loggedIn,
    AuthSessionStatus.authenticating ||
    AuthSessionStatus.invalid ||
    AuthSessionStatus.anonymous ||
    null => _ProfilePreviewMode.loggedOut,
  };
}

String _profilePreviewModeLabel(_ProfilePreviewMode mode) => switch (mode) {
  _ProfilePreviewMode.loggedOut => '未登录',
  _ProfilePreviewMode.loggedIn => '已登录',
  _ProfilePreviewMode.local => '本地使用',
};

String _profilePreviewModeTitle(_ProfilePreviewMode mode) =>
    _profilePreviewModeLabel(mode);

String _profilePreviewModeBadge(_ProfilePreviewMode mode) => switch (mode) {
  _ProfilePreviewMode.loggedOut || _ProfilePreviewMode.local => '本机资料',
  _ProfilePreviewMode.loggedIn => '已同步',
};

String _profilePreviewModeSubtitle(_ProfilePreviewMode mode) => switch (mode) {
  _ProfilePreviewMode.loggedOut || _ProfilePreviewMode.local => '本地菜谱无需登录即可使用',
  _ProfilePreviewMode.loggedIn => '本地菜谱可在登录后同步使用',
};

String _visualStyleLabel(AppVisualStyle style) => switch (style) {
  AppVisualStyle.scrapbook => '手账',
  AppVisualStyle.minimal => '极简',
};

final _profileSessionProvider = StreamProvider.autoDispose
    .family<AuthSessionState, AuthSessionRepository>(
      (ref, repository) => repository.watch(),
    );

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.session,
    required this.repository,
    required this.signInWithApple,
    required this.signInWithPhone,
  });

  final AsyncValue<AuthSessionState> session;
  final AuthSessionRepository? repository;
  final Future<bool> Function()? signInWithApple;
  final Future<bool> Function(String phone, String code)? signInWithPhone;

  @override
  Widget build(BuildContext context) {
    final value = session.valueOrNull;
    final status = value?.status ?? AuthSessionStatus.authenticating;
    final title = switch (status) {
      AuthSessionStatus.authenticated || AuthSessionStatus.refreshing => '已登录',
      AuthSessionStatus.authenticating => '正在恢复会话',
      AuthSessionStatus.invalid => '会话已失效',
      AuthSessionStatus.anonymous => '未登录',
    };
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.account_circle_outlined),
            title: Text(title),
            subtitle: Text(value?.userId ?? '登录可用于账号与设备会话管理，本地菜谱无需登录。'),
          ),
          if (signInWithApple != null &&
              status != AuthSessionStatus.authenticated)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s16,
                0,
                AppSpacing.s16,
                AppSpacing.s12,
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.apple),
                  label: const Text('通过 Apple 登录'),
                  onPressed: () async {
                    final success = await signInWithApple!();
                    if (!context.mounted || success) return;
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Apple 登录未完成，本地功能仍可继续使用。'),
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          if (signInWithPhone != null &&
              status != AuthSessionStatus.authenticated)
            ListTile(
              leading: const Icon(Icons.sms_outlined),
              title: const Text('模拟手机号登录'),
              subtitle: const Text('开发模式验证码：111111'),
              onTap: () => _showMockPhoneDialog(context),
            ),
          if (repository != null &&
              status == AuthSessionStatus.authenticated) ...[
            const Divider(height: AppSpacing.s1, indent: AppSpacing.s56),
            _AppleIdentitySection(repository: repository!),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('退出当前设备'),
              onTap: repository!.signOutCurrentDevice,
            ),
            ListTile(
              leading: const Icon(Icons.devices),
              title: const Text('退出全部设备'),
              onTap: repository!.signOutAllDevices,
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('删除账号'),
              onTap: () =>
                  (context.findAncestorStateOfType<_ProfilePageState>())
                      ?._confirmDeleteAccount(context, repository!),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showMockPhoneDialog(BuildContext context) async {
    final values = await showDialog<({String phone, String code})>(
      context: context,
      builder: (_) => const _MockPhoneLoginDialog(),
    );
    if (values == null || !context.mounted) return;
    final phone = values.phone;
    final code = values.code;
    if (!_isValidCnPhone(phone)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入有效的中国大陆手机号。')));
      return;
    }
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入 6 位验证码。')));
      return;
    }
    final success = await signInWithPhone!(phone, code);
    if (!context.mounted || success) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('模拟手机号登录失败，本地功能仍可继续使用。')));
  }

  bool _isValidCnPhone(String value) {
    final compact = value.replaceAll(RegExp(r'[\s()-]'), '');
    final local = compact.startsWith('+86')
        ? compact.substring(3)
        : compact.startsWith('0086')
        ? compact.substring(4)
        : compact;
    return RegExp(r'^1[3-9]\d{9}$').hasMatch(local);
  }
}

class _MockPhoneLoginDialog extends StatefulWidget {
  const _MockPhoneLoginDialog();

  @override
  State<_MockPhoneLoginDialog> createState() => _MockPhoneLoginDialogState();
}

class _MockPhoneLoginDialogState extends State<_MockPhoneLoginDialog> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController(text: '111111');

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('模拟手机号登录'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: '中国大陆手机号'),
          ),
          TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: '验证码（111111）'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(
            context,
          ).pop((phone: _phoneController.text, code: _codeController.text)),
          child: const Text('登录'),
        ),
      ],
    );
  }
}

/// 账号设置只展示服务端确认过的 Apple 身份；解绑失败时保留当前状态并提示原因。
class _AppleIdentitySection extends StatefulWidget {
  const _AppleIdentitySection({required this.repository});

  final AuthSessionRepository repository;

  @override
  State<_AppleIdentitySection> createState() => _AppleIdentitySectionState();
}

class _AppleIdentitySectionState extends State<_AppleIdentitySection> {
  late Future<List<AuthIdentitySummary>> _identities;

  @override
  void initState() {
    super.initState();
    _identities = widget.repository.listIdentities();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AuthIdentitySummary>>(
      future: _identities,
      builder: (context, snapshot) {
        final apple = snapshot.data
            ?.where((identity) => identity.provider == 'apple')
            .firstOrNull;
        if (apple == null) return const SizedBox.shrink();
        final detail = apple.email == null || apple.email!.isEmpty
            ? 'Apple 身份已绑定'
            : 'Apple 身份已绑定 · ${apple.email}';
        return ListTile(
          leading: const Icon(Icons.apple),
          title: const Text('Apple 登录'),
          subtitle: Text(apple.status == 'active' ? detail : 'Apple 身份已撤销'),
          trailing: TextButton(
            onPressed: apple.status != 'active'
                ? null
                : () => _unbind(context, apple),
            child: const Text('解绑'),
          ),
        );
      },
    );
  }

  Future<void> _unbind(
    BuildContext context,
    AuthIdentitySummary identity,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('解绑 Apple 登录？'),
        content: const Text('解绑后不能再使用当前 Apple 身份登录。若这是账号最后一个登录身份，服务端会拒绝解绑。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('确认解绑'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await widget.repository.unbindIdentity(identity.id);
      if (!mounted) return;
      setState(() => _identities = widget.repository.listIdentities());
      ScaffoldMessenger.of(
        this.context,
      ).showSnackBar(const SnackBar(content: Text('Apple 登录已解绑。')));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('解绑失败，可能需要近期重新登录或保留至少一个登录身份。')),
      );
    }
  }
}
