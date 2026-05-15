import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../settings/font_weight_option.dart';
import '../settings/settings_repository.dart';
import '../theme/app_theme.dart';
import '../ui/app_panel.dart';
import '../ui/latest_snack_bar.dart';
import '../network/nat_traversal_models.dart';
import '../network/nat_traversal_repository.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key, required this.section});

  final String section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = _SettingsSection.fromId(section);
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 920;
          return Column(
            children: [
              _SettingsTopBar(current: current),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    wide ? 28 : 16,
                    0,
                    wide ? 28 : 16,
                    24,
                  ),
                  child: wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 220,
                              child: _SettingsNavigation(current: current),
                            ),
                            const SizedBox(width: 16),
                            Expanded(child: _SettingsBody(section: current)),
                          ],
                        )
                      : Column(
                          children: [
                            _MobileSettingsSelector(current: current),
                            const SizedBox(height: 16),
                            Expanded(child: _SettingsBody(section: current)),
                          ],
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SettingsTopBar extends StatelessWidget {
  const _SettingsTopBar({required this.current});

  final _SettingsSection current;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 65,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '设置 · ${current.title}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const Text('本地优先 · 可加密同步', style: TextStyle(color: AppColors.muted)),
        ],
      ),
    );
  }
}

class _SettingsNavigation extends StatelessWidget {
  const _SettingsNavigation({required this.current});

  final _SettingsSection current;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          for (final section in _SettingsSection.values)
            _SectionButton(section: section, selected: current == section),
        ],
      ),
    );
  }
}

class _MobileSettingsSelector extends StatelessWidget {
  const _MobileSettingsSelector({required this.current});

  final _SettingsSection current;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: [
        for (final section in _SettingsSection.values)
          ButtonSegment(
            value: section.id,
            label: Text(section.title),
            icon: Icon(section.icon),
          ),
      ],
      selected: {current.id},
      onSelectionChanged: (value) {
        context.go('/settings/${value.first}');
      },
    );
  }
}

class _SectionButton extends StatelessWidget {
  const _SectionButton({required this.section, required this.selected});

  final _SettingsSection section;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.bg : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: () => context.go('/settings/${section.id}'),
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          height: 44,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Icon(section.icon, size: 20, color: AppColors.muted),
                const SizedBox(width: 10),
                Expanded(child: Text(section.title)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsBody extends StatelessWidget {
  const _SettingsBody({required this.section});

  final _SettingsSection section;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: switch (section) {
        _SettingsSection.personalization => const _PersonalizationPanel(),
        _SettingsSection.network => const _NetworkSettingsPanel(),
        _SettingsSection.about => const _AboutPanel(),
      },
    );
  }
}

