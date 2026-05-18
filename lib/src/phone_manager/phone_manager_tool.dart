import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../ui/app_panel.dart';
import '../ui/latest_snack_bar.dart';
import 'phone_manager_service.dart';

class PhoneManagerTool extends StatefulWidget {
  const PhoneManagerTool({super.key, PhoneManagerService? service})
    : _service = service;

  final PhoneManagerService? _service;

  @override
  State<PhoneManagerTool> createState() => _PhoneManagerToolState();
}

class _PhoneManagerToolState extends State<PhoneManagerTool> {
  late final PhoneManagerService _service;
  PhoneManagerSupport? _support;
  List<PhoneDevice> _devices = const [];
  List<PhoneContact> _contacts = const [];
  List<PhoneMessage> _messages = const [];
  List<PhoneCallLog> _callLogs = const [];
  List<PhoneFileItem> _files = const [];
  List<PhoneDiagnostic> _diagnostics = const [];
  PhoneMediaSession? _media;
  PhoneVolumeState? _volume;
  String? _selectedDeviceId;
  _PhoneManagerSection _section = _PhoneManagerSection.devices;
  Timer? _pollTimer;
  bool _loading = true;
  bool _busy = false;
  String? _lastError;

  @override
  void initState() {
    super.initState();
    _service = widget._service ?? const PhoneManagerService();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialState());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedDevice = _selectedDevice;
    return _PhoneManagerGrid(
      left: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppPanel(
            title: '管理端状态',
            trailing: _SupportPill(support: _support),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _support?.message ?? '正在检测手机管理能力...',
                  style: const TextStyle(color: AppColors.muted),
                ),
                if (_support?.missingPermissions.isNotEmpty ?? false) ...[
                  const SizedBox(height: 12),
                  _InlineNotice(
                    message: '缺少权限：${_support!.missingPermissions.join('、')}',
                    isError: true,
                  ),
                ],
                if (_support?.runtimeWarnings.isNotEmpty ?? false) ...[
                  const SizedBox(height: 12),
                  _InlineNotice(
                    message: '运行提示：${_support!.runtimeWarnings.join('、')}',
                    isWarning: true,
                  ),
                ],
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: _loading || _busy ? null : _refreshAll,
                      icon: _loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      label: Text(_loading ? '刷新中...' : '刷新'),
                    ),
                    if (Platform.isAndroid)
                      OutlinedButton.icon(
                        onPressed: _busy ? null : _requestAndroidPermissions,
                        icon: const Icon(Icons.privacy_tip_outlined),
                        label: const Text('请求权限'),
                      ),
                    if (Platform.isAndroid)
                      OutlinedButton.icon(
                        onPressed: _busy ? null : _startCompanionServer,
                        icon: const Icon(Icons.settings_remote_outlined),
                        label: const Text('启动伴随服务'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (_lastError != null) ...[
            const SizedBox(height: 12),
            _InlineNotice(message: _lastError!, isError: true),
          ],
          const SizedBox(height: 16),
          AppPanel(
            title: '当前设备',
            child: selectedDevice == null
                ? const _InlineNotice(message: '请选择一个可连接手机。')
                : _SelectedDeviceSummary(device: selectedDevice),
          ),
        ],
      ),
      right: AppPanel(
        title: '手机管理',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionSelector(
              current: _section,
              onChanged: (section) {
                setState(() => _section = section);
                _loadSection(section);
              },
            ),
            const SizedBox(height: 16),
            if (_loading)
              const LinearProgressIndicator()
            else
              _buildSection(context, selectedDevice),
          ],
        ),
      ),
    );
  }

  PhoneDevice? get _selectedDevice {
    final selectedId = _selectedDeviceId;
    if (selectedId == null) {
      return _devices.where((device) => device.enabled).firstOrNull;
    }
    for (final device in _devices) {
      if (device.id == selectedId) {
        return device;
      }
    }
    return _devices.where((device) => device.enabled).firstOrNull;
  }

  Future<void> _loadInitialState() async {
    setState(() {
      _loading = true;
      _lastError = null;
    });
    try {
      final support = await _service.checkSupport();
      final devices = await _service.listDevices();
      final diagnostics = await _service.getDiagnostics();
      if (!mounted) {
        return;
      }
      setState(() {
        _support = support;
        _devices = devices;
        _selectedDeviceId = _selectedDeviceIdFor(devices);
        _diagnostics = diagnostics;
      });
      await _refreshMediaAndVolume();
      _syncPolling();
    } catch (error) {
      if (mounted) {
        setState(() => _lastError = '初始化手机管理失败：$error');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _refreshAll() async {
    await _loadInitialState();
    await _loadSection(_section);
  }

  Future<void> _loadSection(_PhoneManagerSection section) async {
    try {
      switch (section) {
        case _PhoneManagerSection.contacts:
          final contacts = await _service.listContacts();
          if (mounted) setState(() => _contacts = contacts);
        case _PhoneManagerSection.messages:
          final messages = await _service.listMessages();
          if (mounted) setState(() => _messages = messages);
        case _PhoneManagerSection.calls:
          final callLogs = await _service.listCallLogs();
          if (mounted) setState(() => _callLogs = callLogs);
        case _PhoneManagerSection.files:
          final files = await _service.listFiles();
          if (mounted) setState(() => _files = files);
        case _PhoneManagerSection.diagnostics:
          final diagnostics = await _service.getDiagnostics();
          if (mounted) setState(() => _diagnostics = diagnostics);
        case _PhoneManagerSection.media:
        case _PhoneManagerSection.audio:
        case _PhoneManagerSection.volume:
          await _refreshMediaAndVolume();
        case _PhoneManagerSection.devices:
        case _PhoneManagerSection.network:
        case _PhoneManagerSection.input:
          break;
      }
    } catch (error) {
      if (mounted) {
        setState(() => _lastError = '刷新${section.label}失败：$error');
      }
    }
  }

  Future<void> _refreshMediaAndVolume() async {
    final media = await _service.getMediaSession();
    final volume = await _service.getVolumeState();
    if (!mounted) {
      return;
    }
    setState(() {
      _media = media;
      _volume = volume;
    });
  }

  String? _selectedDeviceIdFor(List<PhoneDevice> devices) {
    final selected = _selectedDeviceId;
    if (selected != null && devices.any((device) => device.id == selected)) {
      return selected;
    }
    return devices.where((device) => device.enabled).firstOrNull?.id ??
        devices.firstOrNull?.id;
  }

  Future<void> _runDeviceAction(
    Future<PhoneCapabilityResult> Function(String id) action,
  ) async {
    final device = _selectedDevice;
    if (device == null) {
      return;
    }
    setState(() {
      _busy = true;
      _lastError = null;
    });
    try {
      final result = await action(device.id);
      final devices = await _service.listDevices();
      if (!mounted) {
        return;
      }
      setState(() {
        _devices = devices;
        _selectedDeviceId = _selectedDeviceIdFor(devices);
      });
      ScaffoldMessenger.of(context).showLatestSnackMessage(result.message);
      if (!result.available) {
        setState(() => _lastError = result.message);
      }
      await _refreshMediaAndVolume();
      _syncPolling();
    } catch (error) {
      if (mounted) {
        setState(() => _lastError = '设备操作失败：$error');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _requestAndroidPermissions() async {
    await _runSimpleAction(_service.requestCompanionPermissions);
    await _loadInitialState();
  }

  Future<void> _startCompanionServer() async {
    await _runSimpleAction(_service.startCompanionServer);
    await _loadInitialState();
  }

  Future<void> _registerHid() async {
    await _runSimpleAction(_service.registerHid);
    await _loadSection(_PhoneManagerSection.diagnostics);
  }

  Future<void> _selectFiles() async {
    await _runSimpleAction(_service.selectFiles);
    await _loadSection(_PhoneManagerSection.files);
    await _loadSection(_PhoneManagerSection.diagnostics);
  }

  Future<void> _receiveFile(PhoneFileItem file) async {
    setState(() {
      _busy = true;
      _lastError = null;
    });
    try {
      final result = await _service.receiveFile(file);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showLatestSnackMessage(result.message);
      if (!result.available) {
        setState(() => _lastError = result.message);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _lastError = '接收文件失败：$error');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _sendHidKey(String key) async {
    await _runSimpleAction(() => _service.sendHidKey(key));
    await _loadSection(_PhoneManagerSection.diagnostics);
  }

  Future<void> _sendHidMouse({
    int dx = 0,
    int dy = 0,
    int wheel = 0,
    int buttons = 0,
  }) async {
    await _runSimpleAction(
      () =>
          _service.sendHidMouse(dx: dx, dy: dy, wheel: wheel, buttons: buttons),
    );
    await _loadSection(_PhoneManagerSection.diagnostics);
  }

  Future<void> _runSimpleAction(
    Future<PhoneCapabilityResult> Function() action,
  ) async {
    setState(() {
      _busy = true;
      _lastError = null;
    });
    try {
      final result = await action();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showLatestSnackMessage(result.message);
      if (!result.available) {
        setState(() => _lastError = result.message);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _lastError = '操作失败：$error');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _syncPolling() {
    if (_selectedDevice?.audioOpened == true) {
      _pollTimer ??= Timer.periodic(
        const Duration(seconds: 1),
        (_) => _refreshMediaAndVolume(),
      );
    } else {
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  Widget _buildSection(BuildContext context, PhoneDevice? selectedDevice) {
    return switch (_section) {
      _PhoneManagerSection.devices => _DevicesSection(
        devices: _devices,
        selectedDeviceId: _selectedDeviceId,
        busy: _busy,
        onSelect: (device) {
          setState(() {
            _selectedDeviceId = device.id;
            _lastError = null;
          });
          _syncPolling();
        },
      ),
      _PhoneManagerSection.audio => _AudioSection(
        device: selectedDevice,
        busy: _busy,
        onConnect: () => _runDeviceAction(_service.connectDevice),
        onDisconnect: () => _runDeviceAction(_service.disconnectDevice),
        onStart: () => _runDeviceAction(_service.startAudioTransfer),
        onStop: () => _runDeviceAction(_service.stopAudioTransfer),
      ),
      _PhoneManagerSection.media => _MediaSection(
        media: _media,
        busy: _busy,
        onRefresh: _refreshMediaAndVolume,
        onCommand: (command) async {
          final result = await _service.sendMediaCommand(command);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showLatestSnackMessage(result.message);
          await _refreshMediaAndVolume();
        },
      ),
      _PhoneManagerSection.volume => _VolumeSection(
        volume: _volume,
        busy: _busy,
        onChanged: (value) async {
          await _service.setVolume(value);
          await _refreshMediaAndVolume();
        },
        onMutedChanged: (value) async {
          await _service.setMuted(value);
          await _refreshMediaAndVolume();
        },
      ),
      _PhoneManagerSection.contacts => _ContactsSection(
        contacts: _contacts,
        onRefresh: () => _loadSection(_PhoneManagerSection.contacts),
      ),
      _PhoneManagerSection.messages => _MessagesSection(
        messages: _messages,
        onRefresh: () => _loadSection(_PhoneManagerSection.messages),
      ),
      _PhoneManagerSection.calls => _CallsSection(
        callLogs: _callLogs,
        onRefresh: () => _loadSection(_PhoneManagerSection.calls),
      ),
      _PhoneManagerSection.files => _FilesSection(
        files: _files,
        busy: _busy,
        canSelectFiles: Platform.isAndroid,
        canReceiveFiles: Platform.isWindows,
        onSelectFiles: _selectFiles,
        onRefresh: () => _loadSection(_PhoneManagerSection.files),
        onReceiveFile: _receiveFile,
      ),
      _PhoneManagerSection.network => _NetworkSection(
        busy: _busy,
        onOpenPanSettings: () => _runSimpleAction(_service.openPanSettings),
      ),
      _PhoneManagerSection.input => _InputSection(
        busy: _busy,
        isAndroid: Platform.isAndroid,
        onRegisterHid: _registerHid,
        onSendKey: _sendHidKey,
        onSendMouse: _sendHidMouse,
      ),
      _PhoneManagerSection.diagnostics => _DiagnosticsSection(
        diagnostics: _diagnostics,
        onRefresh: () => _loadSection(_PhoneManagerSection.diagnostics),
      ),
    };
  }
}

enum _PhoneManagerSection {
  devices('设备', Icons.smartphone_outlined),
  audio('音频', Icons.bluetooth_audio_outlined),
  media('媒体', Icons.album_outlined),
  volume('音量', Icons.volume_up_outlined),
  contacts('通讯录', Icons.contacts_outlined),
  messages('消息', Icons.sms_outlined),
  calls('通话', Icons.call_outlined),
  files('文件', Icons.folder_outlined),
  network('网络', Icons.lan_outlined),
  input('输入', Icons.keyboard_alt_outlined),
  diagnostics('诊断', Icons.troubleshoot_outlined);

  const _PhoneManagerSection(this.label, this.icon);

  final String label;
  final IconData icon;
}

class _SectionSelector extends StatelessWidget {
  const _SectionSelector({required this.current, required this.onChanged});

  final _PhoneManagerSection current;
  final ValueChanged<_PhoneManagerSection> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final section in _PhoneManagerSection.values)
          ChoiceChip(
            showCheckmark: false,
            selected: section == current,
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  section.icon,
                  size: 18,
                  color: section == current ? AppColors.fg : AppColors.muted,
                ),
                const SizedBox(width: 6),
                Text(section.label),
              ],
            ),
            onSelected: (_) => onChanged(section),
          ),
      ],
    );
  }
}

class _DevicesSection extends StatelessWidget {
  const _DevicesSection({
    required this.devices,
    required this.selectedDeviceId,
    required this.busy,
    required this.onSelect,
  });

  final List<PhoneDevice> devices;
  final String? selectedDeviceId;
  final bool busy;
  final ValueChanged<PhoneDevice> onSelect;

  @override
  Widget build(BuildContext context) {
    if (devices.isEmpty) {
      return const EmptyState(
        icon: Icons.bluetooth_searching_outlined,
        title: '没有发现可管理手机',
        message: '请先在 Windows 与 Android 设备完成蓝牙配对，然后刷新。',
      );
    }
    return Column(
      children: [
        for (final device in devices) ...[
          _PhoneDeviceTile(
            device: device,
            selected: device.id == selectedDeviceId,
            busy: busy,
            onTap: () => onSelect(device),
          ),
          if (device != devices.last) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _PhoneDeviceTile extends StatelessWidget {
  const _PhoneDeviceTile({
    required this.device,
    required this.selected,
    required this.busy,
    required this.onTap,
  });

  final PhoneDevice device;
  final bool selected;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final stateColor = switch (device.state) {
      PhoneConnectionState.audioOpened => AppColors.good,
      PhoneConnectionState.audioEnabled => AppColors.accent,
      PhoneConnectionState.disconnected => AppColors.muted,
      PhoneConnectionState.unknown => AppColors.muted,
    };
    return InkWell(
      onTap: busy ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.08)
              : AppColors.bg,
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.phone_android_outlined, color: stateColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          device.enabled ? '系统设备可连接' : '系统设备不可连接',
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _StatePill(state: device.state),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final capability in device.capabilities)
                    _CapabilityPill(capability: capability),
                ],
              ),
              if (device.lastError != null) ...[
                const SizedBox(height: 10),
                _InlineNotice(message: device.lastError!, isError: true),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedDeviceSummary extends StatelessWidget {
  const _SelectedDeviceSummary({required this.device});

  final PhoneDevice device;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(device.name, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _StatePill(state: device.state),
            _Pill(
              text: device.companionOnline ? '伴随端在线' : '伴随端未连接',
              color: device.companionOnline ? AppColors.good : AppColors.muted,
            ),
          ],
        ),
        if (device.missingPermissions.isNotEmpty) ...[
          const SizedBox(height: 10),
          _InlineNotice(
            message: '缺少权限：${device.missingPermissions.join('、')}',
            isError: true,
          ),
        ],
      ],
    );
  }
}

class _AudioSection extends StatelessWidget {
  const _AudioSection({
    required this.device,
    required this.busy,
    required this.onConnect,
    required this.onDisconnect,
    required this.onStart,
    required this.onStop,
  });

  final PhoneDevice? device;
  final bool busy;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;
  final VoidCallback onStart;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final current = device;
    final canUse = current != null && current.enabled && !busy;
    final opened = current?.audioOpened == true;
    final enabled = current?.audioEnabled == true || opened;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InlineNotice(
          message: current == null
              ? '请选择一个手机。'
              : '连接设备只启用蓝牙音频接收；开始传输音频才会打开 A2DP 音频流。',
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: canUse && !enabled ? onConnect : null,
              icon: _busyIconOr(Icons.link, busy && !enabled),
              label: const Text('连接设备'),
            ),
            OutlinedButton.icon(
              onPressed: canUse && enabled ? onDisconnect : null,
              icon: const Icon(Icons.link_off),
              label: const Text('断开设备'),
            ),
            FilledButton.icon(
              onPressed: canUse && enabled && !opened ? onStart : null,
              icon: _busyIconOr(Icons.play_arrow, busy && enabled && !opened),
              label: const Text('开始传输音频'),
            ),
            OutlinedButton.icon(
              onPressed: canUse && opened ? onStop : null,
              icon: const Icon(Icons.stop),
              label: const Text('关闭传输音频'),
            ),
          ],
        ),
      ],
    );
  }
}

