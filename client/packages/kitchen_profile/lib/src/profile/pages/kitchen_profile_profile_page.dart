import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitchen_design_system/kitchen_design_system.dart';
import 'package:kitchen_auth_domain/kitchen_auth_domain.dart';

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
          _AccountCard(
            session: session,
            repository: authRepository,
            signInWithApple: signInWithApple,
            signInWithPhone: dependencies?.signInWithPhone,
          ),
          const SizedBox(height: AppSpacing.s12),
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
      if (context.mounted) showKitchenMessage(context, '账号删除请求失败，请稍后重试。');
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
                final confirmed = await showKitchenConfirmDialog(
                  context,
                  title: '清除本机全部资料？',
                  message:
                      '这会删除本机菜谱、菜谱集、导入草稿和受控图片，且不会删除服务端账号。此操作不可撤销，请先确认已有备份。',
                  confirmLabel: '确认清除',
                );
                if (!confirmed || !context.mounted) return;
                await _reportLocalDataResult(
                  context,
                  clearLocalData,
                  successMessage: (_) => '本机资料已清除。',
                  failureMessage: '本机资料未完全清除，请稍后重试。',
                );
              },
              child: const Text('清除本机资料'),
            ),
          if (dependencies.exportBackup != null)
            FilledButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final path = await _reportLocalDataResult(
                  context,
                  dependencies.exportBackup!,
                  successMessage: (path) => '备份已生成：$path',
                  failureMessage: '备份生成失败，请检查本机空间。',
                );
                if (path != null && mounted) {
                  setState(() => _lastExportPath = path);
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
                final confirmed = await showKitchenConfirmDialog(
                  context,
                  title: '确认覆盖本机资料？',
                  message: '恢复会替换当前菜谱、菜谱集、导入草稿和图片。损坏或不兼容的备份不会修改当前资料。',
                  confirmLabel: '确认覆盖',
                );
                if (!confirmed || !context.mounted) return;
                await _reportLocalDataResult(
                  context,
                  () => dependencies.restoreBackup!(path),
                  successMessage: (_) => '本机备份已恢复。',
                  failureMessage: '恢复失败，当前资料保持不变。',
                );
              },
              child: const Text('覆盖恢复'),
            ),
        ],
      ),
    );
  }
}

/// 本机备份与清除共用的执行包装：统一在异步返回后检查 context 生命周期，
/// 成功与失败都只通过 SnackBar 反馈，失败时返回 `null` 让调用方跳过后续副作用。
Future<T?> _reportLocalDataResult<T>(
  BuildContext context,
  Future<T> Function() action, {
  required String Function(T value) successMessage,
  required String failureMessage,
}) async {
  try {
    final value = await action();
    if (context.mounted) showKitchenMessage(context, successMessage(value));
    return value;
  } catch (_) {
    if (context.mounted) showKitchenMessage(context, failureMessage);
    return null;
  }
}

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
                      showKitchenMessage(context, 'Apple 登录未完成，本地功能仍可继续使用。');
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
      showKitchenMessage(context, '请输入有效的中国大陆手机号。');
      return;
    }
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      showKitchenMessage(context, '请输入 6 位验证码。');
      return;
    }
    final success = await signInWithPhone!(phone, code);
    if (!context.mounted || success) return;
    showKitchenMessage(context, '模拟手机号登录失败，本地功能仍可继续使用。');
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
    final confirmed = await showKitchenConfirmDialog(
      context,
      title: '解绑 Apple 登录？',
      message: '解绑后不能再使用当前 Apple 身份登录。若这是账号最后一个登录身份，服务端会拒绝解绑。',
      confirmLabel: '确认解绑',
    );
    if (!confirmed || !context.mounted) return;
    try {
      await widget.repository.unbindIdentity(identity.id);
      if (!mounted) return;
      setState(() => _identities = widget.repository.listIdentities());
      showKitchenMessage(this.context, 'Apple 登录已解绑。');
    } catch (_) {
      if (!context.mounted) return;
      showKitchenMessage(context, '解绑失败，可能需要近期重新登录或保留至少一个登录身份。');
    }
  }
}
