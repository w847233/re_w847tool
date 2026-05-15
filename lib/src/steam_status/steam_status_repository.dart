import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';
import '../data/database_provider.dart';

final steamStatusRepositoryProvider = Provider<SteamStatusRepository>((ref) {
  return SteamStatusRepository(ref.watch(appDatabaseProvider));
});

final steamStatusPresetsProvider =
    StreamProvider<List<SteamStatusPresetRecord>>((ref) {
      return ref.watch(steamStatusRepositoryProvider).watchPresets();
    });

final steamStatusHistoryProvider =
    StreamProvider<List<SteamStatusHistoryRecord>>((ref) {
      return ref.watch(steamStatusRepositoryProvider).watchHistory();
    });

class SteamStatusRepository {
  const SteamStatusRepository(this._database);

  final AppDatabase _database;

  Stream<List<SteamStatusPresetRecord>> watchPresets() {
    return _database.watchSteamStatusPresets();
  }

  Stream<List<SteamStatusHistoryRecord>> watchHistory() {
    return _database.watchSteamStatusHistoryEntries();
  }

  Future<void> savePreset({
    required String text,
    int? appId,
    String? richText,
  }) {
    return _database.saveSteamStatusPreset(
      text: text,
      appId: appId,
      richText: richText,
    );
  }

  Future<void> deletePreset(String id) {
    return _database.deleteSteamStatusPreset(id);
  }

  Future<void> clearPresets() {
    return _database.clearSteamStatusPresets();
  }

  Future<void> addHistory({
    required String text,
    int? appId,
    String? richText,
  }) {
    return _database.addSteamStatusHistory(
      text: text,
      appId: appId,
      richText: richText,
    );
  }
}
