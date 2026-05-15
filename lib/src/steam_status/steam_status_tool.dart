import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/app_database.dart';
import '../theme/app_theme.dart';
import '../ui/app_panel.dart';
import '../ui/latest_snack_bar.dart';
import 'steam_status_models.dart';
import 'steam_status_repository.dart';
import 'steam_status_service.dart';

class SteamStatusTool extends ConsumerStatefulWidget {
  const SteamStatusTool({super.key});

  @override
  ConsumerState<SteamStatusTool> createState() => _SteamStatusToolState();
}

class _SteamStatusToolState extends ConsumerState<SteamStatusTool> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _guardCodeController = TextEditingController();
  final _statusController = TextEditingController();
  final _appIdController = TextEditingController(text: '480');
  final _richTextController = TextEditingController();
  final _richPresenceStatusController = TextEditingController();

  bool _useAppId = true;
  bool _noisyMode = false;
  bool _useRichPresence = false;
  bool _loadingRpTokens = false;
  bool _testingCmServers = false;
  bool _resolvingDomains = false;
  List<SteamRichPresenceToken> _rpTokens = const <SteamRichPresenceToken>[];
  SteamRichPresenceToken? _selectedToken;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _guardCodeController.dispose();
    _statusController.dispose();
    _appIdController.dispose();
    _richTextController.dispose();
    _richPresenceStatusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(steamToolStateProvider);
    final presetsAsync = ref.watch(steamStatusPresetsProvider);
    final historyAsync = ref.watch(steamStatusHistoryProvider);
    final controller = ref.watch(steamStatusControllerProvider);
    final state = stateAsync.asData?.value ?? SteamToolState.initial;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BackendBanner(
          state: state,
          onRestart: () async {
            await _showResult(await controller.restartBackend());
          },
        ),
        if (state.backendError != null) const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 1040) {
              return Column(
                children: [
                  _buildPrimaryColumn(context, state, controller),
                  const SizedBox(height: 16),
                  _buildSecondaryColumn(
                    context,
                    state,
                    controller,
                    presetsAsync.asData?.value ??
                        const <SteamStatusPresetRecord>[],
                    historyAsync.asData?.value ??
                        const <SteamStatusHistoryRecord>[],
                  ),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 7,
                  child: _buildPrimaryColumn(context, state, controller),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 5,
                  child: _buildSecondaryColumn(
                    context,
                    state,
                    controller,
                    presetsAsync.asData?.value ??
                        const <SteamStatusPresetRecord>[],
                    historyAsync.asData?.value ??
                        const <SteamStatusHistoryRecord>[],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildPrimaryColumn(
    BuildContext context,
    SteamToolState state,
    SteamStatusController controller,
  ) {
    return Column(
      children: [
        _ConnectionPanel(
          state: state,
          usernameController: _usernameController,
          passwordController: _passwordController,
          onLogin: () async {
            await _showResult(
              await controller.loginWithPassword(
                _usernameController.text,
                _passwordController.text,
              ),
            );
          },
          onSavedAccountLogin: (username) async {
            await _showResult(await controller.loginWithSavedAccount(username));
          },
          onSavedAccountDelete: (username) async {
            await _showResult(await controller.deleteSavedAccount(username));
          },
          onLogout: () async {
            await _showResult(await controller.logout());
          },
          onSaveCredentials: () async {
            await _showResult(await controller.saveCurrentCredentials());
          },
        ),
        const SizedBox(height: 16),
        _ServerPreferencePanel(
          preference: state.cmPreference,
          domainPreferences: state.domainPreferences,
          backendReady: state.backendReady,
          testing: _testingCmServers,
          resolvingDomains: _resolvingDomains,
          onToggleAuto: (enabled) async {
            await _showResult(await controller.setCMAutoPreference(enabled));
          },
          onTest: state.backendReady && !_testingCmServers
              ? () async {
                  setState(() => _testingCmServers = true);
                  try {
                    await _showResult(await controller.testCMServers());
                  } finally {
                    if (mounted) {
                      setState(() => _testingCmServers = false);
                    }
                  }
                }
              : null,
          onResolveDomains: state.backendReady && !_resolvingDomains
              ? () async {
                  setState(() => _resolvingDomains = true);
                  try {
                    await _showResult(await controller.resolveSteamDomains());
                  } finally {
                    if (mounted) {
                      setState(() => _resolvingDomains = false);
                    }
                  }
                }
              : null,
          onToggleDomain: (domain, enabled) async {
            await _showResult(
              await controller.setSteamDomainEnabled(domain, enabled),
            );
          },
          onToggleDomainIp: (domain, ip, selected) async {
            await _showResult(
              await controller.setSteamDomainIpSelected(
                domain: domain,
                ip: ip,
                selected: selected,
              ),
            );
          },
        ),
        if (state.authPrompt != null || state.waitingForMobileApproval) ...[
          const SizedBox(height: 16),
          _AuthPanel(
            prompt: state.authPrompt,
            waitingForMobileApproval: state.waitingForMobileApproval,
            guardCodeController: _guardCodeController,
            onSubmit: () async {
              await _showResult(
                await controller.submitGuardCode(_guardCodeController.text),
              );
              if (mounted) {
                _guardCodeController.clear();
              }
            },
          ),
        ],
        if (state.remoteState.loggedIn) ...[
          const SizedBox(height: 16),
          _PersonaPanel(
            currentValue: state.remoteState.personaState,
            onSelect: (value) async {
              await _showResult(await controller.setPersonaState(value));
            },
          ),
          const SizedBox(height: 16),
          _PersonaFlagsPanel(
            currentFlags: state.remoteState.personaStateFlags,
            onChanged: (flags) async {
              await _showResult(await controller.setPersonaStateFlags(flags));
            },
          ),
          const SizedBox(height: 16),
          _StatusEditorPanel(
            state: state,
            statusController: _statusController,
            appIdController: _appIdController,
            richTextController: _richTextController,
            richPresenceStatusController: _richPresenceStatusController,
            useAppId: _useAppId,
            noisyMode: _noisyMode,
            useRichPresence: _useRichPresence,
            rpTokens: _rpTokens,
            selectedToken: _selectedToken,
            loadingRpTokens: _loadingRpTokens,
            onToggleUseAppId: (value) => setState(() => _useAppId = value),
            onToggleNoisyMode: (value) => setState(() => _noisyMode = value),
            onToggleUseRichPresence: (value) => setState(() {
              _useRichPresence = value;
              if (!value) {
                _rpTokens = const <SteamRichPresenceToken>[];
                _selectedToken = null;
                _richTextController.clear();
                _richPresenceStatusController.clear();
              }
            }),
            onSelectAppIdPreset: (value) {
              _appIdController.text = '$value';
              setState(() => _useAppId = true);
            },
            onFetchRpTokens: _loadingRpTokens
                ? null
                : () async {
                    final appId = int.tryParse(_appIdController.text.trim());
                    if (appId == null || appId <= 0) {
                      _showSnack('请先填写有效的 AppID', error: true);
                      return;
                    }
                    setState(() => _loadingRpTokens = true);
                    try {
                      final tokens = await controller.fetchRichPresenceTokens(
                        appId,
                      );
                      if (!mounted) {
                        return;
                      }
                      setState(() {
                        _rpTokens = tokens;
                        _selectedToken = null;
                      });
                      _showSnack(
                        tokens.isEmpty
                            ? '该 AppID 没有可用的 Rich Presence Token'
                            : '已获取 ${tokens.length} 个 Token',
                      );
                    } catch (error) {
                      _showSnack('$error', error: true);
                    } finally {
                      if (mounted) {
                        setState(() => _loadingRpTokens = false);
                      }
                    }
                  },
            onSelectToken: (token) {
              setState(() => _selectedToken = token);
              _richTextController.text = token?.token ?? '';
            },
            onSubmit: () async {
              final selectedToken = _selectedToken;
              final richText = _richTextController.text.trim();
              final richPresenceStatus = _richPresenceStatusController.text
                  .trim();
              final placeholderValue = richPresenceStatus.isEmpty
                  ? _statusController.text.trim()
                  : richPresenceStatus;
              final richPresenceValues =
                  selectedToken == null ||
                      !_useRichPresence ||
                      selectedToken.token != richText
                  ? null
                  : {
                      for (final key in selectedToken.placeholders)
                        key: placeholderValue,
                    };
              await _showResult(
                await controller.setStatus(
                  text: _statusController.text,
                  appId: _useAppId
                      ? int.tryParse(_appIdController.text.trim())
                      : null,
                  noisy: _noisyMode,
                  richText: _useRichPresence ? richText : null,
                  richPresenceStatus: _useRichPresence
                      ? richPresenceStatus
                      : null,
                  richPresenceValues: richPresenceValues,
                ),
              );
            },
            onClearStatus: state.remoteState.currentStatus == null
                ? null
                : () async {
                    await _showResult(await controller.clearStatus());
                  },
          ),
        ],
      ],
    );
  }

  Widget _buildSecondaryColumn(
    BuildContext context,
    SteamToolState state,
    SteamStatusController controller,
    List<SteamStatusPresetRecord> presets,
    List<SteamStatusHistoryRecord> history,
  ) {
    return Column(
      children: [
        _PresetsPanel(
          presets: presets,
          onApply: _applyDraft,
          onSaveCurrent: () async {
            final text = _statusController.text.trim();
            if (text.isEmpty) {
              _showSnack('请先输入状态文字', error: true);
              return;
            }
            await ref
                .read(steamStatusRepositoryProvider)
                .savePreset(
                  text: text,
                  appId: _useAppId
                      ? int.tryParse(_appIdController.text.trim())
                      : null,
                  richText: _useRichPresence ? _richTextController.text : null,
                );
            _showSnack('当前状态已保存为预设');
          },
          onDelete: (preset) async {
            await ref
                .read(steamStatusRepositoryProvider)
                .deletePreset(preset.id);
          },
          onClear: () async {
            await ref.read(steamStatusRepositoryProvider).clearPresets();
          },
        ),
        const SizedBox(height: 16),
        _HistoryPanel(history: history, onApply: _applyDraft),
        if (state.remoteState.loggedIn) ...[
          const SizedBox(height: 16),
          _TipsPanel(currentState: state.remoteState),
        ],
      ],
    );
  }

  void _applyDraft({required String text, int? appId, String? richText}) {
    setState(() {
      _statusController.text = text;
      _useAppId = appId != null;
      _appIdController.text = appId?.toString() ?? _appIdController.text;
      _useRichPresence = richText != null;
      _richTextController.text = richText ?? '';
      _richPresenceStatusController.clear();
      _selectedToken = null;
    });
  }

  Future<void> _showResult(SteamActionResult result) async {
    _showSnack(result.message, error: !result.success);
  }

  void _showSnack(String message, {bool error = false}) {
    if (!mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    messenger.showLatestSnackMessage(
      message,
      backgroundColor: error ? AppColors.bad : null,
    );
  }
}

class _BackendBanner extends StatelessWidget {
  const _BackendBanner({required this.state, required this.onRestart});

  final SteamToolState state;
  final Future<void> Function() onRestart;

  @override
  Widget build(BuildContext context) {
    if (state.backendError != null) {
      final title = state.backendPhase == SteamBackendPhase.error
          ? 'Steam 侧车服务异常'
          : 'Steam 操作失败';
      return _StatusBanner(
        color: AppColors.bad,
        icon: Icons.error_outline,
        title: title,
        message: state.backendError!,
        action: OutlinedButton.icon(
          onPressed: onRestart,
          icon: const Icon(Icons.restart_alt_outlined),
          label: const Text('重启侧车'),
        ),
      );
    }

    final (
      Color color,
      IconData icon,
      String title,
      String message,
    ) = switch (state.backendPhase) {
      SteamBackendPhase.starting => (
        AppColors.accent,
        Icons.sync_outlined,
        '正在启动 Steam 侧车服务',
        state.backendMessage ?? '首次进入时会把后端脚本释放到本机支持目录，并准备 Python 环境。',
      ),
      SteamBackendPhase.ready => (
        AppColors.good,
        Icons.check_circle_outline,
        'Steam 侧车服务已就绪',
        '当前通过本地 HTTP API 与 Python 后端协作，账号凭证仅保存在本机，不进入同步快照。',
      ),
      SteamBackendPhase.error => (
        AppColors.bad,
        Icons.error_outline,
        'Steam 侧车服务启动失败',
        state.backendError ?? '请确认本机已安装 Python 3，并已安装 statushack 所需依赖。',
      ),
      SteamBackendPhase.stopped => (
        AppColors.muted,
        Icons.pause_circle_outline,
        'Steam 侧车服务已停止',
        '重新进入此工具页会再次尝试启动。',
      ),
    };

    return _StatusBanner(
      color: color,
      icon: icon,
      title: title,
      message: message,
      action: state.backendPhase == SteamBackendPhase.stopped
          ? OutlinedButton.icon(
              onPressed: onRestart,
              icon: const Icon(Icons.play_arrow_outlined),
              label: const Text('启动侧车'),
            )
          : null,
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.color,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.22)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(message, style: const TextStyle(color: AppColors.muted)),
                if (action != null) ...[
                  const SizedBox(height: 12),
                  Align(alignment: Alignment.centerLeft, child: action),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionPanel extends StatelessWidget {
  const _ConnectionPanel({
    required this.state,
    required this.usernameController,
    required this.passwordController,
    required this.onLogin,
    required this.onSavedAccountLogin,
    required this.onSavedAccountDelete,
    required this.onLogout,
    required this.onSaveCredentials,
  });

  final SteamToolState state;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final Future<void> Function() onLogin;
  final Future<void> Function(String username) onSavedAccountLogin;
  final Future<void> Function(String username) onSavedAccountDelete;
  final Future<void> Function() onLogout;
  final Future<void> Function() onSaveCredentials;

  @override
  Widget build(BuildContext context) {
    final remote = state.remoteState;
    final loginBusy = state.loginInProgress;
    return AppPanel(
      title: '连接与账号',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: remote.loggedIn ? AppColors.good : AppColors.muted,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  loginBusy
                      ? state.loginMessage ?? '正在登录 Steam...'
                      : remote.loggedIn
                      ? '当前已连接账号：${remote.username ?? '未知账号'}'
                      : '当前未登录 Steam',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (remote.loggedIn)
                OutlinedButton.icon(
                  onPressed: loginBusy ? null : onLogout,
                  icon: const Icon(Icons.logout_outlined),
                  label: const Text('切换账号'),
                ),
            ],
          ),
          if (loginBusy) ...[
            const SizedBox(height: 14),
            const LinearProgressIndicator(minHeight: 3),
            const SizedBox(height: 8),
            Text(
              state.loginMessage ?? '正在登录 Steam...',
              style: const TextStyle(color: AppColors.muted),
            ),
          ],
          if (state.shouldPromptSaveCredentials && remote.loggedIn) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bg,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('当前登录凭证尚未保存。保存后，下次可以免密码直接登录这个账号。'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: loginBusy ? null : onSaveCredentials,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('保存凭证'),
                  ),
                ],
              ),
            ),
          ],
          if (state.savedAccounts.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text('已保存账号', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final account in state.savedAccounts)
                  _SavedAccountChip(
                    username: account.username,
                    enabled: !loginBusy,
                    onLogin: () => onSavedAccountLogin(account.username),
                    onDelete: () => onSavedAccountDelete(account.username),
                  ),
              ],
            ),
          ],
          if (!remote.loggedIn) ...[
            const SizedBox(height: 18),
            TextField(
              controller: usernameController,
              enabled: !loginBusy,
              decoration: const InputDecoration(labelText: 'Steam 用户名'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              enabled: !loginBusy,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Steam 密码'),
              onSubmitted: (_) {
                if (!loginBusy && state.backendReady) {
                  onLogin();
                }
              },
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: state.backendReady && !loginBusy ? onLogin : null,
              icon: loginBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.login_outlined),
              label: Text(loginBusy ? '正在登录...' : '登录'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ServerPreferencePanel extends StatelessWidget {
  const _ServerPreferencePanel({
    required this.preference,
    required this.domainPreferences,
    required this.backendReady,
    required this.testing,
    required this.resolvingDomains,
    required this.onToggleAuto,
    required this.onTest,
    required this.onResolveDomains,
    required this.onToggleDomain,
    required this.onToggleDomainIp,
  });

  final SteamCMPreference preference;
  final List<SteamDomainPreference> domainPreferences;
  final bool backendReady;
  final bool testing;
  final bool resolvingDomains;
  final ValueChanged<bool> onToggleAuto;
  final Future<void> Function()? onTest;
  final Future<void> Function()? onResolveDomains;
  final Future<void> Function(String domain, bool enabled) onToggleDomain;
  final Future<void> Function(String domain, String ip, bool selected)
  onToggleDomainIp;

  @override
  Widget build(BuildContext context) {
    final best = preference.bestServer;
    final testedCount = preference.servers.length;
    final successCount = preference.servers
        .where((item) => item.success)
        .length;
    final checkedAt = preference.lastCheckedAt == null
        ? '尚未测速'
        : DateFormat('MM-dd HH:mm:ss').format(preference.lastCheckedAt!);
    return AppPanel(
      title: 'Steam 服务器优选',
      trailing: Switch(
        value: preference.enabled,
        onChanged: backendReady ? onToggleAuto : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            preference.enabled ? '登录前自动选择低延迟 CM 节点' : '已关闭自动优选，使用 Steam 默认节点选择',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            '优选只影响 Steam CM 连接；账号登录 WebAPI 仍使用 api.steampowered.com。',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bg,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MetricLine(label: '最近测速', value: checkedAt),
                const SizedBox(height: 6),
                _MetricLine(
                  label: '可用节点',
                  value: '$successCount / $testedCount',
                ),
                const SizedBox(height: 6),
                _MetricLine(
                  label: '当前最优',
                  value: best == null
                      ? '暂无'
                      : '${best.endpoint} · ${best.latencyMs?.toStringAsFixed(1)} ms',
                ),
                if (preference.lastError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    preference.lastError!,
                    style: const TextStyle(color: AppColors.bad),
                  ),
                ],
              ],
            ),
          ),
          if (preference.servers.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final server in preference.servers.take(5))
                  _CMServerChip(server: server),
              ],
            ),
          ],
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onTest,
            icon: testing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.speed_outlined),
            label: Text(testing ? '测速中...' : '立即测速并应用'),
          ),
          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 18),
          Text('全流程域名优选', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          const Text(
            '选择某个域名解析出的 IP 后，后端会在 DNS 解析阶段优先使用这些 IP；HTTPS 请求仍保留原域名和证书校验。',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onResolveDomains,
            icon: resolvingDomains
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.language_outlined),
            label: Text(resolvingDomains ? '解析中...' : '解析域名 IP 与属地'),
          ),
          if (domainPreferences.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final domain in domainPreferences) ...[
              _DomainPreferenceCard(
                preference: domain,
                enabled: backendReady,
                onToggleDomain: (value) => onToggleDomain(domain.domain, value),
                onToggleIp: (ip, value) =>
                    onToggleDomainIp(domain.domain, ip, value),
              ),
              if (domain != domainPreferences.last) const SizedBox(height: 10),
            ],
          ],
        ],
      ),
    );
  }
}

