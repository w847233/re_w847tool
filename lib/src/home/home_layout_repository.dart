import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';
import '../data/database_provider.dart';

const homeWidgetLayoutKey = 'homeWidgetLayout';

final homeLayoutRepositoryProvider = Provider<HomeLayoutRepository>((ref) {
  return HomeLayoutRepository(ref.watch(appDatabaseProvider));
});

final homeWidgetLayoutProvider = StreamProvider<List<HomeWidgetLayoutItem>>((
  ref,
) {
  return ref.watch(homeLayoutRepositoryProvider).watchLayout();
});

enum HomeWidgetSize {
  small('small', '1x1', 1, 1),
  wide('wide', '2x1', 2, 1),
  large('large', '2x2', 2, 2),
  banner('banner', '3x1', 3, 1);

  const HomeWidgetSize(this.id, this.label, this.columns, this.rows);

  final String id;
  final String label;
  final int columns;
  final int rows;

  static HomeWidgetSize fromId(String id) {
    return values.firstWhere((size) => size.id == id, orElse: () => small);
  }
}

class HomeWidgetLayoutItem {
  const HomeWidgetLayoutItem({
    required this.widgetId,
    required this.size,
    required this.order,
    required this.visible,
  });

  final String widgetId;
  final HomeWidgetSize size;
  final int order;
  final bool visible;

  HomeWidgetLayoutItem copyWith({
    String? widgetId,
    HomeWidgetSize? size,
    int? order,
    bool? visible,
  }) {
    return HomeWidgetLayoutItem(
      widgetId: widgetId ?? this.widgetId,
      size: size ?? this.size,
      order: order ?? this.order,
      visible: visible ?? this.visible,
    );
  }

  Map<String, dynamic> toJson() => {
    'widgetId': widgetId,
    'size': size.id,
    'order': order,
    'visible': visible,
  };

  factory HomeWidgetLayoutItem.fromJson(Map<String, dynamic> json) {
    return HomeWidgetLayoutItem(
      widgetId: json['widgetId'] as String? ?? '',
      size: HomeWidgetSize.fromId(json['size'] as String? ?? ''),
      order: json['order'] as int? ?? 0,
      visible: json['visible'] as bool? ?? true,
    );
  }
}

class DashboardWidgetDefinition {
  const DashboardWidgetDefinition({
    required this.id,
    required this.title,
    required this.icon,
    required this.defaultSize,
    required this.allowedSizes,
  });

  final String id;
  final String title;
  final IconData icon;
  final HomeWidgetSize defaultSize;
  final List<HomeWidgetSize> allowedSizes;
}

const dashboardWidgetDefinitions = <DashboardWidgetDefinition>[
  DashboardWidgetDefinition(
    id: 'todayTodos',
    title: '今日待办',
    icon: Icons.checklist_outlined,
    defaultSize: HomeWidgetSize.wide,
    allowedSizes: [
      HomeWidgetSize.small,
      HomeWidgetSize.wide,
      HomeWidgetSize.large,
    ],
  ),
  DashboardWidgetDefinition(
    id: 'recentNotes',
    title: '最近便签',
    icon: Icons.sticky_note_2_outlined,
    defaultSize: HomeWidgetSize.wide,
    allowedSizes: [
      HomeWidgetSize.small,
      HomeWidgetSize.wide,
      HomeWidgetSize.large,
    ],
  ),
  DashboardWidgetDefinition(
    id: 'exchangeSnapshot',
    title: '汇率速览',
    icon: Icons.currency_exchange_outlined,
    defaultSize: HomeWidgetSize.wide,
    allowedSizes: [HomeWidgetSize.wide, HomeWidgetSize.large],
  ),
  DashboardWidgetDefinition(
    id: 'monthlyLedger',
    title: '本月收支',
    icon: Icons.account_balance_wallet_outlined,
    defaultSize: HomeWidgetSize.wide,
    allowedSizes: [
      HomeWidgetSize.wide,
      HomeWidgetSize.large,
      HomeWidgetSize.banner,
    ],
  ),
  DashboardWidgetDefinition(
    id: 'countdown',
    title: '倒数日',
    icon: Icons.event_outlined,
    defaultSize: HomeWidgetSize.wide,
    allowedSizes: [
      HomeWidgetSize.small,
      HomeWidgetSize.wide,
      HomeWidgetSize.large,
    ],
  ),
  DashboardWidgetDefinition(
    id: 'pomodoro',
    title: '番茄钟统计',
    icon: Icons.timer_outlined,
    defaultSize: HomeWidgetSize.small,
    allowedSizes: [HomeWidgetSize.small, HomeWidgetSize.wide],
  ),
  DashboardWidgetDefinition(
    id: 'quickActions',
    title: '快捷工具',
    icon: Icons.bolt_outlined,
    defaultSize: HomeWidgetSize.banner,
    allowedSizes: [
      HomeWidgetSize.wide,
      HomeWidgetSize.banner,
      HomeWidgetSize.large,
    ],
  ),
];

class HomeLayoutRepository {
  const HomeLayoutRepository(this._database);

  final AppDatabase _database;

  List<HomeWidgetLayoutItem> get defaultLayout {
    return [
      for (var index = 0; index < dashboardWidgetDefinitions.length; index++)
        HomeWidgetLayoutItem(
          widgetId: dashboardWidgetDefinitions[index].id,
          size: dashboardWidgetDefinitions[index].defaultSize,
          order: index,
          visible: true,
        ),
    ];
  }

  Stream<List<HomeWidgetLayoutItem>> watchLayout() {
    return _database.watchSettingValue(homeWidgetLayoutKey).map(parseLayout);
  }

  Future<List<HomeWidgetLayoutItem>> loadLayout() async {
    return parseLayout(await _database.getSettingValue(homeWidgetLayoutKey));
  }

  Future<void> saveLayout(List<HomeWidgetLayoutItem> layout) async {
    final normalized = _normalize(layout);
    final payload = {
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
      'items': [for (final item in normalized) item.toJson()],
    };
    await _database.setSettingValue(homeWidgetLayoutKey, jsonEncode(payload));
  }

  Future<void> resetLayout() => saveLayout(defaultLayout);

  List<HomeWidgetLayoutItem> parseLayout(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return defaultLayout;
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final items = decoded['items'];
      if (items is! List) {
        return defaultLayout;
      }
      return _normalize(
        items
            .whereType<Map>()
            .map(
              (item) => HomeWidgetLayoutItem.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList(),
      );
    } catch (_) {
      return defaultLayout;
    }
  }

  List<HomeWidgetLayoutItem> _normalize(List<HomeWidgetLayoutItem> layout) {
    final definitionIds = {
      for (final definition in dashboardWidgetDefinitions) definition.id,
    };
    final byId = <String, HomeWidgetLayoutItem>{};
    for (final item in layout) {
      if (!definitionIds.contains(item.widgetId)) {
        continue;
      }
      byId[item.widgetId] = item;
    }

    final ordered = byId.values.toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    final missing = defaultLayout.where(
      (item) => !byId.containsKey(item.widgetId),
    );
    final combined = [...ordered, ...missing];

    return [
      for (var index = 0; index < combined.length; index++)
        combined[index].copyWith(order: index),
    ];
  }
}

DashboardWidgetDefinition dashboardWidgetById(String id) {
  return dashboardWidgetDefinitions.firstWhere(
    (definition) => definition.id == id,
    orElse: () => dashboardWidgetDefinitions.first,
  );
}
