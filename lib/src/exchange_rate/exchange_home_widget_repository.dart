import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';
import '../data/database_provider.dart';
import 'sina_forex_market_service.dart';

const exchangeHomeWidgetConfigKey = 'exchangeHomeWidgetConfig';

final exchangeHomeWidgetRepositoryProvider =
    Provider<ExchangeHomeWidgetRepository>((ref) {
      return ExchangeHomeWidgetRepository(ref.watch(appDatabaseProvider));
    });

final exchangeHomeWidgetConfigProvider =
    StreamProvider<ExchangeHomeWidgetConfig>((ref) {
      return ref.watch(exchangeHomeWidgetRepositoryProvider).watchConfig();
    });

class ExchangeHomeWidgetConfig {
  const ExchangeHomeWidgetConfig({
    this.fromCode = 'CNY',
    this.targetCodes = const ['JPY', 'USD'],
    this.refreshSeconds = 30,
  });

  static const defaultAmount = 100.0;
  static const minRefreshSeconds = 5;

  final String fromCode;
  final List<String> targetCodes;
  final int refreshSeconds;

  ExchangeHomeWidgetConfig copyWith({
    String? fromCode,
    List<String>? targetCodes,
    int? refreshSeconds,
  }) {
    return ExchangeHomeWidgetConfig(
      fromCode: fromCode ?? this.fromCode,
      targetCodes: targetCodes ?? this.targetCodes,
      refreshSeconds: refreshSeconds ?? this.refreshSeconds,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'fromCode': fromCode,
      'targetCodes': targetCodes,
      'refreshSeconds': refreshSeconds,
    };
  }

  factory ExchangeHomeWidgetConfig.fromJson(Map<String, dynamic> json) {
    final rawTargets = (json['targetCodes'] as List?)
        ?.whereType<String>()
        .toList();
    return ExchangeHomeWidgetConfig(
      fromCode: json['fromCode'] as String? ?? 'CNY',
      targetCodes: rawTargets ?? const ['JPY', 'USD'],
      refreshSeconds: int.tryParse('${json['refreshSeconds'] ?? 30}') ?? 30,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is ExchangeHomeWidgetConfig &&
        other.fromCode == fromCode &&
        _listEquals(other.targetCodes, targetCodes) &&
        other.refreshSeconds == refreshSeconds;
  }

  @override
  int get hashCode =>
      Object.hash(fromCode, Object.hashAll(targetCodes), refreshSeconds);
}

class ExchangeHomeWidgetRepository {
  const ExchangeHomeWidgetRepository(this._database);

  final AppDatabase _database;

  Stream<ExchangeHomeWidgetConfig> watchConfig() {
    return _database
        .watchSettingValue(exchangeHomeWidgetConfigKey)
        .map(parseConfig);
  }

  Future<ExchangeHomeWidgetConfig> loadConfig() async {
    return parseConfig(
      await _database.getSettingValue(exchangeHomeWidgetConfigKey),
    );
  }

  Future<void> saveConfig(ExchangeHomeWidgetConfig config) async {
    final normalized = normalizeConfig(config);
    await _database.setSettingValue(
      exchangeHomeWidgetConfigKey,
      jsonEncode(normalized.toJson()),
    );
  }

  ExchangeHomeWidgetConfig parseConfig(String? source) {
    if (source == null || source.trim().isEmpty) {
      return const ExchangeHomeWidgetConfig();
    }
    try {
      final decoded = jsonDecode(source);
      if (decoded is Map<String, dynamic>) {
        return normalizeConfig(ExchangeHomeWidgetConfig.fromJson(decoded));
      }
      if (decoded is Map) {
        return normalizeConfig(
          ExchangeHomeWidgetConfig.fromJson(Map<String, dynamic>.from(decoded)),
        );
      }
    } catch (_) {}
    return const ExchangeHomeWidgetConfig();
  }

  ExchangeHomeWidgetConfig normalizeConfig(ExchangeHomeWidgetConfig config) {
    final supportedCodes = {
      for (final currency in exchangeCurrencies) currency.code,
    };
    final fromCode = supportedCodes.contains(config.fromCode)
        ? config.fromCode
        : const ExchangeHomeWidgetConfig().fromCode;
    final targets = <String>[];
    final seen = <String>{};
    for (final code in config.targetCodes) {
      if (!supportedCodes.contains(code) ||
          code == fromCode ||
          !seen.add(code)) {
        continue;
      }
      targets.add(code);
    }
    if (targets.isEmpty) {
      for (final code in const ExchangeHomeWidgetConfig().targetCodes) {
        if (code != fromCode &&
            supportedCodes.contains(code) &&
            seen.add(code)) {
          targets.add(code);
        }
      }
    }
    if (targets.isEmpty) {
      final fallback = _firstAvailableTarget(fromCode, const []);
      if (fallback != null) {
        targets.add(fallback);
      }
    }
    final refreshSeconds = config.refreshSeconds < 1
        ? const ExchangeHomeWidgetConfig().refreshSeconds
        : config.refreshSeconds;
    return ExchangeHomeWidgetConfig(
      fromCode: fromCode,
      targetCodes: targets,
      refreshSeconds:
          refreshSeconds.clamp(ExchangeHomeWidgetConfig.minRefreshSeconds, 3600)
              as int,
    );
  }

  String? firstAvailableTarget(String fromCode, List<String> existingTargets) {
    return _firstAvailableTarget(fromCode, existingTargets);
  }

  String? _firstAvailableTarget(String fromCode, List<String> existingTargets) {
    for (final currency in exchangeCurrencies) {
      final code = currency.code;
      if (code != fromCode && !existingTargets.contains(code)) {
        return code;
      }
    }
    return null;
  }
}

bool _listEquals(List<String> left, List<String> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var i = 0; i < left.length; i++) {
    if (left[i] != right[i]) {
      return false;
    }
  }
  return true;
}