class _MediaSection extends StatelessWidget {
  const _MediaSection({
    required this.media,
    required this.busy,
    required this.onRefresh,
    required this.onCommand,
  });

  final PhoneMediaSession? media;
  final bool busy;
  final VoidCallback onRefresh;
  final ValueChanged<PhoneMediaCommand> onCommand;

  @override
  Widget build(BuildContext context) {
    final session = media;
    if (session == null || !session.available) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InlineNotice(message: session?.message ?? '还没有读取到媒体会话。'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: busy ? null : onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('刷新媒体'),
          ),
        ],
      );
    }
    final image = session.thumbnailBase64 == null
        ? null
        : Image.memory(
            base64Decode(session.thumbnailBase64!),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const Icon(Icons.album_outlined),
          );
    final progress = session.duration.inMilliseconds <= 0
        ? 0.0
        : (session.position.inMilliseconds / session.duration.inMilliseconds)
              .clamp(0, 1)
              .toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: AppColors.bg,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: image ?? const Icon(Icons.album_outlined, size: 36),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.title.isEmpty ? '未知标题' : session.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    session.artist.isEmpty ? '未知作者' : session.artist,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  if (session.album.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      session.album,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LinearProgressIndicator(value: progress, minHeight: 8),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(_formatDuration(session.position)),
            const Spacer(),
            Text(_formatDuration(session.duration)),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            IconButton.filledTonal(
              tooltip: '上一首',
              onPressed: session.canPrevious
                  ? () => onCommand(PhoneMediaCommand.previous)
                  : null,
              icon: const Icon(Icons.skip_previous),
            ),
            IconButton.filled(
              tooltip: session.playbackStatus == 'Playing' ? '暂停' : '播放',
              onPressed: session.playbackStatus == 'Playing'
                  ? (session.canPause
                        ? () => onCommand(PhoneMediaCommand.pause)
                        : null)
                  : (session.canPlay
                        ? () => onCommand(PhoneMediaCommand.play)
                        : null),
              icon: Icon(
                session.playbackStatus == 'Playing'
                    ? Icons.pause
                    : Icons.play_arrow,
              ),
            ),
            IconButton.filledTonal(
              tooltip: '下一首',
              onPressed: session.canNext
                  ? () => onCommand(PhoneMediaCommand.next)
                  : null,
              icon: const Icon(Icons.skip_next),
            ),
            IconButton.outlined(
              tooltip: '停止',
              onPressed: session.canStop
                  ? () => onCommand(PhoneMediaCommand.stop)
                  : null,
              icon: const Icon(Icons.stop),
            ),
            IconButton.outlined(
              tooltip: '刷新媒体',
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ],
    );
  }
}