class _PersonalizationPanel extends ConsumerWidget {
  const _PersonalizationPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferredWeight = ref.watch(preferredFontWeightProvider);
    final selected = preferredWeight.maybeWhen(
      data: (value) => value.value,
      orElse: () => defaultFontWeightOption.value,
    );
    return AppPanel(
      title: '字体粗细',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '选择应用内主要文字的字重。设置会立即生效，并写入本地数据库。',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in fontWeightOptions)
                ChoiceChip(
                  label: Text(option.label),
                  selected: selected == option.value,
                  onSelected: (_) async {
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await ref
                          .read(settingsRepositoryProvider)
                          .setPreferredFontWeight(option.value);
                    } catch (_) {
                      messenger.showLatestSnackBar(
                        const SnackBar(content: Text('字体设置保存失败，已保留原设置')),
                      );
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.bg,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '预览：个人工具箱使用 HarmonyOS Sans SC 作为主要字体，适合中文界面和高频工具操作。',
              style: TextStyle(
                fontSize: 18,
                height: 1.6,
                fontWeight: fontWeightOptionFromValue(selected).weight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NetworkSettingsPanel extends ConsumerStatefulWidget {
  const _NetworkSettingsPanel();

  @override
  ConsumerState<_NetworkSettingsPanel> createState() =>
      _NetworkSettingsPanelState();
}

class _NetworkSettingsPanelState extends ConsumerState<_NetworkSettingsPanel> {
  final _stunController = TextEditingController();
  final _tcpStunController = TextEditingController();
  final _turnController = TextEditingController();
  final _turnUsernameController = TextEditingController();
  final _turnPasswordController = TextEditingController();
  final _tcpKeepAliveController = TextEditingController();
  bool _loaded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadConfig());
  }

  @override
  void dispose() {
    _stunController.dispose();
    _tcpStunController.dispose();
    _turnController.dispose();
    _turnUsernameController.dispose();
    _turnPasswordController.dispose();
    _tcpKeepAliveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: 'NAT 穿透服务器',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'UDP STUN 用于检测公网映射和 NAT 行为；TCP 映射需要一个支持 TCP 的 STUN 服务器和一个 HTTP 保活服务器。TURN 用于中继兜底。',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 18),
          if (!_loaded) ...[
            const LinearProgressIndicator(),
          ] else ...[
            TextField(
              controller: _stunController,
              decoration: const InputDecoration(
                labelText: 'UDP STUN 服务器',
                hintText: NatTraversalConfig.defaultStunServer,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tcpStunController,
              decoration: const InputDecoration(
                labelText: 'TCP STUN 服务器',
                hintText: NatTraversalConfig.defaultTcpStunServer,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _turnController,
              decoration: const InputDecoration(
                labelText: 'TURN 服务器',
                hintText: 'turn.example.com:3478',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _turnUsernameController,
              decoration: const InputDecoration(labelText: 'TURN 用户名'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _turnPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'TURN 密码'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tcpKeepAliveController,
              decoration: const InputDecoration(
                labelText: 'TCP HTTP 保活服务器',
                hintText: NatTraversalConfig.defaultTcpKeepAliveServer,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bg,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '注意：TCP 模式会从同一本地端口建立 HTTP 保活和 TCP STUN 映射，再监听该端口转发到本地服务。UDP 检测为 Full Cone 只说明 UDP 行为正常；TCP STUN 地址还必须能接受 TCP 连接。',
                style: TextStyle(color: AppColors.muted),
              ),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _saving ? null : _saveConfig,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_saving ? '保存中...' : '保存服务器设置'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _loadConfig() async {
    final config = await ref.read(natTraversalRepositoryProvider).loadConfig();
    if (!mounted) {
      return;
    }
    setState(() {
      _stunController.text = config.stunServer;
      _tcpStunController.text = config.tcpStunServer;
      _turnController.text = config.turnServer;
      _turnUsernameController.text = config.turnUsername;
      _turnPasswordController.text = config.turnPassword;
      _tcpKeepAliveController.text = config.tcpKeepAliveServer;
      _loaded = true;
    });
  }

  Future<void> _saveConfig() async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(natTraversalRepositoryProvider)
          .saveConfig(
            NatTraversalConfig(
              stunServer: _stunController.text.trim().isEmpty
                  ? NatTraversalConfig.defaultStunServer
                  : _stunController.text.trim(),
              tcpStunServer: _tcpStunController.text.trim().isEmpty
                  ? NatTraversalConfig.defaultTcpStunServer
                  : _tcpStunController.text.trim(),
              turnServer: _turnController.text.trim(),
              turnUsername: _turnUsernameController.text.trim(),
              turnPassword: _turnPasswordController.text,
              tcpKeepAliveServer: _tcpKeepAliveController.text.trim().isEmpty
                  ? NatTraversalConfig.defaultTcpKeepAliveServer
                  : _tcpKeepAliveController.text.trim(),
            ),
          );
      messenger.showLatestSnackBar(
        const SnackBar(content: Text('NAT 穿透服务器设置已保存')),
      );
    } catch (_) {
      messenger.showLatestSnackBar(
        const SnackBar(content: Text('NAT 穿透服务器设置保存失败')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

class _AboutPanel extends StatelessWidget {
  const _AboutPanel();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppPanel(
          title: '个人工具箱',
          child: Wrap(
            runSpacing: 12,
            children: const [
              _InfoRow(label: '当前版本', value: '1.0.0'),
              _InfoRow(label: '数据存储', value: '本地 SQLite，支持加密 WebDAV 快照同步'),
              _InfoRow(label: '主要字体', value: 'HarmonyOS Sans SC'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const AppPanel(
          title: '当前项目技术链',
          child: Wrap(
            runSpacing: 12,
            children: [
              _InfoRow(label: '应用框架', value: 'Flutter'),
              _InfoRow(label: '编程语言', value: 'Dart'),
              _InfoRow(label: '状态管理', value: 'flutter_riverpod'),
              _InfoRow(label: '路由', value: 'go_router'),
              _InfoRow(label: '本地数据库', value: 'Drift + SQLite'),
              _InfoRow(label: '本地路径', value: 'path_provider'),
              _InfoRow(
                label: 'Steam 状态后端',
                value: '内置 Python 侧车（statushack 重构集成）',
              ),
              _InfoRow(label: '同步协议', value: 'WebDAV'),
              _InfoRow(label: '加密', value: 'AES-256-GCM + PBKDF2-HMAC-SHA256'),
              _InfoRow(label: '字体', value: 'HarmonyOS Sans SC'),
              _InfoRow(
                label: '目标平台',
                value: 'Windows 优先，保留 Android/iOS/macOS/Linux 工程',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppPanel(
          title: '字体与许可',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '本应用使用 HarmonyOS Sans 字体。字体文件保持未修改状态，许可证文件随应用资源一并保留。',
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () => _showFontLicense(context),
                icon: const Icon(Icons.article_outlined),
                label: const Text('查看字体许可证'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const AppPanel(
          title: '数据与同步',
          child: Text(
            'WebDAV 同步使用 personal-toolbox/state.v1.enc.json 文件。同步数据在本地加密后上传，冲突默认按最后写入时间处理。Steam 状态工具中的预设与历史会参与同步，但账号凭证仅保存在本机。',
            style: TextStyle(color: AppColors.muted),
          ),
        ),
      ],
    );
  }

  Future<void> _showFontLicense(BuildContext context) async {
    final license = await rootBundle.loadString(
      'assets/fonts/harmony_os_sans_sc/LICENSE.txt',
    );
    if (!context.mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('HarmonyOS Sans 许可证'),
        content: SizedBox(
          width: 640,
          child: SingleChildScrollView(
            child: Text(license.replaceAll('\u0000', '').trim()),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 340,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}

enum _SettingsSection {
  personalization('personalization', '个性化', Icons.tune_outlined),
  network('network', '网络', Icons.router_outlined),
  about('about', '关于', Icons.info_outline);

  const _SettingsSection(this.id, this.title, this.icon);

  final String id;
  final String title;
  final IconData icon;

  static _SettingsSection fromId(String id) {
    return values.firstWhere(
      (section) => section.id == id,
      orElse: () => personalization,
    );
  }
}
