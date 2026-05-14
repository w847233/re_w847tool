import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';
import '../data/database_provider.dart';
import 'font_weight_option.dart';

const preferredFontWeightKey = 'preferredFontWeight';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(appDatabaseProvider));
});

final preferredFontWeightProvider = StreamProvider<FontWeight>((ref) {
  return ref.watch(settingsRepositoryProvider).watchPreferredFontWeight();
});

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
}