class _VolumeSection extends StatelessWidget {
  const _VolumeSection({
    required this.volume,
    required this.busy,
    required this.onChanged,
    required this.onMutedChanged,
  });

  final PhoneVolumeState? volume;
  final bool busy;
  final ValueChanged<double> onChanged;
  final ValueChanged<bool> onMutedChanged;

  @override
  Widget build(BuildContext context) {
    final state = volume;
    if (state == null || !state.available) {
      return _InlineNotice(message: state?.message ?? '还没有读取到音量状态。');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          state.endpointName.isEmpty ? '当前 Windows 输出端点' : state.endpointName,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const Icon(Icons.volume_down_outlined),
            Expanded(
              child: Slider(
                value: state.volume,
                onChanged: busy ? null : onChanged,
              ),
            ),
            SizedBox(
              width: 48,
              child: Text('${(state.volume * 100).round()}%'),
            ),
          ],
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('静音'),
          value: state.muted,
          onChanged: busy ? null : onMutedChanged,
        ),
      ],
    );
  }
}

class _ContactsSection extends StatelessWidget {
  const _ContactsSection({required this.contacts, required this.onRefresh});

  final List<PhoneContact> contacts;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return _DataListShell(
      emptyTitle: '没有会话内联系人',
      emptyMessage: '点击刷新后，会从 PBAP 或 Android 伴随端读取联系人；数据不会落盘。',
      onRefresh: onRefresh,
      children: [
        for (final contact in contacts)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.person_outline),
            title: Text(contact.name),
            subtitle: Text(
              [...contact.phones, ...contact.emails].join('  '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}

class _MessagesSection extends StatelessWidget {
  const _MessagesSection({required this.messages, required this.onRefresh});

  final List<PhoneMessage> messages;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return _DataListShell(
      emptyTitle: '没有会话内消息',
      emptyMessage: '点击刷新后，会从 MAP 或 Android 伴随端读取消息；数据不会落盘。',
      onRefresh: onRefresh,
      children: [
        for (final message in messages)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.sms_outlined),
            title: Text(message.address.isEmpty ? '未知号码' : message.address),
            subtitle: Text(
              message.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}

class _CallsSection extends StatelessWidget {
  const _CallsSection({required this.callLogs, required this.onRefresh});

  final List<PhoneCallLog> callLogs;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return _DataListShell(
      emptyTitle: '没有会话内通话记录',
      emptyMessage: '点击刷新后，会从 PBAP/HFP 或 Android 伴随端读取通话记录；数据不会落盘。',
      onRefresh: onRefresh,
      children: [
        for (final log in callLogs)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.call_outlined),
            title: Text(log.name.isEmpty ? log.number : log.name),
            subtitle: Text('${log.type}  ${_formatDuration(log.duration)}'),
          ),
      ],
    );
  }
}

class _FilesSection extends StatelessWidget {
  const _FilesSection({
    required this.files,
    required this.busy,
    required this.canSelectFiles,
    required this.canReceiveFiles,
    required this.onSelectFiles,
    required this.onRefresh,
    required this.onReceiveFile,
  });

  final List<PhoneFileItem> files;
  final bool busy;
  final bool canSelectFiles;
  final bool canReceiveFiles;
  final VoidCallback onSelectFiles;
  final VoidCallback onRefresh;
  final ValueChanged<PhoneFileItem> onReceiveFile;

  @override
  Widget build(BuildContext context) {
    return _DataListShell(
      emptyTitle: '没有会话内文件',
      emptyMessage: '文件只通过 OPP 或 Android 用户选择后传输，不读取手机完整文件系统。',
      leadingActions: [
        if (canSelectFiles)
          FilledButton.icon(
            onPressed: busy ? null : onSelectFiles,
            icon: const Icon(Icons.attach_file),
            label: const Text('选择文件'),
          ),
      ],
      onRefresh: onRefresh,
      children: [
        for (final file in files)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.insert_drive_file_outlined),
            title: Text(file.name),
            subtitle: Text('${file.mimeType}  ${file.size} B'),
            trailing: canReceiveFiles
                ? OutlinedButton.icon(
                    onPressed: busy ? null : () => onReceiveFile(file),
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('接收'),
                  )
                : null,
          ),
      ],
    );
  }
}

