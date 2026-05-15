import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/app_database.dart';
import '../data/database_provider.dart';
import 'nat_traversal_models.dart';

const natTraversalConfigKey = 'natTraversalConfig';
const natTunnelRulesKey = 'natTunnelRules';

final natTraversalRepositoryProvider = Provider<NatTraversalRepository>((ref) {
  return NatTraversalRepository(ref.watch(appDatabaseProvider));
});

final natTraversalConfigProvider = StreamProvider<NatTraversalConfig>((ref) {
  return ref.watch(natTraversalRepositoryProvider).watchConfig();
});

final natTunnelRulesProvider = StreamProvider<List<NatTunnelRule>>((ref) {
  return ref.watch(natTraversalRepositoryProvider).watchRules();
});

class NatTraversalRepository {
  const NatTraversalRepository(this._database);

  static const _uuid = Uuid();

  final AppDatabase _database;

  Stream<NatTraversalConfig> watchConfig() {
    return _database.watchSettingValue(natTraversalConfigKey).map(parseConfig);
  }

  Future<NatTraversalConfig> loadConfig() async {
    return parseConfig(await _database.getSettingValue(natTraversalConfigKey));
  }

  Future<void> saveConfig(NatTraversalConfig config) async {
    await _database.setSettingValue(natTraversalConfigKey, jsonEncode(config));
  }

  Stream<List<NatTunnelRule>> watchRules() {
    return _database.watchSettingValue(natTunnelRulesKey).map(parseRules);
  }

  Future<List<NatTunnelRule>> loadRules() async {
    return parseRules(await _database.getSettingValue(natTunnelRulesKey));
  }

  Future<NatTunnelRule> addRule({
    required NatTunnelProtocol protocol,
    required String targetAddress,
    required int targetPort,
    String label = '',
    String remoteHost = '',
    int? remotePort,
    bool enabled = false,
  }) async {
    final now = DateTime.now().toUtc();
    final rule = NatTunnelRule(
      id: _uuid.v4(),
      protocol: protocol,
      targetAddress: targetAddress.trim().isEmpty
          ? '127.0.0.1'
          : targetAddress.trim(),
      targetPort: targetPort,
      label: label.trim(),
      remoteHost: remoteHost.trim(),
      remotePort: remotePort,
      enabled: enabled,
      createdAt: now,
      updatedAt: now,
    );
    final rules = await loadRules();
    await saveRules([...rules, rule]);
    return rule;
  }

  Future<void> updateRule(NatTunnelRule rule) async {
    final rules = await loadRules();
    await saveRules([
      for (final current in rules)
        if (current.id == rule.id)
          rule.copyWith(updatedAt: DateTime.now().toUtc())
        else
          current,
    ]);
  }

  Future<void> removeRule(String id) async {
    final rules = await loadRules();
    await saveRules([
      for (final rule in rules)
        if (rule.id != id) rule,
    ]);
  }

  Future<void> saveRules(List<NatTunnelRule> rules) async {
    final value = jsonEncode({
      'rules': [for (final rule in rules) rule.toJson()],
    });
    await _database.setSettingValue(natTunnelRulesKey, value);
  }

  NatTraversalConfig parseConfig(String? source) {
    if (source == null || source.trim().isEmpty) {
      return const NatTraversalConfig();
    }
    try {
      final decoded = jsonDecode(source);
      if (decoded is Map<String, dynamic>) {
        return NatTraversalConfig.fromJson(decoded);
      }
      if (decoded is Map) {
        return NatTraversalConfig.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {}
    return const NatTraversalConfig();
  }

  List<NatTunnelRule> parseRules(String? source) {
    if (source == null || source.trim().isEmpty) {
      return const <NatTunnelRule>[];
    }
    try {
      final decoded = jsonDecode(source);
      final rawRules = decoded is Map ? decoded['rules'] : decoded;
      if (rawRules is! List) {
        return const <NatTunnelRule>[];
      }
      return rawRules
          .whereType<Map>()
          .map(
            (item) => NatTunnelRule.fromJson(Map<String, dynamic>.from(item)),
          )
          .where((rule) => rule.id.isNotEmpty && rule.targetPort > 0)
          .toList();
    } catch (_) {
      return const <NatTunnelRule>[];
    }
  }
}
