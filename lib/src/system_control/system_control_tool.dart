import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../ui/app_panel.dart';
import '../ui/latest_snack_bar.dart';
import 'system_control_service.dart';

class SystemControlTool extends StatefulWidget {
  const SystemControlTool({super.key, SystemControlService? service})
    : _service = service;

  final SystemControlService? _service;

  @override
  State<SystemControlTool> createState() => _SystemControlToolState();
}

class _SystemControlToolState extends State<SystemControlTool> {
  late final SystemControlService _service;
  bool _busy = false;
  String? _lastError;

  @override
  void initState() {
    super.initState();
    _service = widget._service ?? const SystemControlService();
  }

  @override
  Widget build(BuildContext context) {
    final supported = _service.isSupported;
    return AppPanel(
      title: '系统控制',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '这里收纳只在 Windows 上可用的系统级快捷操作。当前提供一键熄屏：只关闭显示器，不会锁屏、睡眠或关闭程序。',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.bg,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.visibility_off_outlined,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '一键熄屏',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          '发送 Windows 显示器关闭指令。移动鼠标、触摸板或按任意键后，屏幕会按系统电源策略重新亮起。',
                          style: TextStyle(color: AppColors.muted),
                        ),
                        if (!supported) ...[
                          const SizedBox(height: 10),
                          const Text(
                            '当前平台不是 Windows，此功能不可用。',
                            style: TextStyle(color: AppColors.bad),
                          ),
                        ],
                        if (_lastError != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            _lastError!,
                            style: const TextStyle(color: AppColors.bad),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  FilledButton.icon(
                    onPressed: !supported || _busy ? null : _turnOffDisplay,
                    icon: _busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.power_settings_new),
                    label: Text(_busy ? '发送中...' : '立即熄屏'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _turnOffDisplay() async {
    setState(() {
      _busy = true;
      _lastError = null;
    });
    try {
      await _service.turnOffDisplay();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showLatestSnackBar(
        const SnackBar(content: Text('已发送熄屏指令，按键或移动鼠标可重新亮屏。')),
      );
    } catch (error) {
      if (mounted) {
        setState(() => _lastError = '熄屏失败：$error');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }
}