class _NetworkSection extends StatelessWidget {
  const _NetworkSection({required this.busy, required this.onOpenPanSettings});

  final bool busy;
  final VoidCallback onOpenPanSettings;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _InlineNotice(
          message:
              'Windows 没有稳定公开的一键 PAN 连接 API。这里负责探测和打开系统入口，连接成功后通过 BthPan 网络适配器诊断确认。',
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: busy ? null : onOpenPanSettings,
          icon: const Icon(Icons.settings_bluetooth_outlined),
          label: const Text('打开蓝牙网络设置'),
        ),
      ],
    );
  }
}

class _InputSection extends StatelessWidget {
  const _InputSection({
    required this.busy,
    required this.isAndroid,
    required this.onRegisterHid,
    required this.onSendKey,
    required this.onSendMouse,
  });

  final bool busy;
  final bool isAndroid;
  final VoidCallback onRegisterHid;
  final ValueChanged<String> onSendKey;
  final void Function({int dx, int dy, int wheel, int buttons}) onSendMouse;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _InlineNotice(
          message:
              'HID 需要 Android 伴随端注册为蓝牙键盘/鼠标。部分厂商系统会限制 HID Device Profile，诊断页会显示真实原因。',
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: busy || !isAndroid ? null : onRegisterHid,
          icon: const Icon(Icons.keyboard_alt_outlined),
          label: const Text('注册 Android HID'),
        ),
        if (isAndroid) ...[
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: busy ? null : () => onSendKey('escape'),
                icon: const Icon(Icons.close),
                label: const Text('Esc'),
              ),
              OutlinedButton.icon(
                onPressed: busy ? null : () => onSendKey('enter'),
                icon: const Icon(Icons.keyboard_return_outlined),
                label: const Text('Enter'),
              ),
              OutlinedButton.icon(
                onPressed: busy ? null : () => onSendKey('space'),
                icon: const Icon(Icons.space_bar_outlined),
                label: const Text('Space'),
              ),
              OutlinedButton.icon(
                onPressed: busy ? null : () => onSendMouse(buttons: 1),
                icon: const Icon(Icons.ads_click_outlined),
                label: const Text('左键'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              IconButton.outlined(
                tooltip: '上移',
                onPressed: busy ? null : () => onSendMouse(dy: -20),
                icon: const Icon(Icons.keyboard_arrow_up),
              ),
              IconButton.outlined(
                tooltip: '左移',
                onPressed: busy ? null : () => onSendMouse(dx: -20),
                icon: const Icon(Icons.keyboard_arrow_left),
              ),
              IconButton.outlined(
                tooltip: '右移',
                onPressed: busy ? null : () => onSendMouse(dx: 20),
                icon: const Icon(Icons.keyboard_arrow_right),
              ),
              IconButton.outlined(
                tooltip: '下移',
                onPressed: busy ? null : () => onSendMouse(dy: 20),
                icon: const Icon(Icons.keyboard_arrow_down),
              ),
              IconButton.outlined(
                tooltip: '滚轮上',
                onPressed: busy ? null : () => onSendMouse(wheel: 1),
                icon: const Icon(Icons.expand_less),
              ),
              IconButton.outlined(
                tooltip: '滚轮下',
                onPressed: busy ? null : () => onSendMouse(wheel: -1),
                icon: const Icon(Icons.expand_more),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _DiagnosticsSection extends StatelessWidget {
  const _DiagnosticsSection({
    required this.diagnostics,
    required this.onRefresh,
  });

  final List<PhoneDiagnostic> diagnostics;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return _DataListShell(
      emptyTitle: '暂无诊断信息',
      emptyMessage: '刷新后会显示 Windows 能力、Android 权限和 Profile 状态。',
      onRefresh: onRefresh,
      children: [
        for (final item in diagnostics)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              item.severity == 'error'
                  ? Icons.error_outline
                  : item.severity == 'warning'
                  ? Icons.warning_amber_outlined
                  : Icons.info_outline,
              color: item.severity == 'error'
                  ? AppColors.bad
                  : item.severity == 'warning'
                  ? AppColors.accent
                  : AppColors.muted,
            ),
            title: Text('${item.area}：${item.status}'),
            subtitle: Text(item.message),
          ),
      ],
    );
  }
}

class _DataListShell extends StatelessWidget {
  const _DataListShell({
    required this.emptyTitle,
    required this.emptyMessage,
    required this.onRefresh,
    required this.children,
    this.leadingActions = const [],
  });

