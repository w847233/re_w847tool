import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/app_database.dart';
import '../data/database_provider.dart';
import 'game_library_models.dart';

const gameLibraryItemsKey = 'gameLibraryItems';

final gameLibraryRepositoryProvider = Provider<GameLibraryRepository>((ref) {
  return GameLibraryRepository(ref.watch(appDatabaseProvider));
});

final gameLibraryItemsProvider = StreamProvider<List<GameLibraryItem>>((ref) {
  return ref.watch(gameLibraryRepositoryProvider).watchItems();
});

class GameLibraryRepository {
  const GameLibraryRepository(this._database);

  static const _uuid = Uuid();

  final AppDatabase _database;

  Stream<List<GameLibraryItem>> watchItems() {
    return _database.watchSettingValue(gameLibraryItemsKey).map(parseItems);
  }

  Future<List<GameLibraryItem>> loadItems() async {
    return parseItems(await _database.getSettingValue(gameLibraryItemsKey));
  }

  Future<GameLibraryItem> addGame({
    required String title,
    String cover = '',
  }) async {
    final now = DateTime.now().toUtc();
    final item = GameLibraryItem(
      id: _uuid.v4(),
      title: title.trim(),
      cover: cover.trim(),
      createdAt: now,
      updatedAt: now,
    );
    final items = await loadItems();
    await saveItems([item, ...items]);
    return item;
  }

  Future<void> saveItems(List<GameLibraryItem> items) async {
    final sortedItems = [...items]
      ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
    final value = jsonEncode({
      'items': [for (final item in sortedItems) item.toJson()],
    });
    await _database.setSettingValue(gameLibraryItemsKey, value);
  }

  List<GameLibraryItem> parseItems(String? source) {
    if (source == null || source.trim().isEmpty) {
      return const <GameLibraryItem>[];
    }
    try {
      final decoded = jsonDecode(source);
      final rawItems = decoded is Map ? decoded['items'] : decoded;
      if (rawItems is! List) {
        return const <GameLibraryItem>[];
      }
      final items = rawItems
          .whereType<Map>()
          .map(
            (item) => GameLibraryItem.fromJson(Map<String, dynamic>.from(item)),
          )
          .where((item) => item.id.isNotEmpty && item.title.trim().isNotEmpty)
          .toList();
      items.sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
      return items;
    } catch (_) {
      return const <GameLibraryItem>[];
    }
  }
}