class _DomainPreferenceCard extends StatelessWidget {
  const _DomainPreferenceCard({
    required this.preference,
    required this.enabled,
    required this.onToggleDomain,
    required this.onToggleIp,
  });

  final SteamDomainPreference preference;
  final bool enabled;
  final ValueChanged<bool> onToggleDomain;
  final void Function(String ip, bool selected) onToggleIp;

  @override
  Widget build(BuildContext context) {
    final checkedAt = preference.lastResolvedAt == null
        ? '尚未解析'
        : DateFormat('MM-dd HH:mm:ss').format(preference.lastResolvedAt!);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('${preference.label} · ${preference.domain}'),
            subtitle: Text(
              '${preference.description}\n$checkedAt · 已选 ${preference.selectedIps.length} 个 IP',
            ),
            value: preference.enabled,
            onChanged: enabled ? onToggleDomain : null,
          ),
          if (preference.lastError != null)
            Text(
              preference.lastError!,
              style: const TextStyle(color: AppColors.bad),
            ),
          if (preference.ips.isEmpty)
            const Text(
              '解析后可在这里选择优先使用的 IP。',
              style: TextStyle(color: AppColors.muted),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final ip in preference.ips)
                  FilterChip(
                    selected: ip.selected,
                    onSelected: enabled && preference.enabled
                        ? (value) => onToggleIp(ip.address, value)
                        : null,
                    label: Text(_domainIpLabel(ip)),
                    avatar: Icon(
                      ip.success ? Icons.public_outlined : Icons.error_outline,
                      size: 16,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _MetricLine extends StatelessWidget {
  const _MetricLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 74,
          child: Text(label, style: const TextStyle(color: AppColors.muted)),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }
}

class _CMServerChip extends StatelessWidget {
  const _CMServerChip({required this.server});

  final SteamCMServer server;

  @override
  Widget build(BuildContext context) {
    final color = server.success ? AppColors.good : AppColors.bad;
    final label = server.success
        ? '${server.endpoint} · ${server.latencyMs?.toStringAsFixed(1)} ms'
        : '${server.endpoint} · 失败';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.24)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: TextStyle(color: color)),
    );
  }
}