  final String emptyTitle;
  final String emptyMessage;
  final VoidCallback onRefresh;
  final List<Widget> children;
  final List<Widget> leadingActions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ...leadingActions,
              OutlinedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('刷新会话数据'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (children.isEmpty)
          EmptyState(
            icon: Icons.inbox_outlined,
            title: emptyTitle,
            message: emptyMessage,
          )
        else
          Column(children: children),
      ],
    );
  }
}

class _SupportPill extends StatelessWidget {
  const _SupportPill({required this.support});

  final PhoneManagerSupport? support;

  @override
  Widget build(BuildContext context) {
    final available = support?.available;
    return _Pill(
      text: available == true
          ? '可用'
          : available == false
          ? '受限'
          : '检测中',
      color: available == true
          ? AppColors.good
          : available == false
          ? AppColors.bad
          : AppColors.muted,
    );
  }
}

class _StatePill extends StatelessWidget {
  const _StatePill({required this.state});

  final PhoneConnectionState state;

  @override
  Widget build(BuildContext context) {
    final (text, color) = switch (state) {
      PhoneConnectionState.audioOpened => ('传输中', AppColors.good),
      PhoneConnectionState.audioEnabled => ('已连接', AppColors.accent),
      PhoneConnectionState.disconnected => ('未连接', AppColors.muted),
      PhoneConnectionState.unknown => ('未知', AppColors.muted),
    };
    return _Pill(text: text, color: color);
  }
}

