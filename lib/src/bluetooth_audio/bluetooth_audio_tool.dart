import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../ui/app_panel.dart';
import '../ui/latest_snack_bar.dart';
import 'bluetooth_audio_service.dart';

class BluetoothAudioTool extends StatefulWidget {
  const BluetoothAudioTool({super.key, BluetoothAudioService? service})
    : _service = service;

  final BluetoothAudioService? _service;

  @override
  State<BluetoothAudioTool> createState() => _BluetoothAudioToolState();
}

class _BluetoothAudioToolState extends State<BluetoothAudioTool> {
  late final BluetoothAudioService _service;
  BluetoothAudioSupport? _support;
  List<BluetoothAudioDevice> _devices = const [];
  List<WindowsPlaybackDevice> _playbackDevices = const [];
  String? _selectedDeviceId;
  String? _selectedPlaybackDeviceId;
  Timer? _levelTimer;
  double _playbackLevel = 0;
  bool _loading = true;
  bool _busy = false;
  bool _loadingPlaybackDevices = false;
  bool _settingPlaybackDevice = false;
  bool _pollingPlaybackLevel = false;
  String? _lastError;
  String? _playbackLevelError;

  @override
  void initState() {
    super.initState();
    _service = widget._service ?? const BluetoothAudioService();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialState());
  }

  @override
  void dispose() {
    _levelTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedDevice = _selectedDevice;
    final supported = _support?.supported ?? false;
    return _BluetoothAudioGrid(
      left: Column(
        children: [
          AppPanel(
            title: '接收端状态',
            trailing: _SupportPill(support: _support),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _support?.message ?? '正在检测 Windows 蓝牙音频接收能力...',
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 14),
                _InlineNotice(
                  message:
                      '先在 Windows 设置中完成手机配对，再回到这里刷新设备。启用后，手机可把这台电脑作为蓝牙音频输出，声音会从 Windows 当前默认播放设备输出。',
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: _loading || _busy ? null : _refreshDevices,
                      icon: _loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      label: Text(_loading ? '刷新中...' : '刷新设备'),
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
        ],
      ),
      right: AppPanel(
        title: '已配对音频设备',
        child: _loading
            ? const LinearProgressIndicator()
            : !supported
            ? EmptyState(
                icon: Icons.bluetooth_disabled_outlined,
                title: '当前系统不可用',
                message: _support?.message ?? '未检测到可用的 Windows 蓝牙音频接收 API。',
              )
            : _devices.isEmpty
            ? const EmptyState(
                icon: Icons.bluetooth_searching_outlined,
                title: '没有发现可接收音频的设备',
                message: '请先把 Android 或 iOS 设备与 Windows 蓝牙配对，然后点击刷新设备。',
              )
            : Column(
                children: [
                  _DeviceSelectorPanel(
                    devices: _selectableDevices,
                    selectedDeviceId: _selectedDeviceId,
                    busy: _busy,
                    onChanged: (value) {
                      setState(() {
                        _selectedDeviceId = value;
                        _lastError = null;
                      });
                      _syncLevelPolling();
                    },
                  ),
                  const SizedBox(height: 16),
                  for (final device in _devices) ...[
                    _BluetoothDeviceTile(
                      device: device,
                      selected: device.id == _selectedDeviceId,
                      busy: _busy,
                      onSelect: device.isEnabled
                          ? () {
                              setState(() {
                                _selectedDeviceId = device.id;
                                _lastError = null;
                              });
                              _syncLevelPolling();
                            }
                          : null,
                    ),
                    if (device != _devices.last) const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 16),
                  _ConnectionPanel(
                    selectedDevice: selectedDevice,
                    busy: _busy,
                    onConnect: selectedDevice == null
                        ? null
                        : () => _runConnectionAction(
                            () => _service.enableConnection(selectedDevice.id),
                          ),
                    onDisconnect: selectedDevice == null
                        ? null
                        : () => _runConnectionAction(
                            () => _service.closeConnection(selectedDevice.id),
                          ),
                    onOpen: selectedDevice == null
                        ? null
                        : () => _runConnectionAction(
                            () => _service.openConnection(selectedDevice.id),
                          ),
                    onClose: selectedDevice == null
                        ? null
                        : () => _runConnectionAction(
                            () => _service.closeConnection(selectedDevice.id),
                          ),
                  ),
                  if (selectedDevice?.state ==
                      BluetoothAudioConnectionState.opened) ...[
                    const SizedBox(height: 16),
                    _PlaybackOutputPanel(
                      devices: _playbackDevices,
                      selectedDeviceId: _selectedPlaybackDeviceId,
                      level: _playbackLevel,
                      loading: _loadingPlaybackDevices,
                      setting: _settingPlaybackDevice,
                      levelError: _playbackLevelError,
                      onChanged: _setPlaybackDevice,
                      onRefresh: _refreshPlaybackDevices,
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  BluetoothAudioDevice? get _selectedDevice {
    final selectedId = _selectedDeviceId;
    if (selectedId == null) {
      return null;
    }
    for (final device in _devices) {
      if (device.id == selectedId && device.isEnabled) {
        return device;
      }
    }
    return null;
  }

  List<BluetoothAudioDevice> get _selectableDevices {
    return _devices.where((device) => device.isEnabled).toList();
  }

  Future<void> _loadInitialState() async {
    setState(() {
      _loading = true;
      _lastError = null;
    });
    try {
      final support = await _service.checkSupport();
      final devices = support.supported
          ? await _service.listDevices()
          : const <BluetoothAudioDevice>[];
      final playbackDevices = support.supported
          ? await _service.listPlaybackDevices()
          : const <WindowsPlaybackDevice>[];
      if (!mounted) {
        return;
      }
      setState(() {
        _support = support;
        _devices = devices;
        _selectedDeviceId = _selectedDeviceIdFor(devices);
        _playbackDevices = playbackDevices;
        _selectedPlaybackDeviceId = _selectedPlaybackDeviceIdFor(
          playbackDevices,
        );
      });
      _syncLevelPolling();
    } catch (error) {
      if (mounted) {
        setState(() => _lastError = '初始化蓝牙音频转接失败：$error');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _refreshDevices() async {
    setState(() {
      _loading = true;
      _lastError = null;
    });
    try {
      final devices = await _service.listDevices();
      if (!mounted) {
        return;
      }
      setState(() {
        _devices = devices;
        _selectedDeviceId = _selectedDeviceIdFor(devices);
      });
      _syncLevelPolling();
    } catch (error) {
      if (mounted) {
        setState(() => _lastError = '刷新蓝牙音频设备失败：$error');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _refreshPlaybackDevices() async {
    setState(() {
      _loadingPlaybackDevices = true;
      _lastError = null;
    });
    try {
      final devices = await _service.listPlaybackDevices();
      if (!mounted) {
        return;
      }
      setState(() {
        _playbackDevices = devices;
        _selectedPlaybackDeviceId = _selectedPlaybackDeviceIdFor(devices);
      });
    } catch (error) {
      if (mounted) {
        setState(() => _lastError = '刷新 Windows 播放设备失败：$error');
      }
    } finally {
      if (mounted) {
        setState(() => _loadingPlaybackDevices = false);
      }
    }
  }

  String? _selectedDeviceIdFor(List<BluetoothAudioDevice> devices) {
    final selected = _selectedDeviceId;
    if (selected != null &&
        devices.any((device) => device.id == selected && device.isEnabled)) {
      return selected;
    }
    return devices.where((device) => device.isEnabled).firstOrNull?.id;
  }

  String? _selectedPlaybackDeviceIdFor(
    List<WindowsPlaybackDevice> devices, {
    String? preferredId,
  }) {
    if (preferredId != null &&
        devices.any((device) => device.id == preferredId)) {
      return preferredId;
    }
    final selected = _selectedPlaybackDeviceId;
    if (selected != null && devices.any((device) => device.id == selected)) {
      return selected;
    }
    return devices.where((device) => device.isDefault).firstOrNull?.id ??
        devices.firstOrNull?.id;
  }

  Future<void> _runConnectionAction(
    Future<BluetoothAudioConnectionResult> Function() action,
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
      await _refreshDevices();
      if (mounted) {
        ScaffoldMessenger.of(context).showLatestSnackMessage(result.message);
      }
      if (!result.success && mounted) {
        setState(() => _lastError = result.message);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _lastError = '蓝牙音频连接操作失败：$error');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
      _syncLevelPolling();
    }
  }

  Future<void> _setPlaybackDevice(String? deviceId) async {
    if (deviceId == null) {
      return;
    }
    setState(() {
      _settingPlaybackDevice = true;
      _lastError = null;
      _selectedPlaybackDeviceId = deviceId;
    });
    try {
      final result = await _service.setPlaybackDevice(deviceId);
      final devices = await _service.listPlaybackDevices();
      if (!mounted) {
        return;
      }
      setState(() {
        _playbackDevices = devices;
        _selectedPlaybackDeviceId = _selectedPlaybackDeviceIdFor(
          devices,
          preferredId: result.success ? deviceId : null,
        );
      });
      ScaffoldMessenger.of(context).showLatestSnackMessage(result.message);
      if (!result.success) {
        setState(() => _lastError = result.message);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _lastError = '切换 Windows 播放设备失败：$error');
      }
    } finally {
      if (mounted) {
        setState(() => _settingPlaybackDevice = false);
      }
    }
  }

  void _syncLevelPolling() {
    if (_selectedDevice?.state == BluetoothAudioConnectionState.opened) {
      _startLevelPolling();
    } else {
      _stopLevelPolling();
    }
  }

  void _startLevelPolling() {
    if (_levelTimer != null) {
      return;
    }
    _pollPlaybackLevel();
    _levelTimer = Timer.periodic(
      const Duration(milliseconds: 300),
      (_) => _pollPlaybackLevel(),
    );
  }

  void _stopLevelPolling() {
    _levelTimer?.cancel();
    _levelTimer = null;
    _pollingPlaybackLevel = false;
    if (mounted && (_playbackLevel != 0 || _playbackLevelError != null)) {
      setState(() {
        _playbackLevel = 0;
        _playbackLevelError = null;
      });
    }
  }

  Future<void> _pollPlaybackLevel() async {
    if (_pollingPlaybackLevel ||
        _selectedDevice?.state != BluetoothAudioConnectionState.opened) {
      return;
    }
    _pollingPlaybackLevel = true;
    try {
      final level = await _service.getPlaybackLevel(
        playbackDeviceId: _selectedPlaybackDeviceId,
      );
      if (!mounted ||
          _selectedDevice?.state != BluetoothAudioConnectionState.opened) {
        return;
      }
      setState(() {
        _playbackLevel = level;
        _playbackLevelError = null;
      });
    } catch (error) {
      if (mounted) {
        setState(() => _playbackLevelError = '无法读取当前输出电平：$error');
      }
    } finally {
      _pollingPlaybackLevel = false;
    }
  }
}

class _DeviceSelectorPanel extends StatelessWidget {
  const _DeviceSelectorPanel({
    required this.devices,
    required this.selectedDeviceId,
    required this.busy,
    required this.onChanged,
  });

  final List<BluetoothAudioDevice> devices;
  final String? selectedDeviceId;
  final bool busy;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (devices.isEmpty) {
      return const _InlineNotice(
        message: '当前没有可选择的蓝牙音频设备。请确认手机已完成蓝牙配对、蓝牙已开启，然后刷新设备。',
        isError: true,
      );
    }
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: devices.any((device) => device.id == selectedDeviceId)
          ? selectedDeviceId
          : null,
      decoration: const InputDecoration(labelText: '选择连接设备'),
      items: [
        for (final device in devices)
          DropdownMenuItem(
            value: device.id,
            child: Text(device.name, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: busy ? null : onChanged,
    );
  }
}

class _BluetoothDeviceTile extends StatelessWidget {
  const _BluetoothDeviceTile({
    required this.device,
    required this.selected,
    required this.busy,
    required this.onSelect,
  });

  final BluetoothAudioDevice device;
  final bool selected;
  final bool busy;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    final canSelect = onSelect != null;
    final stateColor = switch (device.state) {
      BluetoothAudioConnectionState.opened => AppColors.good,
      BluetoothAudioConnectionState.enabled => AppColors.accent,
      BluetoothAudioConnectionState.closed => AppColors.muted,
      BluetoothAudioConnectionState.unknown => AppColors.muted,
    };
    return InkWell(
      onTap: busy ? null : onSelect,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.08)
              : AppColors.bg,
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
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
                    canSelect ? '系统设备状态：可选择' : '系统设备状态：不可选择',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            canSelect
                ? _StatePill(state: device.state)
                : const _Pill(text: '不可选择', color: AppColors.bad),
          ],
        ),
      ),
    );
  }
}

class _ConnectionPanel extends StatelessWidget {
  const _ConnectionPanel({
    required this.selectedDevice,
    required this.busy,
    required this.onConnect,
    required this.onDisconnect,
    required this.onOpen,
    required this.onClose,
  });

  final BluetoothAudioDevice? selectedDevice;
  final bool busy;
  final VoidCallback? onConnect;
  final VoidCallback? onDisconnect;
  final VoidCallback? onOpen;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final device = selectedDevice;
    final isPlaying = device?.state == BluetoothAudioConnectionState.opened;
    final isConnected =
        device?.state == BluetoothAudioConnectionState.enabled || isPlaying;
    final canConnect = device != null && !busy && !isConnected;
    final canDisconnect = device != null && !busy && isConnected;
    final canStart =
        device?.state == BluetoothAudioConnectionState.enabled && !busy;
    final canClose = device != null && !busy && isPlaying;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bluetooth_audio_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    device == null ? '请选择一个设备' : '当前选择：${device.name}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              device == null
                  ? '选择设备后，先在当前设备中点击连接。'
                  : _operationHint(device.state),
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (isConnected)
                  FilledButton.icon(
                    onPressed: canDisconnect ? onDisconnect : null,
                    icon: _busyIconOr(Icons.link_off, busy),
                    label: Text(busy ? '处理中...' : '断开'),
                  )
                else
                  FilledButton.icon(
                    onPressed: canConnect ? onConnect : null,
                    icon: _busyIconOr(Icons.link, busy),
                    label: Text(busy ? '处理中...' : '连接'),
                  ),
                FilledButton.icon(
                  onPressed: canStart ? onOpen : null,
                  icon: _busyIconOr(Icons.play_arrow, busy && isConnected),
                  label: Text(busy && isConnected ? '处理中...' : '开始播放'),
                ),
                if (isPlaying)
                  FilledButton.icon(
                    onPressed: canClose ? onClose : null,
                    icon: _busyIconOr(Icons.stop, busy),
                    label: Text(busy ? '关闭中...' : '关闭播放'),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.stop),
                    label: const Text('关闭播放'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _operationHint(BluetoothAudioConnectionState state) {
    return switch (state) {
      BluetoothAudioConnectionState.opened => '连接已打开，手机音频应通过 Windows 默认播放设备输出。',
      BluetoothAudioConnectionState.enabled => '设备已连接。点击开始播放，或在手机蓝牙输出中选择这台电脑。',
      BluetoothAudioConnectionState.closed => '设备尚未连接。请先在当前设备中点击连接。',
      BluetoothAudioConnectionState.unknown => '设备状态未知。请先刷新设备，或重新点击连接。',
    };
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
}

class _PlaybackOutputPanel extends StatelessWidget {
  const _PlaybackOutputPanel({
    required this.devices,
    required this.selectedDeviceId,
    required this.level,
    required this.loading,
    required this.setting,
    required this.levelError,
    required this.onChanged,
    required this.onRefresh,
  });

  final List<WindowsPlaybackDevice> devices;
  final String? selectedDeviceId;
  final double level;
  final bool loading;
  final bool setting;
  final String? levelError;
  final ValueChanged<String?> onChanged;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final safeLevel = level.clamp(0, 1).toDouble();
    final canChoose = devices.isNotEmpty && !loading && !setting;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.speaker_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Windows 输出',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: '刷新播放设备',
                  onPressed: loading || setting ? null : onRefresh,
                  icon: loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const _InlineNotice(
              message: '播放设备选择会切换 Windows 默认播放设备，蓝牙音频会跟随该输出。',
            ),
            const SizedBox(height: 12),
            if (devices.isEmpty)
              const _InlineNotice(
                message: '没有读取到可选择的 Windows 播放设备，请确认系统输出设备可用后刷新。',
                isError: true,
              )
            else
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue:
                    devices.any((device) => device.id == selectedDeviceId)
                    ? selectedDeviceId
                    : null,
                decoration: const InputDecoration(labelText: '播放到'),
                items: [
                  for (final device in devices)
                    DropdownMenuItem(
                      value: device.id,
                      child: Text(
                        device.isDefault ? '${device.name}（默认）' : device.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: canChoose ? onChanged : null,
              ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '当前输出电平',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ),
                Text(
                  '${(safeLevel * 100).round()}%',
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(value: safeLevel, minHeight: 10),
            ),
            if (levelError != null) ...[
              const SizedBox(height: 10),
              _InlineNotice(message: levelError!, isError: true),
            ],
          ],
        ),
      ),
    );
  }
}

class _SupportPill extends StatelessWidget {
  const _SupportPill({required this.support});

  final BluetoothAudioSupport? support;

  @override
  Widget build(BuildContext context) {
    final supported = support?.supported;
    final color = supported == true
        ? AppColors.good
        : supported == false
        ? AppColors.bad
        : AppColors.muted;
    final text = supported == true
        ? '可用'
        : supported == false
        ? '不可用'
        : '检测中';
    return _Pill(text: text, color: color);
  }
}

class _StatePill extends StatelessWidget {
  const _StatePill({required this.state});

  final BluetoothAudioConnectionState state;

  @override
  Widget build(BuildContext context) {
    final (text, color) = switch (state) {
      BluetoothAudioConnectionState.opened => ('播放中', AppColors.good),
      BluetoothAudioConnectionState.enabled => ('已启用', AppColors.accent),
      BluetoothAudioConnectionState.closed => ('已关闭', AppColors.muted),
      BluetoothAudioConnectionState.unknown => ('未知', AppColors.muted),
    };
    return _Pill(text: text, color: color);
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
  const _InlineNotice({required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isError ? AppColors.bad.withValues(alpha: 0.08) : AppColors.bg,
        border: Border.all(color: isError ? AppColors.bad : AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.info_outline,
              size: 18,
              color: isError ? AppColors.bad : AppColors.muted,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: isError ? AppColors.bad : AppColors.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BluetoothAudioGrid extends StatelessWidget {
  const _BluetoothAudioGrid({required this.left, required this.right});

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

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
