import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../network/nat_traversal_models.dart';
import '../network/nat_traversal_repository.dart';
import '../settings/font_weight_option.dart';
import '../settings/settings_repository.dart';
import '../sync/sync_service.dart';
import '../sync/webdav_client.dart';
import '../theme/app_theme.dart';
import '../ui/app_panel.dart';
import '../ui/latest_snack_bar.dart';

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
  final _stunServersController = TextEditingController();
  final _turnController = TextEditingController();
  final _turnUsernameController = TextEditingController();
  final _turnPasswordController = TextEditingController();
  final _tcpKeepAliveController = TextEditingController();
  final _webDavBaseUrlController = TextEditingController();
  final _webDavUsernameController = TextEditingController();
  final _webDavPasswordController = TextEditingController();
  final _syncPassphraseController = TextEditingController();
  bool _loaded = false;
  bool _natSaving = false;
  bool _webDavSaving = false;
  bool _webDavTesting = false;
  bool _syncPassphraseSaving = false;
  bool _syncUploading = false;
  bool _syncDownloading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadConfig());
  }

  @override
  void dispose() {
    _stunServersController.dispose();
    _turnController.dispose();
    _turnUsernameController.dispose();
    _turnPasswordController.dispose();
    _tcpKeepAliveController.dispose();
    _webDavBaseUrlController.dispose();
    _webDavUsernameController.dispose();
    _webDavPasswordController.dispose();
    _syncPassphraseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppPanel(
          title: 'NAT 穿透服务器',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'STUN 服务器列表由你提供，一行一个。检测时会并行测试整份列表，并分别选出 UDP NAT 检测和 TCP STUN 探测延迟最低的可用服务器。TURN 用于中继兜底。',
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 18),
              if (!_loaded) ...[
                const LinearProgressIndicator(),
              ] else ...[
                TextField(
                  controller: _stunServersController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'STUN 服务器列表',
                    hintText:
                        '一行一个，例如：\nstun.l.google.com:19302\nstun.nextcloud.com:443',
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
                    onPressed: _natSaving ? null : _saveNatConfig,
                    icon: _natSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_natSaving ? '保存中...' : '保存 NAT 设置'),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppPanel(
          title: 'WebDAV 同步服务器',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '配置 WebDAV 服务器地址和账号信息，后续同步会复用这里保存的连接参数。同步快照仍会在本地加密后再上传。',
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 18),
              if (!_loaded) ...[
                const LinearProgressIndicator(),
              ] else ...[
                TextField(
                  controller: _webDavBaseUrlController,
                  decoration: const InputDecoration(
                    labelText: 'WebDAV 服务器地址',
                    hintText:
                        'http://dav.example.com/... 或 https://dav.example.com/...',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _webDavUsernameController,
                  decoration: const InputDecoration(labelText: 'WebDAV 用户名'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _webDavPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'WebDAV 密码'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _syncPassphraseController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: '同步加密口令',
                    hintText: '用于加密上传和解密下载的同一口令',
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
                    '远端同步文件固定写入 personal-toolbox/state.v1.enc.json。建议把地址指向你的 WebDAV 根目录或用户目录。同步口令会参与本地加密和解密；如果点击“保存口令”，它会以明文形式保存在本机应用设置中。',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _busyWithWebDavActions
                            ? null
                            : _testWebDavConnection,
                        icon: _webDavTesting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.wifi_tethering_outlined),
                        label: Text(_webDavTesting ? '测试中...' : '测试连接'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _busyWithWebDavActions
                            ? null
                            : _saveSyncPassphrase,
                        icon: _syncPassphraseSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.key_outlined),
                        label: Text(_syncPassphraseSaving ? '保存中...' : '保存口令'),
                      ),
                      FilledButton.icon(
                        onPressed: _busyWithWebDavActions
                            ? null
                            : _saveWebDavConfig,
                        icon: _webDavSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.cloud_sync_outlined),
                        label: Text(_webDavSaving ? '保存中...' : '保存 WebDAV 设置'),
                      ),
                      FilledButton.icon(
                        onPressed: _busyWithWebDavActions ? null : _uploadSync,
                        icon: _syncUploading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.cloud_upload_outlined),
                        label: Text(_syncUploading ? '上传中...' : '上传同步'),
                      ),
                      FilledButton.icon(
                        onPressed: _busyWithWebDavActions
                            ? null
                            : _downloadSync,
                        icon: _syncDownloading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.cloud_download_outlined),
                        label: Text(_syncDownloading ? '下载中...' : '下载同步'),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _loadConfig() async {
    final results = await Future.wait([
      ref.read(natTraversalRepositoryProvider).loadConfig(),
      ref.read(settingsRepositoryProvider).loadWebDavSyncConfig(),
      ref.read(settingsRepositoryProvider).loadSyncPassphrase(),
    ]);
    final natConfig = results[0] as NatTraversalConfig;
    final webDavConfig = results[1] as WebDavSyncServerConfig;
    if (!mounted) {
      return;
    }
    setState(() {
      _stunServersController.text = natConfig.stunServers.join('\n');
      _turnController.text = natConfig.turnServer;
      _turnUsernameController.text = natConfig.turnUsername;
      _turnPasswordController.text = natConfig.turnPassword;
      _tcpKeepAliveController.text = natConfig.tcpKeepAliveServer;
      _webDavBaseUrlController.text = webDavConfig.baseUrl;
      _webDavUsernameController.text = webDavConfig.username;
      _webDavPasswordController.text = webDavConfig.password;
      _syncPassphraseController.text = results[2] as String;
      _loaded = true;
    });
  }

  Future<void> _saveNatConfig() async {
    setState(() => _natSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final stunServers = _parseStunServerLines(_stunServersController.text);
      await ref
          .read(natTraversalRepositoryProvider)
          .saveConfig(
            NatTraversalConfig(
              stunServers: stunServers.isEmpty
                  ? NatTraversalConfig.defaultStunServers
                  : stunServers,
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
        setState(() => _natSaving = false);
      }
    }
  }

  List<String> _parseStunServerLines(String rawText) {
    final seen = <String>{};
    final result = <String>[];
    for (final line in rawText.split(RegExp(r'\r?\n'))) {
      final value = line.trim();
      if (value.isEmpty || !seen.add(value)) {
        continue;
      }
      result.add(value);
    }
    return result;
  }

  Future<void> _saveWebDavConfig() async {
    setState(() => _webDavSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(settingsRepositoryProvider)
          .saveWebDavSyncConfig(
            WebDavSyncServerConfig(
              baseUrl: _webDavBaseUrlController.text.trim(),
              username: _webDavUsernameController.text.trim(),
              password: _webDavPasswordController.text,
            ),
          );
      messenger.showLatestSnackBar(
        const SnackBar(content: Text('WebDAV 同步服务器设置已保存')),
      );
    } catch (_) {
      messenger.showLatestSnackBar(
        const SnackBar(content: Text('WebDAV 同步服务器设置保存失败')),
      );
    } finally {
      if (mounted) {
        setState(() => _webDavSaving = false);
      }
    }
  }

  Future<void> _saveSyncPassphrase() async {
    final passphrase = _syncPassphraseController.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    if (passphrase.isEmpty) {
      messenger.showLatestSnackBar(const SnackBar(content: Text('请先填写同步加密口令')));
      return;
    }

    setState(() => _syncPassphraseSaving = true);
    try {
      await ref.read(settingsRepositoryProvider).saveSyncPassphrase(passphrase);
      messenger.showLatestSnackBar(
        const SnackBar(content: Text('同步加密口令已保存到本机')),
      );
    } catch (_) {
      messenger.showLatestSnackBar(const SnackBar(content: Text('同步加密口令保存失败')));
    } finally {
      if (mounted) {
        setState(() => _syncPassphraseSaving = false);
      }
    }
  }

  Future<void> _testWebDavConnection() async {
    final messenger = ScaffoldMessenger.of(context);
    final config = _currentWebDavConfig;
    if (!config.isConfigured) {
      messenger.showLatestSnackBar(
        const SnackBar(content: Text('请先填写完整的 WebDAV 地址、用户名和密码')),
      );
      return;
    }

    setState(() => _webDavTesting = true);
    try {
      final success = await ref
          .read(webDavClientProvider)
          .testConnection(config.toWebDavConfig());
      if (!mounted) {
        return;
      }
      messenger.showLatestSnackBar(
        SnackBar(
          content: Text(success ? 'WebDAV 连接成功' : 'WebDAV 连接失败，请检查地址、账号或密码'),
        ),
      );
    } catch (error) {
      messenger.showLatestSnackBar(
        SnackBar(content: Text('WebDAV 连接测试失败：$error')),
      );
    } finally {
      if (mounted) {
        setState(() => _webDavTesting = false);
      }
    }
  }

  Future<void> _uploadSync() async {
    final messenger = ScaffoldMessenger.of(context);
    final config = _currentWebDavConfig;
    final passphrase = _syncPassphraseController.text.trim();
    if (!config.isConfigured) {
      messenger.showLatestSnackBar(
        const SnackBar(content: Text('请先填写完整的 WebDAV 地址、用户名和密码')),
      );
      return;
    }
    if (passphrase.isEmpty) {
      messenger.showLatestSnackBar(const SnackBar(content: Text('请先填写同步加密口令')));
      return;
    }

    setState(() => _syncUploading = true);
    try {
      await ref
          .read(syncServiceProvider)
          .uploadEncryptedSnapshot(
            config: config.toWebDavConfig(),
            passphrase: passphrase,
          );
      messenger.showLatestSnackBar(
        const SnackBar(content: Text('同步快照已上传到 WebDAV')),
      );
    } catch (error) {
      messenger.showLatestSnackBar(SnackBar(content: Text('上传同步失败：$error')));
    } finally {
      if (mounted) {
        setState(() => _syncUploading = false);
      }
    }
  }

  Future<void> _downloadSync() async {
    final messenger = ScaffoldMessenger.of(context);
    final config = _currentWebDavConfig;
    final passphrase = _syncPassphraseController.text.trim();
    if (!config.isConfigured) {
      messenger.showLatestSnackBar(
        const SnackBar(content: Text('请先填写完整的 WebDAV 地址、用户名和密码')),
      );
      return;
    }
    if (passphrase.isEmpty) {
      messenger.showLatestSnackBar(const SnackBar(content: Text('请先填写同步加密口令')));
      return;
    }

    setState(() => _syncDownloading = true);
    try {
      final hasRemoteSnapshot = await ref
          .read(syncServiceProvider)
          .downloadEncryptedSnapshot(
            config: config.toWebDavConfig(),
            passphrase: passphrase,
          );
      messenger.showLatestSnackBar(
        SnackBar(
          content: Text(
            hasRemoteSnapshot ? '已从 WebDAV 下载并导入同步快照' : '远端还没有可下载的同步快照',
          ),
        ),
      );
    } catch (error) {
      messenger.showLatestSnackBar(SnackBar(content: Text('下载同步失败：$error')));
    } finally {
      if (mounted) {
        setState(() => _syncDownloading = false);
      }
    }
  }

  bool get _busyWithWebDavActions =>
      _webDavSaving ||
      _webDavTesting ||
      _syncPassphraseSaving ||
      _syncUploading ||
      _syncDownloading;

  WebDavSyncServerConfig get _currentWebDavConfig {
    return WebDavSyncServerConfig(
      baseUrl: _webDavBaseUrlController.text.trim(),
      username: _webDavUsernameController.text.trim(),
      password: _webDavPasswordController.text,
    );
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