class _CapabilityPill extends StatelessWidget {
  const _CapabilityPill({required this.capability});

  final PhoneCapability capability;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: capability.message,
      child: _Pill(
        text: capability.label,
        color: capability.available ? AppColors.good : AppColors.muted,
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 12)),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({
    required this.message,
    this.isError = false,
    this.isWarning = false,
  });

  final String message;
  final bool isError;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final color = isError
        ? AppColors.bad
        : isWarning
        ? AppColors.accent
        : AppColors.muted;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isError || isWarning
            ? color.withValues(alpha: 0.08)
            : AppColors.bg,
        border: Border.all(
          color: isError || isWarning ? color : AppColors.border,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isError
                  ? Icons.error_outline
                  : isWarning
                  ? Icons.warning_amber_outlined
                  : Icons.info_outline,
              size: 18,
              color: color,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: TextStyle(color: color)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhoneManagerGrid extends StatelessWidget {
  const _PhoneManagerGrid({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 980) {
          return Column(children: [left, const SizedBox(height: 16), right]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 390, child: left),
            const SizedBox(width: 16),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}

Widget _busyIconOr(IconData icon, bool busy) {
  if (!busy) {
    return Icon(icon);
  }
  return const SizedBox(
    width: 16,
    height: 16,
    child: CircularProgressIndicator(strokeWidth: 2),
  );
}

String _formatDuration(Duration duration) {
  final totalSeconds = duration.inSeconds;
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
