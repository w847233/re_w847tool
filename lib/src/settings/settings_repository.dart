import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';

import '../data/app_database.dart';
import '../data/database_provider.dart';
import '../sync/webdav_client.dart';
import 'font_weight_option.dart';

const preferredFontWeightKey = 'preferredFontWeight';
const webDavSyncConfigKey = '${localOnlySettingPrefix}webDavSyncConfig';
const syncPassphraseKey = '${localOnlySettingPrefix}syncPassphrase';
const legacyWebDavSyncConfigKey = 'webDavSyncConfig';
const legacySyncPassphraseKey = 'syncPassphrase';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(appDatabaseProvider));
});

final preferredFontWeightProvider = StreamProvider<FontWeight>((ref) {
  return ref.watch(settingsRepositoryProvider).watchPreferredFontWeight();
});

final webDavSyncConfigProvider = StreamProvider<WebDavSyncServerConfig>((ref) {
  return ref.watch(settingsRepositoryProvider).watchWebDavSyncConfig();
});

class WebDavSyncServerConfig {
  const WebDavSyncServerConfig({
    this.baseUrl = '',
    this.username = '',
    this.password = '',
  });

  final String baseUrl;
  final String username;
  final String password;

  bool get isConfigured =>
      baseUrl.trim().isNotEmpty &&
      username.trim().isNotEmpty &&
      password.isNotEmpty;

  WebDavConfig toWebDavConfig() {
    return WebDavConfig(
      baseUrl: baseUrl.trim(),
      username: username.trim(),
      password: password,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'baseUrl': baseUrl.trim(),
      'username': username.trim(),
      'password': password,
    };
  }

  factory WebDavSyncServerConfig.fromJson(Map<String, dynamic> json) {
    return WebDavSyncServerConfig(
      baseUrl: (json['baseUrl'] as String? ?? '').trim(),
      username: (json['username'] as String? ?? '').trim(),
      password: json['password'] as String? ?? '',
    );
  }
}

class SettingsRepository {
  const SettingsRepository(this._database);

  final AppDatabase _database;

  Stream<FontWeight> watchPreferredFontWeight() {
    return _database.watchSettingValue(preferredFontWeightKey).map<FontWeight>((
      value,
    ) {
      final parsed = int.tryParse(value ?? '');
      return fontWeightOptionFromValue(
        parsed ?? defaultFontWeightOption.value,
      ).weight;
    });
  }

  Future<void> setPreferredFontWeight(int value) async {
    final option = fontWeightOptionFromValue(value);
    await _database.setSettingValue(
      preferredFontWeightKey,
      option.value.toString(),
    );
  }

  Stream<WebDavSyncServerConfig> watchWebDavSyncConfig() {
    return _database.watchSettingValue(webDavSyncConfigKey).asyncMap((
      value,
    ) async {
      return parseWebDavSyncConfig(
        value ?? await _database.getSettingValue(legacyWebDavSyncConfigKey),
      );
    });
  }

  Future<WebDavSyncServerConfig> loadWebDavSyncConfig() async {
    return parseWebDavSyncConfig(
      await _database.getSettingValue(webDavSyncConfigKey) ??
          await _database.getSettingValue(legacyWebDavSyncConfigKey),
    );
  }

  Future<void> saveWebDavSyncConfig(WebDavSyncServerConfig config) async {
    await _database.setSettingValue(
      webDavSyncConfigKey,
      jsonEncode(config.toJson()),
    );
    await _database.removeSettingValue(legacyWebDavSyncConfigKey);
  }

  Future<String> loadSyncPassphrase() async {
    return (await _database.getSettingValue(syncPassphraseKey) ??
            await _database.getSettingValue(legacySyncPassphraseKey) ??
            '')
        .trim();
  }

  Future<void> saveSyncPassphrase(String passphrase) async {
    await _database.setSettingValue(syncPassphraseKey, passphrase.trim());
    await _database.removeSettingValue(legacySyncPassphraseKey);
  }

  WebDavSyncServerConfig parseWebDavSyncConfig(String? source) {
    if (source == null || source.trim().isEmpty) {
      return const WebDavSyncServerConfig();
    }
    try {
      final decoded = jsonDecode(source);
      if (decoded is Map<String, dynamic>) {
        return WebDavSyncServerConfig.fromJson(decoded);
      }
      if (decoded is Map) {
        return WebDavSyncServerConfig.fromJson(
          Map<String, dynamic>.from(decoded),
        );
      }
    } catch (_) {}
    return const WebDavSyncServerConfig();
  }
}