class _SavedAccountChip extends StatelessWidget {
  const _SavedAccountChip({
    required this.username,
    required this.enabled,
    required this.onLogin,
    required this.onDelete,
  });

  final String username;
  final bool enabled;
  final VoidCallback onLogin;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(username),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            onPressed: enabled ? onLogin : null,
            icon: const Icon(Icons.key_outlined, size: 16),
            label: const Text('免密登录'),
          ),
          const SizedBox(width: 6),
          IconButton(
            tooltip: '删除凭证',
            onPressed: enabled ? onDelete : null,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}

class _AuthPanel extends StatelessWidget {
  const _AuthPanel({
    required this.prompt,
    required this.waitingForMobileApproval,
    required this.guardCodeController,
    required this.onSubmit,
  });

  final SteamAuthPrompt? prompt;
  final bool waitingForMobileApproval;
  final TextEditingController guardCodeController;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    if (waitingForMobileApproval) {
      return const AppPanel(
        title: '手机批准',
        child: Text(
          'Steam 已要求你在手机 App 中确认本次登录。保持此页面打开，确认后状态会自动刷新。',
          style: TextStyle(color: AppColors.muted),
        ),
      );
    }
    if (prompt == null) {
      return const SizedBox.shrink();
    }
    return AppPanel(
      title: prompt!.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            prompt!.subtitle,
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: guardCodeController,
                  decoration: const InputDecoration(labelText: '验证码'),
                  onSubmitted: (_) => onSubmit(),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: onSubmit,
                icon: const Icon(Icons.verified_outlined),
                label: const Text('提交'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PersonaPanel extends StatelessWidget {
  const _PersonaPanel({required this.currentValue, required this.onSelect});

  final int currentValue;
  final Future<void> Function(int value) onSelect;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: '副状态',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final option in steamPersonaOptions)
            ChoiceChip(
              label: Text(option.label),
              selected: option.value == currentValue,
              onSelected: (_) => onSelect(option.value),
            ),
        ],
      ),
    );
  }
}

