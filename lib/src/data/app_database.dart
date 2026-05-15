import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

part 'app_database.g.dart';

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get deviceId => text()();

  @override
  Set<Column> get primaryKey => {key};
}

class Notes extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get deviceId => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class Todos extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get deviceId => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class LedgerEntries extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  RealColumn get amount => real()();
  TextColumn get note => text()();
  DateTimeColumn get occurredAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get deviceId => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class CountdownEvents extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  DateTimeColumn get targetDate => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get deviceId => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class PomodoroSessions extends Table {
  TextColumn get id => text()();
  IntColumn get minutes => integer()();
  TextColumn get note => text()();
  DateTimeColumn get completedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get deviceId => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class PomodoroSettings extends Table {
  TextColumn get id => text()();
  IntColumn get focusMinutes => integer().withDefault(const Constant(25))();
  IntColumn get breakMinutes => integer().withDefault(const Constant(5))();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get deviceId => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SteamStatusPresetRecord')
class SteamStatusPresetRecords extends Table {
  @override
  String get tableName => 'steam_status_presets';

  TextColumn get id => text()();
  TextColumn get steamStatusDisplayText => text().named('status_text')();
  IntColumn get relatedSteamAppId => integer().named('app_id').nullable()();
  TextColumn get richPresenceTokenText =>
      text().named('rich_text').nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get deviceId => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SteamStatusHistoryRecord')
class SteamStatusHistoryRecords extends Table {
  @override
  String get tableName => 'steam_status_history_entries';

  TextColumn get id => text()();
  TextColumn get steamStatusDisplayText => text().named('status_text')();
  IntColumn get relatedSteamAppId => integer().named('app_id').nullable()();
  TextColumn get richPresenceTokenText =>
      text().named('rich_text').nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get deviceId => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    AppSettings,
    Notes,
    Todos,
    LedgerEntries,
    CountdownEvents,
    PomodoroSessions,
    PomodoroSettings,
    SteamStatusPresetRecords,
    SteamStatusHistoryRecords,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  static const _uuid = Uuid();

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(steamStatusPresetRecords);
        await migrator.createTable(steamStatusHistoryRecords);
      }
    },
  );

  Stream<String?> watchSettingValue(String key) {
    final query = select(appSettings)..where((row) => row.key.equals(key));
    return query.watchSingleOrNull().map((row) => row?.value);
  }

  Future<String?> getSettingValue(String key) async {
    final query = select(appSettings)..where((row) => row.key.equals(key));
    return (await query.getSingleOrNull())?.value;
  }

  Future<void> setSettingValue(
    String key,
    String value, {
    String? deviceId,
  }) async {
    final resolvedDeviceId = deviceId ?? await ensureDeviceId();
    await into(appSettings).insertOnConflictUpdate(
      AppSetting(
        key: key,
        value: value,
        updatedAt: DateTime.now().toUtc(),
        deviceId: resolvedDeviceId,
      ),
    );
  }

  Future<String> ensureDeviceId() async {
    final existing = await getSettingValue('deviceId');
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final id = _uuid.v4();
    await setSettingValue('deviceId', id, deviceId: id);
    return id;
  }

  Stream<List<Note>> watchActiveNotes() {
    return (select(notes)
          ..where((row) => row.deletedAt.isNull())
          ..orderBy([(row) => OrderingTerm.desc(row.updatedAt)]))
        .watch();
  }

  Future<void> addNote({required String title, required String content}) async {
    final now = DateTime.now().toUtc();
    final deviceId = await ensureDeviceId();
    await into(notes).insert(
      Note(
        id: _uuid.v4(),
        title: title.trim().isEmpty ? '未命名便签' : title.trim(),
        content: content.trim(),
        createdAt: now,
        updatedAt: now,
        deletedAt: null,
        deviceId: deviceId,
      ),
    );
  }

  Future<void> updateNote(
    String id, {
    required String title,
    required String content,
  }) async {
    final existing = await (select(
      notes,
    )..where((row) => row.id.equals(id))).getSingle();
    final now = DateTime.now().toUtc();
    await into(notes).insertOnConflictUpdate(
      existing.copyWith(
        title: title.trim().isEmpty ? '未命名便签' : title.trim(),
        content: content.trim(),
        updatedAt: now,
        deviceId: await ensureDeviceId(),
      ),
    );
  }

  Future<void> deleteNote(String id) async {
    final existing = await (select(
      notes,
    )..where((row) => row.id.equals(id))).getSingle();
    final now = DateTime.now().toUtc();
    await into(notes).insertOnConflictUpdate(
      existing.copyWith(
        updatedAt: now,
        deletedAt: Value(now),
        deviceId: await ensureDeviceId(),
      ),
    );
  }

  Stream<List<Todo>> watchActiveTodos() {
    return (select(todos)
          ..where((row) => row.deletedAt.isNull())
          ..orderBy([
            (row) => OrderingTerm.asc(row.completed),
            (row) => OrderingTerm.desc(row.updatedAt),
          ]))
        .watch();
  }

  Future<void> addTodo(String title) async {
    if (title.trim().isEmpty) {
      return;
    }
    final now = DateTime.now().toUtc();
    await into(todos).insert(
      Todo(
        id: _uuid.v4(),
        title: title.trim(),
        completed: false,
        createdAt: now,
        updatedAt: now,
        deletedAt: null,
        deviceId: await ensureDeviceId(),
      ),
    );
  }

  Future<void> toggleTodo(Todo todo) async {
    await into(todos).insertOnConflictUpdate(
      todo.copyWith(
        completed: !todo.completed,
        updatedAt: DateTime.now().toUtc(),
        deviceId: await ensureDeviceId(),
      ),
    );
  }

  Future<void> deleteTodo(String id) async {
    final existing = await (select(
      todos,
    )..where((row) => row.id.equals(id))).getSingle();
    final now = DateTime.now().toUtc();
    await into(todos).insertOnConflictUpdate(
      existing.copyWith(
        updatedAt: now,
        deletedAt: Value(now),
        deviceId: await ensureDeviceId(),
      ),
    );
  }

  Stream<List<LedgerEntry>> watchActiveLedgerEntries() {
    return (select(ledgerEntries)
          ..where((row) => row.deletedAt.isNull())
          ..orderBy([(row) => OrderingTerm.desc(row.occurredAt)]))
        .watch();
  }

  Future<void> addLedgerEntry({
    required String type,
    required double amount,
    required String note,
  }) async {
    if (amount <= 0) {
      return;
    }
    final now = DateTime.now().toUtc();
    await into(ledgerEntries).insert(
      LedgerEntry(
        id: _uuid.v4(),
        type: type,
        amount: amount,
        note: note.trim(),
        occurredAt: now,
        createdAt: now,
        updatedAt: now,
        deletedAt: null,
        deviceId: await ensureDeviceId(),
      ),
    );
  }

  Future<bool> importLedgerEntry({
    required String sourceId,
    required String type,
    required double amount,
    required String note,
    required DateTime occurredAt,
  }) async {
    final normalizedSourceId = sourceId.trim();
    if (normalizedSourceId.isEmpty || amount <= 0) {
      return false;
    }
    final existing = await (select(
      ledgerEntries,
    )..where((row) => row.id.equals(normalizedSourceId))).getSingleOrNull();
    if (existing != null) {
      return false;
    }
    final now = DateTime.now().toUtc();
    await into(ledgerEntries).insert(
      LedgerEntry(
        id: normalizedSourceId,
        type: type,
        amount: amount,
        note: note.trim(),
        occurredAt: occurredAt.toUtc(),
        createdAt: now,
        updatedAt: now,
        deletedAt: null,
        deviceId: await ensureDeviceId(),
      ),
    );
    return true;
  }

  Future<void> deleteLedgerEntry(String id) async {
    final existing = await (select(
      ledgerEntries,
    )..where((row) => row.id.equals(id))).getSingle();
    final now = DateTime.now().toUtc();
    await into(ledgerEntries).insertOnConflictUpdate(
      existing.copyWith(
        updatedAt: now,
        deletedAt: Value(now),
        deviceId: await ensureDeviceId(),
      ),
    );
  }

  Stream<List<CountdownEvent>> watchActiveCountdownEvents() {
    return (select(countdownEvents)
          ..where((row) => row.deletedAt.isNull())
          ..orderBy([(row) => OrderingTerm.asc(row.targetDate)]))
        .watch();
  }

  Future<void> addCountdownEvent({
    required String title,
    required DateTime targetDate,
  }) async {
    if (title.trim().isEmpty) {
      return;
    }
    final now = DateTime.now().toUtc();
    await into(countdownEvents).insert(
      CountdownEvent(
        id: _uuid.v4(),
        title: title.trim(),
        targetDate: targetDate.toUtc(),
        createdAt: now,
        updatedAt: now,
        deletedAt: null,
        deviceId: await ensureDeviceId(),
      ),
    );
  }

  Future<void> deleteCountdownEvent(String id) async {
    final existing = await (select(
      countdownEvents,
    )..where((row) => row.id.equals(id))).getSingle();
    final now = DateTime.now().toUtc();
    await into(countdownEvents).insertOnConflictUpdate(
      existing.copyWith(
        updatedAt: now,
        deletedAt: Value(now),
        deviceId: await ensureDeviceId(),
      ),
    );
  }

  Stream<List<PomodoroSession>> watchPomodoroSessions() {
    return (select(pomodoroSessions)
          ..where((row) => row.deletedAt.isNull())
          ..orderBy([(row) => OrderingTerm.desc(row.completedAt)]))
        .watch();
  }

  Future<void> addPomodoroSession({
    required int minutes,
    String note = '',
  }) async {
    final now = DateTime.now().toUtc();
    await into(pomodoroSessions).insert(
      PomodoroSession(
        id: _uuid.v4(),
        minutes: minutes,
        note: note.trim(),
        completedAt: now,
        createdAt: now,
        updatedAt: now,
        deletedAt: null,
        deviceId: await ensureDeviceId(),
      ),
    );
  }

  Stream<List<SteamStatusPresetRecord>> watchSteamStatusPresets() {
    return (select(steamStatusPresetRecords)
          ..where((row) => row.deletedAt.isNull())
          ..orderBy([(row) => OrderingTerm.desc(row.updatedAt)]))
        .watch();
  }

  Future<void> saveSteamStatusPreset({
    required String text,
    int? appId,
    String? richText,
  }) async {
    final normalizedText = text.trim();
    if (normalizedText.isEmpty) {
      return;
    }
    final now = DateTime.now().toUtc();
    await into(steamStatusPresetRecords).insert(
      SteamStatusPresetRecord(
        id: _uuid.v4(),
        steamStatusDisplayText: normalizedText,
        relatedSteamAppId: appId,
        richPresenceTokenText: _normalizedRichText(richText),
        createdAt: now,
        updatedAt: now,
        deletedAt: null,
        deviceId: await ensureDeviceId(),
      ),
    );
  }

  Future<void> deleteSteamStatusPreset(String id) async {
    final existing = await (select(
      steamStatusPresetRecords,
    )..where((row) => row.id.equals(id))).getSingle();
    final now = DateTime.now().toUtc();
    await into(steamStatusPresetRecords).insertOnConflictUpdate(
      existing.copyWith(
        updatedAt: now,
        deletedAt: Value(now),
        deviceId: await ensureDeviceId(),
      ),
    );
  }

  Future<void> clearSteamStatusPresets() async {
    final now = DateTime.now().toUtc();
    final rows = await (select(
      steamStatusPresetRecords,
    )..where((row) => row.deletedAt.isNull())).get();
    final deviceId = await ensureDeviceId();
    for (final row in rows) {
      await into(steamStatusPresetRecords).insertOnConflictUpdate(
        row.copyWith(updatedAt: now, deletedAt: Value(now), deviceId: deviceId),
      );
    }
  }

  Stream<List<SteamStatusHistoryRecord>> watchSteamStatusHistoryEntries({
    int limit = 30,
  }) {
    return (select(steamStatusHistoryRecords)
          ..where((row) => row.deletedAt.isNull())
          ..orderBy([(row) => OrderingTerm.desc(row.updatedAt)])
          ..limit(limit))
        .watch();
  }

  Future<void> addSteamStatusHistory({
    required String text,
    int? appId,
    String? richText,
  }) async {
    final normalizedText = text.trim();
    if (normalizedText.isEmpty) {
      return;
    }
    final normalizedRichText = _normalizedRichText(richText);
    final now = DateTime.now().toUtc();
    final deviceId = await ensureDeviceId();
    final existing =
        await (select(steamStatusHistoryRecords)
              ..where((row) => row.deletedAt.isNull())
              ..where(
                (row) => row.steamStatusDisplayText.equals(normalizedText),
              )
              ..where((row) {
                if (appId == null) {
                  return row.relatedSteamAppId.isNull();
                }
                return row.relatedSteamAppId.equals(appId);
              })
              ..where((row) {
                if (normalizedRichText == null) {
                  return row.richPresenceTokenText.isNull();
                }
                return row.richPresenceTokenText.equals(normalizedRichText);
              }))
            .getSingleOrNull();

    if (existing != null) {
      await into(steamStatusHistoryRecords).insertOnConflictUpdate(
        existing.copyWith(
          updatedAt: now,
          richPresenceTokenText: Value(normalizedRichText),
          deviceId: deviceId,
        ),
      );
    } else {
      await into(steamStatusHistoryRecords).insert(
        SteamStatusHistoryRecord(
          id: _uuid.v4(),
          steamStatusDisplayText: normalizedText,
          relatedSteamAppId: appId,
          richPresenceTokenText: normalizedRichText,
          createdAt: now,
          updatedAt: now,
          deletedAt: null,
          deviceId: deviceId,
        ),
      );
    }

    final activeRows =
        await (select(steamStatusHistoryRecords)
              ..where((row) => row.deletedAt.isNull())
              ..orderBy([(row) => OrderingTerm.desc(row.updatedAt)]))
            .get();
    for (final row in activeRows.skip(30)) {
      await into(steamStatusHistoryRecords).insertOnConflictUpdate(
        row.copyWith(updatedAt: now, deletedAt: Value(now), deviceId: deviceId),
      );
    }
  }

  Future<Map<String, dynamic>> exportPlainSnapshot() async {
    final deviceId = await ensureDeviceId();
    return <String, dynamic>{
      'schemaVersion': schemaVersion,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
      'deviceId': deviceId,
      'settings': (await select(
        appSettings,
      ).get()).map(_settingToJson).toList(),
      'notes': (await select(notes).get()).map(_noteToJson).toList(),
      'todos': (await select(todos).get()).map(_todoToJson).toList(),
      'ledgerEntries': (await select(
        ledgerEntries,
      ).get()).map(_ledgerToJson).toList(),
      'countdownEvents': (await select(
        countdownEvents,
      ).get()).map(_countdownToJson).toList(),
      'pomodoroSessions': (await select(
        pomodoroSessions,
      ).get()).map(_pomodoroToJson).toList(),
      'pomodoroSettings': (await select(
        pomodoroSettings,
      ).get()).map(_pomodoroSettingToJson).toList(),
      'steamStatusPresets': (await select(
        steamStatusPresetRecords,
      ).get()).map(_steamStatusPresetToJson).toList(),
      'steamStatusHistoryEntries': (await select(
        steamStatusHistoryRecords,
      ).get()).map(_steamStatusHistoryEntryToJson).toList(),
    };
  }

  Future<void> importPlainSnapshot(Map<String, dynamic> snapshot) async {
    await transaction(() async {
      await _importSettings(_list(snapshot['settings']));
      await _importNotes(_list(snapshot['notes']));
      await _importTodos(_list(snapshot['todos']));
      await _importLedgerEntries(_list(snapshot['ledgerEntries']));
      await _importCountdownEvents(_list(snapshot['countdownEvents']));
      await _importPomodoroSessions(_list(snapshot['pomodoroSessions']));
      await _importPomodoroSettings(_list(snapshot['pomodoroSettings']));
      await _importSteamStatusPresets(_list(snapshot['steamStatusPresets']));
      await _importSteamStatusHistoryEntries(
        _list(snapshot['steamStatusHistoryEntries']),
      );
    });
  }

  Future<void> _importSettings(List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final incoming = AppSetting(
        key: row['key'] as String,
        value: row['value'] as String? ?? '',
        updatedAt: _date(row['updatedAt']),
        deviceId: row['deviceId'] as String? ?? 'remote',
      );
      final local = await (select(
        appSettings,
      )..where((entry) => entry.key.equals(incoming.key))).getSingleOrNull();
      if (_isNewerOrEqual(incoming.updatedAt, local?.updatedAt)) {
        await into(appSettings).insertOnConflictUpdate(incoming);
      }
    }
  }

  Future<void> _importNotes(List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final incoming = Note(
        id: row['id'] as String,
        title: row['title'] as String? ?? '',
        content: row['content'] as String? ?? '',
        createdAt: _date(row['createdAt']),
        updatedAt: _date(row['updatedAt']),
        deletedAt: _nullableDate(row['deletedAt']),
        deviceId: row['deviceId'] as String? ?? 'remote',
      );
      final local = await (select(
        notes,
      )..where((entry) => entry.id.equals(incoming.id))).getSingleOrNull();
      if (_isNewerOrEqual(incoming.updatedAt, local?.updatedAt)) {
        await into(notes).insertOnConflictUpdate(incoming);
      }
    }
  }

  Future<void> _importTodos(List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final incoming = Todo(
        id: row['id'] as String,
        title: row['title'] as String? ?? '',
        completed: row['completed'] as bool? ?? false,
        createdAt: _date(row['createdAt']),
        updatedAt: _date(row['updatedAt']),
        deletedAt: _nullableDate(row['deletedAt']),
        deviceId: row['deviceId'] as String? ?? 'remote',
      );
      final local = await (select(
        todos,
      )..where((entry) => entry.id.equals(incoming.id))).getSingleOrNull();
      if (_isNewerOrEqual(incoming.updatedAt, local?.updatedAt)) {
        await into(todos).insertOnConflictUpdate(incoming);
      }
    }
  }

  Future<void> _importLedgerEntries(List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final incoming = LedgerEntry(
        id: row['id'] as String,
        type: row['type'] as String? ?? '支出',
        amount: (row['amount'] as num? ?? 0).toDouble(),
        note: row['note'] as String? ?? '',
        occurredAt: _date(row['occurredAt']),
        createdAt: _date(row['createdAt']),
        updatedAt: _date(row['updatedAt']),
        deletedAt: _nullableDate(row['deletedAt']),
        deviceId: row['deviceId'] as String? ?? 'remote',
      );
      final local = await (select(
        ledgerEntries,
      )..where((entry) => entry.id.equals(incoming.id))).getSingleOrNull();
      if (_isNewerOrEqual(incoming.updatedAt, local?.updatedAt)) {
        await into(ledgerEntries).insertOnConflictUpdate(incoming);
      }
    }
  }

  Future<void> _importCountdownEvents(List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final incoming = CountdownEvent(
        id: row['id'] as String,
        title: row['title'] as String? ?? '',
        targetDate: _date(row['targetDate']),
        createdAt: _date(row['createdAt']),
        updatedAt: _date(row['updatedAt']),
        deletedAt: _nullableDate(row['deletedAt']),
        deviceId: row['deviceId'] as String? ?? 'remote',
      );
      final local = await (select(
        countdownEvents,
      )..where((entry) => entry.id.equals(incoming.id))).getSingleOrNull();
      if (_isNewerOrEqual(incoming.updatedAt, local?.updatedAt)) {
        await into(countdownEvents).insertOnConflictUpdate(incoming);
      }
    }
  }

  Future<void> _importPomodoroSessions(List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final incoming = PomodoroSession(
        id: row['id'] as String,
        minutes: row['minutes'] as int? ?? 25,
        note: row['note'] as String? ?? '',
        completedAt: _date(row['completedAt']),
        createdAt: _date(row['createdAt']),
        updatedAt: _date(row['updatedAt']),
        deletedAt: _nullableDate(row['deletedAt']),
        deviceId: row['deviceId'] as String? ?? 'remote',
      );
      final local = await (select(
        pomodoroSessions,
      )..where((entry) => entry.id.equals(incoming.id))).getSingleOrNull();
      if (_isNewerOrEqual(incoming.updatedAt, local?.updatedAt)) {
        await into(pomodoroSessions).insertOnConflictUpdate(incoming);
      }
    }
  }

  Future<void> _importPomodoroSettings(List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final incoming = PomodoroSetting(
        id: row['id'] as String? ?? 'default',
        focusMinutes: row['focusMinutes'] as int? ?? 25,
        breakMinutes: row['breakMinutes'] as int? ?? 5,
        updatedAt: _date(row['updatedAt']),
        deviceId: row['deviceId'] as String? ?? 'remote',
      );
      final local = await (select(
        pomodoroSettings,
      )..where((entry) => entry.id.equals(incoming.id))).getSingleOrNull();
      if (_isNewerOrEqual(incoming.updatedAt, local?.updatedAt)) {
        await into(pomodoroSettings).insertOnConflictUpdate(incoming);
      }
    }
  }

  Future<void> _importSteamStatusPresets(
    List<Map<String, dynamic>> rows,
  ) async {
    for (final row in rows) {
      final incoming = SteamStatusPresetRecord(
        id: row['id'] as String,
        steamStatusDisplayText: row['text'] as String? ?? '',
        relatedSteamAppId: row['appId'] as int?,
        richPresenceTokenText: row['richText'] as String?,
        createdAt: _date(row['createdAt']),
        updatedAt: _date(row['updatedAt']),
        deletedAt: _nullableDate(row['deletedAt']),
        deviceId: row['deviceId'] as String? ?? 'remote',
      );
      final local = await (select(
        steamStatusPresetRecords,
      )..where((entry) => entry.id.equals(incoming.id))).getSingleOrNull();
      if (_isNewerOrEqual(incoming.updatedAt, local?.updatedAt)) {
        await into(steamStatusPresetRecords).insertOnConflictUpdate(incoming);
      }
    }
  }

  Future<void> _importSteamStatusHistoryEntries(
    List<Map<String, dynamic>> rows,
  ) async {
    for (final row in rows) {
      final incoming = SteamStatusHistoryRecord(
        id: row['id'] as String,
        steamStatusDisplayText: row['text'] as String? ?? '',
        relatedSteamAppId: row['appId'] as int?,
        richPresenceTokenText: row['richText'] as String?,
        createdAt: _date(row['createdAt']),
        updatedAt: _date(row['updatedAt']),
        deletedAt: _nullableDate(row['deletedAt']),
        deviceId: row['deviceId'] as String? ?? 'remote',
      );
      final local = await (select(
        steamStatusHistoryRecords,
      )..where((entry) => entry.id.equals(incoming.id))).getSingleOrNull();
      if (_isNewerOrEqual(incoming.updatedAt, local?.updatedAt)) {
        await into(steamStatusHistoryRecords).insertOnConflictUpdate(incoming);
      }
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationSupportDirectory();
    final file = File(p.join(directory.path, 'personal_toolbox.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

bool _isNewerOrEqual(DateTime incoming, DateTime? local) {
  return local == null || !incoming.isBefore(local);
}

DateTime _date(Object? value) {
  if (value is DateTime) {
    return value.toUtc();
  }
  return DateTime.parse(value as String).toUtc();
}

DateTime? _nullableDate(Object? value) {
  if (value == null) {
    return null;
  }
  return _date(value);
}

List<Map<String, dynamic>> _list(Object? value) {
  if (value is! List) {
    return const [];
  }
  return value
      .whereType<Map>()
      .map((row) => Map<String, dynamic>.from(row))
      .toList();
}

String? _normalizedRichText(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}

Map<String, dynamic> _settingToJson(AppSetting row) => {
  'key': row.key,
  'value': row.value,
  'updatedAt': row.updatedAt.toUtc().toIso8601String(),
  'deviceId': row.deviceId,
};

Map<String, dynamic> _noteToJson(Note row) => {
  'id': row.id,
  'title': row.title,
  'content': row.content,
  'createdAt': row.createdAt.toUtc().toIso8601String(),
  'updatedAt': row.updatedAt.toUtc().toIso8601String(),
  'deletedAt': row.deletedAt?.toUtc().toIso8601String(),
  'deviceId': row.deviceId,
};

Map<String, dynamic> _todoToJson(Todo row) => {
  'id': row.id,
  'title': row.title,
  'completed': row.completed,
  'createdAt': row.createdAt.toUtc().toIso8601String(),
  'updatedAt': row.updatedAt.toUtc().toIso8601String(),
  'deletedAt': row.deletedAt?.toUtc().toIso8601String(),
  'deviceId': row.deviceId,
};

Map<String, dynamic> _ledgerToJson(LedgerEntry row) => {
  'id': row.id,
  'type': row.type,
  'amount': row.amount,
  'note': row.note,
  'occurredAt': row.occurredAt.toUtc().toIso8601String(),
  'createdAt': row.createdAt.toUtc().toIso8601String(),
  'updatedAt': row.updatedAt.toUtc().toIso8601String(),
  'deletedAt': row.deletedAt?.toUtc().toIso8601String(),
  'deviceId': row.deviceId,
};

Map<String, dynamic> _countdownToJson(CountdownEvent row) => {
  'id': row.id,
  'title': row.title,
  'targetDate': row.targetDate.toUtc().toIso8601String(),
  'createdAt': row.createdAt.toUtc().toIso8601String(),
  'updatedAt': row.updatedAt.toUtc().toIso8601String(),
  'deletedAt': row.deletedAt?.toUtc().toIso8601String(),
  'deviceId': row.deviceId,
};

Map<String, dynamic> _pomodoroToJson(PomodoroSession row) => {
  'id': row.id,
  'minutes': row.minutes,
  'note': row.note,
  'completedAt': row.completedAt.toUtc().toIso8601String(),
  'createdAt': row.createdAt.toUtc().toIso8601String(),
  'updatedAt': row.updatedAt.toUtc().toIso8601String(),
  'deletedAt': row.deletedAt?.toUtc().toIso8601String(),
  'deviceId': row.deviceId,
};

Map<String, dynamic> _pomodoroSettingToJson(PomodoroSetting row) => {
  'id': row.id,
  'focusMinutes': row.focusMinutes,
  'breakMinutes': row.breakMinutes,
  'updatedAt': row.updatedAt.toUtc().toIso8601String(),
  'deviceId': row.deviceId,
};

Map<String, dynamic> _steamStatusPresetToJson(SteamStatusPresetRecord row) => {
  'id': row.id,
  'text': row.steamStatusDisplayText,
  'appId': row.relatedSteamAppId,
  'richText': row.richPresenceTokenText,
  'createdAt': row.createdAt.toUtc().toIso8601String(),
  'updatedAt': row.updatedAt.toUtc().toIso8601String(),
  'deletedAt': row.deletedAt?.toUtc().toIso8601String(),
  'deviceId': row.deviceId,
};

Map<String, dynamic> _steamStatusHistoryEntryToJson(
  SteamStatusHistoryRecord row,
) => {
  'id': row.id,
  'text': row.steamStatusDisplayText,
  'appId': row.relatedSteamAppId,
  'richText': row.richPresenceTokenText,
  'createdAt': row.createdAt.toUtc().toIso8601String(),
  'updatedAt': row.updatedAt.toUtc().toIso8601String(),
  'deletedAt': row.deletedAt?.toUtc().toIso8601String(),
  'deviceId': row.deviceId,
};