class _PersonaFlagsPanel extends StatelessWidget {
  const _PersonaFlagsPanel({
    required this.currentFlags,
    required this.onChanged,
  });

  final int currentFlags;
  final Future<void> Function(int flags) onChanged;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: '特殊标记',
      trailing: currentFlags == 0
          ? null
          : TextButton(onPressed: () => onChanged(0), child: const Text('清空')),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '这些是 Steam Persona State Flags，可模拟 Web、Mobile、Big Picture、VR 等名称旁标记；实际好友端显示仍受 Steam 客户端版本和风控影响。',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 14),
          _PersonaFlagGroup(
            title: '和 VR 同类的客户端类型',
            options: steamPersonaClientTypeFlagOptions,
            currentFlags: currentFlags,
            onChanged: onChanged,
          ),
          const SizedBox(height: 14),
          _PersonaFlagGroup(
            title: '其它同组 EPersonaStateFlag',
            options: steamPersonaOtherFlagOptions,
            currentFlags: currentFlags,
            onChanged: onChanged,
          ),
          const SizedBox(height: 10),
          Text(
            '当前 flags：$currentFlags',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _PersonaFlagGroup extends StatelessWidget {
  const _PersonaFlagGroup({
    required this.title,
    required this.options,
    required this.currentFlags,
    required this.onChanged,
  });

  final String title;
  final List<SteamPersonaFlagOption> options;
  final int currentFlags;
  final Future<void> Function(int flags) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final option in options)
              FilterChip(
                label: Text(option.label),
                avatar: Text('${option.value}'),
                tooltip: option.description,
                selected: (currentFlags & option.value) != 0,
                onSelected: (selected) {
                  final nextFlags = selected
                      ? currentFlags | option.value
                      : currentFlags & ~option.value;
                  onChanged(nextFlags);
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _StatusEditorPanel extends StatelessWidget {
  const _StatusEditorPanel({
    required this.state,
    required this.statusController,
    required this.appIdController,
    required this.richTextController,
    required this.richPresenceStatusController,
    required this.useAppId,
    required this.noisyMode,
    required this.useRichPresence,
    required this.rpTokens,
    required this.selectedToken,
    required this.loadingRpTokens,
    required this.onToggleUseAppId,
    required this.onToggleNoisyMode,
    required this.onToggleUseRichPresence,
    required this.onSelectAppIdPreset,
    required this.onFetchRpTokens,
    required this.onSelectToken,
    required this.onSubmit,
    required this.onClearStatus,
  });

  final SteamToolState state;
  final TextEditingController statusController;
  final TextEditingController appIdController;
  final TextEditingController richTextController;
  final TextEditingController richPresenceStatusController;
  final bool useAppId;
  final bool noisyMode;
  final bool useRichPresence;
  final List<SteamRichPresenceToken> rpTokens;
  final SteamRichPresenceToken? selectedToken;
  final bool loadingRpTokens;
  final ValueChanged<bool> onToggleUseAppId;
  final ValueChanged<bool> onToggleNoisyMode;
  final ValueChanged<bool> onToggleUseRichPresence;
  final ValueChanged<int> onSelectAppIdPreset;
  final Future<void> Function()? onFetchRpTokens;
  final ValueChanged<SteamRichPresenceToken?> onSelectToken;
  final Future<void> Function() onSubmit;
  final Future<void> Function()? onClearStatus;

  @override
  Widget build(BuildContext context) {
    final remote = state.remoteState;
    final charCount = statusController.text.characters.length;
    return AppPanel(
      title: '自定义状态',
      trailing: remote.currentStatus == null
          ? null
          : OutlinedButton.icon(
              onPressed: onClearStatus,
              icon: const Icon(Icons.clear_outlined),
              label: const Text('清除'),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (remote.currentStatus != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bg,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '当前状态：${remote.currentStatus}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  if (remote.currentAppId != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '关联 AppID：${remote.currentAppId}',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ),
                  if (remote.currentRichText != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Rich Presence：${remote.currentRichText}',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ),
                  if (remote.currentRichPresenceStatus != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '富文本内容：${remote.currentRichPresenceStatus}',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: statusController,
            maxLength: 64,
            decoration: InputDecoration(
              labelText: '上方显示名称',
              helperText: '长度 $charCount / 64',
            ),
            onSubmitted: (_) => onSubmit(),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('关联真实游戏 AppID'),
            subtitle: const Text('显示游戏图标，并为 Rich Presence 提供更高兼容性'),
            value: useAppId,
            onChanged: onToggleUseAppId,
          ),
          if (useAppId) ...[
            TextField(
              controller: appIdController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'AppID'),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final preset in const [
                  ('CS2', 730),
                  ('Dota2', 570),
                  ('TF2', 440),
                  ('Rust', 252490),
                  ('Apex', 1172470),
                ])
                  OutlinedButton(
                    onPressed: () => onSelectAppIdPreset(preset.$2),
                    child: Text(preset.$1),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('吵闹模式'),
            subtitle: const Text('重新上线并强制推动好友侧刷新，可能更显眼'),
            value: noisyMode,
            onChanged: onToggleNoisyMode,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Rich Presence 富文本子状态'),
            subtitle: const Text('实验性功能，需填写以 # 开头的 Token Key'),
            value: useRichPresence,
            onChanged: onToggleUseRichPresence,
          ),
          if (useRichPresence) ...[
            TextField(
              controller: richTextController,
              decoration: const InputDecoration(
                labelText: 'Rich Presence Token Key',
                hintText: '例如 #display_Lobby',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: richPresenceStatusController,
              maxLength: 128,
              decoration: const InputDecoration(
                labelText: '富文本状态内容',
                helperText: '留空时使用上方显示名称',
              ),
              onSubmitted: (_) => onSubmit(),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: onFetchRpTokens,
                  icon: loadingRpTokens
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.travel_explore_outlined),
                  label: Text(loadingRpTokens ? '获取中...' : '从 AppID 获取 Tokens'),
                ),
                const Text(
                  'Token 所需占位符会用富文本状态内容填充。',
                  style: TextStyle(color: AppColors.muted),
                ),
              ],
            ),
            if (rpTokens.isNotEmpty) ...[
              const SizedBox(height: 10),
              DropdownButtonFormField<SteamRichPresenceToken>(
                initialValue: selectedToken,
                decoration: const InputDecoration(labelText: '选择一个 Token'),
                items: [
                  for (final token in rpTokens)
                    DropdownMenuItem(
                      value: token,
                      child: Text(
                        token.placeholders.isEmpty
                            ? '${token.token} -> ${token.display}'
                            : '${token.token} -> ${token.display} '
                                  '(${token.placeholders.join(', ')})',
                      ),
                    ),
                ],
                onChanged: onSelectToken,
              ),
            ],
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onSubmit,
            icon: const Icon(Icons.send_outlined),
            label: const Text('设置状态'),
          ),
        ],
      ),
    );
  }
}

class _PresetsPanel extends StatelessWidget {
  const _PresetsPanel({
    required this.presets,
    required this.onApply,
    required this.onSaveCurrent,
    required this.onDelete,
    required this.onClear,
  });

  final List<SteamStatusPresetRecord> presets;
  final void Function({required String text, int? appId, String? richText})
  onApply;
  final Future<void> Function() onSaveCurrent;
  final Future<void> Function(SteamStatusPresetRecord preset) onDelete;
  final Future<void> Function() onClear;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: '快速预设',
      trailing: Wrap(
        spacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: onSaveCurrent,
            icon: const Icon(Icons.bookmark_add_outlined),
            label: const Text('保存当前'),
          ),
          OutlinedButton.icon(
            onPressed: presets.isEmpty ? null : onClear,
            icon: const Icon(Icons.delete_sweep_outlined),
            label: const Text('清空'),
          ),
        ],
      ),
      child: presets.isEmpty
          ? const EmptyState(
              icon: Icons.star_outline,
              title: '还没有预设',
              message: '把常用状态保存下来，下次可以一键回填。',
            )
          : Column(
              children: [
                for (final preset in presets) ...[
                  _DraftRow(
                    title: preset.steamStatusDisplayText,
                    subtitle: _draftSubtitle(
                      appId: preset.relatedSteamAppId,
                      richText: preset.richPresenceTokenText,
                    ),
                    onApply: () => onApply(
                      text: preset.steamStatusDisplayText,
                      appId: preset.relatedSteamAppId,
                      richText: preset.richPresenceTokenText,
                    ),
                    onDelete: () => onDelete(preset),
                  ),
                  if (preset != presets.last) const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }
}

class _HistoryPanel extends StatelessWidget {
  const _HistoryPanel({required this.history, required this.onApply});

  final List<SteamStatusHistoryRecord> history;
  final void Function({required String text, int? appId, String? richText})
  onApply;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: '历史记录',
      child: history.isEmpty
          ? const EmptyState(
              icon: Icons.history_outlined,
              title: '暂无历史记录',
              message: '成功设置过的状态会自动进入这里，支持一键回填。',
            )
          : Column(
              children: [
                for (final item in history) ...[
                  _DraftRow(
                    title: item.steamStatusDisplayText,
                    subtitle:
                        '${_draftSubtitle(appId: item.relatedSteamAppId, richText: item.richPresenceTokenText)} · ${DateFormat('MM-dd HH:mm').format(item.updatedAt.toLocal())}',
                    onApply: () => onApply(
                      text: item.steamStatusDisplayText,
                      appId: item.relatedSteamAppId,
                      richText: item.richPresenceTokenText,
                    ),
                  ),
                  if (item != history.last) const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }
}

class _TipsPanel extends StatelessWidget {
  const _TipsPanel({required this.currentState});

  final SteamRemoteState currentState;

  @override
  Widget build(BuildContext context) {
    return const AppPanel(
      title: '说明',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('1. 账号凭证只保存在本机侧车目录，不进入 WebDAV 同步快照。'),
          SizedBox(height: 8),
          Text('2. 预设和历史记录会跟随应用数据库一起参与同步。'),
          SizedBox(height: 8),
          Text('3. Rich Presence 依赖目标游戏自己的配置，建议与真实 AppID 一起使用。'),
          SizedBox(height: 8),
          Text('4. 如果侧车启动失败，优先确认本机 Python 3 与 statushack 依赖是否已安装。'),
        ],
      ),
    );
  }
}

class _DraftRow extends StatelessWidget {
  const _DraftRow({
    required this.title,
    required this.subtitle,
    required this.onApply,
    this.onDelete,
  });

  final String title;
  final String subtitle;
  final VoidCallback onApply;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: AppColors.muted)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: onApply,
            icon: const Icon(Icons.replay_outlined),
            label: const Text('回填'),
          ),
          if (onDelete != null) ...[
            const SizedBox(width: 6),
            IconButton(
              tooltip: '删除',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ],
      ),
    );
  }
}

String _draftSubtitle({int? appId, String? richText}) {
  final parts = <String>[];
  parts.add(appId == null ? '无 AppID' : 'AppID $appId');
  if (richText != null && richText.isNotEmpty) {
    parts.add('RP $richText');
  }
  return parts.join(' · ');
}

String _domainIpLabel(SteamDomainIp ip) {
  final parts = <String>[ip.address];
  if (ip.latencyMs != null) {
    parts.add('${ip.latencyMs!.toStringAsFixed(1)} ms');
  } else if (!ip.success) {
    parts.add('连接失败');
  }
  if (ip.location != null && ip.location!.isNotEmpty) {
    parts.add(ip.location!);
  }
  return parts.join(' · ');
}
