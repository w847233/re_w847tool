// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt, deviceId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String value;
  final DateTime updatedAt;
  final String deviceId;
  const AppSetting({
    required this.key,
    required this.value,
    required this.updatedAt,
    required this.deviceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['device_id'] = Variable<String>(deviceId);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
      deviceId: Value(deviceId),
    );
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deviceId': serializer.toJson<String>(deviceId),
    };
  }

  AppSetting copyWith({
    String? key,
    String? value,
    DateTime? updatedAt,
    String? deviceId,
  }) => AppSetting(
    key: key ?? this.key,
    value: value ?? this.value,
    updatedAt: updatedAt ?? this.updatedAt,
    deviceId: deviceId ?? this.deviceId,
  );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deviceId: $deviceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt, deviceId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt &&
          other.deviceId == this.deviceId);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  final Value<String> deviceId;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    required DateTime updatedAt,
    required String deviceId,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value),
       updatedAt = Value(updatedAt),
       deviceId = Value(deviceId);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
    Expression<String>? deviceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<DateTime>? updatedAt,
    Value<String>? deviceId,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NotesTable extends Notes with TableInfo<$NotesTable, Note> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    content,
    createdAt,
    updatedAt,
    deletedAt,
    deviceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Note> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Note map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Note(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
    );
  }

  @override
  $NotesTable createAlias(String alias) {
    return $NotesTable(attachedDatabase, alias);
  }
}

class Note extends DataClass implements Insertable<Note> {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String deviceId;
  const Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.deviceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['content'] = Variable<String>(content);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['device_id'] = Variable<String>(deviceId);
    return map;
  }

  NotesCompanion toCompanion(bool nullToAbsent) {
    return NotesCompanion(
      id: Value(id),
      title: Value(title),
      content: Value(content),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: Value(deviceId),
    );
  }

  factory Note.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Note(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      content: serializer.fromJson<String>(json['content']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'content': serializer.toJson<String>(content),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'deviceId': serializer.toJson<String>(deviceId),
    };
  }

  Note copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? deviceId,
  }) => Note(
    id: id ?? this.id,
    title: title ?? this.title,
    content: content ?? this.content,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
  );
  Note copyWithCompanion(NotesCompanion data) {
    return Note(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      content: data.content.present ? data.content.value : this.content,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Note(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    content,
    createdAt,
    updatedAt,
    deletedAt,
    deviceId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Note &&
          other.id == this.id &&
          other.title == this.title &&
          other.content == this.content &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId);
}

class NotesCompanion extends UpdateCompanion<Note> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> content;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> deviceId;
  final Value<int> rowid;
  const NotesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotesCompanion.insert({
    required String id,
    required String title,
    required String content,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String deviceId,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       content = Value(content),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       deviceId = Value(deviceId);
  static Insertable<Note> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? content,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? deviceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotesCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? content,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? deviceId,
    Value<int>? rowid,
  }) {
    return NotesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TodosTable extends Todos with TableInfo<$TodosTable, Todo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TodosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedMeta = const VerificationMeta(
    'completed',
  );
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
    'completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    completed,
    createdAt,
    updatedAt,
    deletedAt,
    deviceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'todos';
  @override
  VerificationContext validateIntegrity(
    Insertable<Todo> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('completed')) {
      context.handle(
        _completedMeta,
        completed.isAcceptableOrUnknown(data['completed']!, _completedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Todo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Todo(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      completed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}completed'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
    );
  }

  @override
  $TodosTable createAlias(String alias) {
    return $TodosTable(attachedDatabase, alias);
  }
}

class Todo extends DataClass implements Insertable<Todo> {
  final String id;
  final String title;
  final bool completed;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String deviceId;
  const Todo({
    required this.id,
    required this.title,
    required this.completed,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.deviceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['completed'] = Variable<bool>(completed);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['device_id'] = Variable<String>(deviceId);
    return map;
  }

  TodosCompanion toCompanion(bool nullToAbsent) {
    return TodosCompanion(
      id: Value(id),
      title: Value(title),
      completed: Value(completed),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: Value(deviceId),
    );
  }

  factory Todo.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Todo(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      completed: serializer.fromJson<bool>(json['completed']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'completed': serializer.toJson<bool>(completed),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'deviceId': serializer.toJson<String>(deviceId),
    };
  }

  Todo copyWith({
    String? id,
    String? title,
    bool? completed,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? deviceId,
  }) => Todo(
    id: id ?? this.id,
    title: title ?? this.title,
    completed: completed ?? this.completed,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
  );
  Todo copyWithCompanion(TodosCompanion data) {
    return Todo(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      completed: data.completed.present ? data.completed.value : this.completed,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Todo(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('completed: $completed, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    completed,
    createdAt,
    updatedAt,
    deletedAt,
    deviceId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Todo &&
          other.id == this.id &&
          other.title == this.title &&
          other.completed == this.completed &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId);
}

class TodosCompanion extends UpdateCompanion<Todo> {
  final Value<String> id;
  final Value<String> title;
  final Value<bool> completed;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> deviceId;
  final Value<int> rowid;
  const TodosCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.completed = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TodosCompanion.insert({
    required String id,
    required String title,
    this.completed = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String deviceId,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       deviceId = Value(deviceId);
  static Insertable<Todo> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<bool>? completed,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? deviceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (completed != null) 'completed': completed,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TodosCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<bool>? completed,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? deviceId,
    Value<int>? rowid,
  }) {
    return TodosCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TodosCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('completed: $completed, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LedgerEntriesTable extends LedgerEntries
    with TableInfo<$LedgerEntriesTable, LedgerEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LedgerEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    amount,
    note,
    occurredAt,
    createdAt,
    updatedAt,
    deletedAt,
    deviceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ledger_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<LedgerEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    } else if (isInserting) {
      context.missing(_noteMeta);
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LedgerEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LedgerEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
    );
  }

  @override
  $LedgerEntriesTable createAlias(String alias) {
    return $LedgerEntriesTable(attachedDatabase, alias);
  }
}

class LedgerEntry extends DataClass implements Insertable<LedgerEntry> {
  final String id;
  final String type;
  final double amount;
  final String note;
  final DateTime occurredAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String deviceId;
  const LedgerEntry({
    required this.id,
    required this.type,
    required this.amount,
    required this.note,
    required this.occurredAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.deviceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['amount'] = Variable<double>(amount);
    map['note'] = Variable<String>(note);
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['device_id'] = Variable<String>(deviceId);
    return map;
  }

  LedgerEntriesCompanion toCompanion(bool nullToAbsent) {
    return LedgerEntriesCompanion(
      id: Value(id),
      type: Value(type),
      amount: Value(amount),
      note: Value(note),
      occurredAt: Value(occurredAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: Value(deviceId),
    );
  }

  factory LedgerEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LedgerEntry(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      amount: serializer.fromJson<double>(json['amount']),
      note: serializer.fromJson<String>(json['note']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'amount': serializer.toJson<double>(amount),
      'note': serializer.toJson<String>(note),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'deviceId': serializer.toJson<String>(deviceId),
    };
  }

  LedgerEntry copyWith({
    String? id,
    String? type,
    double? amount,
    String? note,
    DateTime? occurredAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? deviceId,
  }) => LedgerEntry(
    id: id ?? this.id,
    type: type ?? this.type,
    amount: amount ?? this.amount,
    note: note ?? this.note,
    occurredAt: occurredAt ?? this.occurredAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
  );
  LedgerEntry copyWithCompanion(LedgerEntriesCompanion data) {
    return LedgerEntry(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      amount: data.amount.present ? data.amount.value : this.amount,
      note: data.note.present ? data.note.value : this.note,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LedgerEntry(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('amount: $amount, ')
          ..write('note: $note, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    amount,
    note,
    occurredAt,
    createdAt,
    updatedAt,
    deletedAt,
    deviceId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LedgerEntry &&
          other.id == this.id &&
          other.type == this.type &&
          other.amount == this.amount &&
          other.note == this.note &&
          other.occurredAt == this.occurredAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId);
}

class LedgerEntriesCompanion extends UpdateCompanion<LedgerEntry> {
  final Value<String> id;
  final Value<String> type;
  final Value<double> amount;
  final Value<String> note;
  final Value<DateTime> occurredAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> deviceId;
  final Value<int> rowid;
  const LedgerEntriesCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.amount = const Value.absent(),
    this.note = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LedgerEntriesCompanion.insert({
    required String id,
    required String type,
    required double amount,
    required String note,
    required DateTime occurredAt,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String deviceId,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       amount = Value(amount),
       note = Value(note),
       occurredAt = Value(occurredAt),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       deviceId = Value(deviceId);
  static Insertable<LedgerEntry> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<double>? amount,
    Expression<String>? note,
    Expression<DateTime>? occurredAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? deviceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (amount != null) 'amount': amount,
      if (note != null) 'note': note,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LedgerEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? type,
    Value<double>? amount,
    Value<String>? note,
    Value<DateTime>? occurredAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? deviceId,
    Value<int>? rowid,
  }) {
    return LedgerEntriesCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      occurredAt: occurredAt ?? this.occurredAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LedgerEntriesCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('amount: $amount, ')
          ..write('note: $note, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CountdownEventsTable extends CountdownEvents
    with TableInfo<$CountdownEventsTable, CountdownEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CountdownEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetDateMeta = const VerificationMeta(
    'targetDate',
  );
  @override
  late final GeneratedColumn<DateTime> targetDate = GeneratedColumn<DateTime>(
    'target_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    targetDate,
    createdAt,
    updatedAt,
    deletedAt,
    deviceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'countdown_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<CountdownEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('target_date')) {
      context.handle(
        _targetDateMeta,
        targetDate.isAcceptableOrUnknown(data['target_date']!, _targetDateMeta),
      );
    } else if (isInserting) {
      context.missing(_targetDateMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CountdownEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CountdownEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      targetDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}target_date'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
    );
  }

  @override
  $CountdownEventsTable createAlias(String alias) {
    return $CountdownEventsTable(attachedDatabase, alias);
  }
}

class CountdownEvent extends DataClass implements Insertable<CountdownEvent> {
  final String id;
  final String title;
  final DateTime targetDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String deviceId;
  const CountdownEvent({
    required this.id,
    required this.title,
    required this.targetDate,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.deviceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['target_date'] = Variable<DateTime>(targetDate);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['device_id'] = Variable<String>(deviceId);
    return map;
  }

  CountdownEventsCompanion toCompanion(bool nullToAbsent) {
    return CountdownEventsCompanion(
      id: Value(id),
      title: Value(title),
      targetDate: Value(targetDate),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: Value(deviceId),
    );
  }

  factory CountdownEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CountdownEvent(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      targetDate: serializer.fromJson<DateTime>(json['targetDate']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'targetDate': serializer.toJson<DateTime>(targetDate),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'deviceId': serializer.toJson<String>(deviceId),
    };
  }

  CountdownEvent copyWith({
    String? id,
    String? title,
    DateTime? targetDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? deviceId,
  }) => CountdownEvent(
    id: id ?? this.id,
    title: title ?? this.title,
    targetDate: targetDate ?? this.targetDate,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
  );
  CountdownEvent copyWithCompanion(CountdownEventsCompanion data) {
    return CountdownEvent(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      targetDate: data.targetDate.present
          ? data.targetDate.value
          : this.targetDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CountdownEvent(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('targetDate: $targetDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    targetDate,
    createdAt,
    updatedAt,
    deletedAt,
    deviceId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CountdownEvent &&
          other.id == this.id &&
          other.title == this.title &&
          other.targetDate == this.targetDate &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId);
}

class CountdownEventsCompanion extends UpdateCompanion<CountdownEvent> {
  final Value<String> id;
  final Value<String> title;
  final Value<DateTime> targetDate;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> deviceId;
  final Value<int> rowid;
  const CountdownEventsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CountdownEventsCompanion.insert({
    required String id,
    required String title,
    required DateTime targetDate,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String deviceId,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       targetDate = Value(targetDate),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       deviceId = Value(deviceId);
  static Insertable<CountdownEvent> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<DateTime>? targetDate,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? deviceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (targetDate != null) 'target_date': targetDate,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CountdownEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<DateTime>? targetDate,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? deviceId,
    Value<int>? rowid,
  }) {
    return CountdownEventsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      targetDate: targetDate ?? this.targetDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (targetDate.present) {
      map['target_date'] = Variable<DateTime>(targetDate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CountdownEventsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('targetDate: $targetDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PomodoroSessionsTable extends PomodoroSessions
    with TableInfo<$PomodoroSessionsTable, PomodoroSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PomodoroSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minutesMeta = const VerificationMeta(
    'minutes',
  );
  @override
  late final GeneratedColumn<int> minutes = GeneratedColumn<int>(
    'minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    minutes,
    note,
    completedAt,
    createdAt,
    updatedAt,
    deletedAt,
    deviceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pomodoro_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<PomodoroSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('minutes')) {
      context.handle(
        _minutesMeta,
        minutes.isAcceptableOrUnknown(data['minutes']!, _minutesMeta),
      );
    } else if (isInserting) {
      context.missing(_minutesMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    } else if (isInserting) {
      context.missing(_noteMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PomodoroSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PomodoroSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      minutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minutes'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
    );
  }

  @override
  $PomodoroSessionsTable createAlias(String alias) {
    return $PomodoroSessionsTable(attachedDatabase, alias);
  }
}

class PomodoroSession extends DataClass implements Insertable<PomodoroSession> {
  final String id;
  final int minutes;
  final String note;
  final DateTime completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String deviceId;
  const PomodoroSession({
    required this.id,
    required this.minutes,
    required this.note,
    required this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.deviceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['minutes'] = Variable<int>(minutes);
    map['note'] = Variable<String>(note);
    map['completed_at'] = Variable<DateTime>(completedAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['device_id'] = Variable<String>(deviceId);
    return map;
  }

  PomodoroSessionsCompanion toCompanion(bool nullToAbsent) {
    return PomodoroSessionsCompanion(
      id: Value(id),
      minutes: Value(minutes),
      note: Value(note),
      completedAt: Value(completedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: Value(deviceId),
    );
  }

  factory PomodoroSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PomodoroSession(
      id: serializer.fromJson<String>(json['id']),
      minutes: serializer.fromJson<int>(json['minutes']),
      note: serializer.fromJson<String>(json['note']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'minutes': serializer.toJson<int>(minutes),
      'note': serializer.toJson<String>(note),
      'completedAt': serializer.toJson<DateTime>(completedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'deviceId': serializer.toJson<String>(deviceId),
    };
  }

  PomodoroSession copyWith({
    String? id,
    int? minutes,
    String? note,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? deviceId,
  }) => PomodoroSession(
    id: id ?? this.id,
    minutes: minutes ?? this.minutes,
    note: note ?? this.note,
    completedAt: completedAt ?? this.completedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
  );
  PomodoroSession copyWithCompanion(PomodoroSessionsCompanion data) {
    return PomodoroSession(
      id: data.id.present ? data.id.value : this.id,
      minutes: data.minutes.present ? data.minutes.value : this.minutes,
      note: data.note.present ? data.note.value : this.note,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PomodoroSession(')
          ..write('id: $id, ')
          ..write('minutes: $minutes, ')
          ..write('note: $note, ')
          ..write('completedAt: $completedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    minutes,
    note,
    completedAt,
    createdAt,
    updatedAt,
    deletedAt,
    deviceId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PomodoroSession &&
          other.id == this.id &&
          other.minutes == this.minutes &&
          other.note == this.note &&
          other.completedAt == this.completedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId);
}

class PomodoroSessionsCompanion extends UpdateCompanion<PomodoroSession> {
  final Value<String> id;
  final Value<int> minutes;
  final Value<String> note;
  final Value<DateTime> completedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> deviceId;
  final Value<int> rowid;
  const PomodoroSessionsCompanion({
    this.id = const Value.absent(),
    this.minutes = const Value.absent(),
    this.note = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PomodoroSessionsCompanion.insert({
    required String id,
    required int minutes,
    required String note,
    required DateTime completedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String deviceId,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       minutes = Value(minutes),
       note = Value(note),
       completedAt = Value(completedAt),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       deviceId = Value(deviceId);
  static Insertable<PomodoroSession> custom({
    Expression<String>? id,
    Expression<int>? minutes,
    Expression<String>? note,
    Expression<DateTime>? completedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? deviceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (minutes != null) 'minutes': minutes,
      if (note != null) 'note': note,
      if (completedAt != null) 'completed_at': completedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PomodoroSessionsCompanion copyWith({
    Value<String>? id,
    Value<int>? minutes,
    Value<String>? note,
    Value<DateTime>? completedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? deviceId,
    Value<int>? rowid,
  }) {
    return PomodoroSessionsCompanion(
      id: id ?? this.id,
      minutes: minutes ?? this.minutes,
      note: note ?? this.note,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (minutes.present) {
      map['minutes'] = Variable<int>(minutes.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PomodoroSessionsCompanion(')
          ..write('id: $id, ')
          ..write('minutes: $minutes, ')
          ..write('note: $note, ')
          ..write('completedAt: $completedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PomodoroSettingsTable extends PomodoroSettings
    with TableInfo<$PomodoroSettingsTable, PomodoroSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PomodoroSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _focusMinutesMeta = const VerificationMeta(
    'focusMinutes',
  );
  @override
  late final GeneratedColumn<int> focusMinutes = GeneratedColumn<int>(
    'focus_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(25),
  );
  static const VerificationMeta _breakMinutesMeta = const VerificationMeta(
    'breakMinutes',
  );
  @override
  late final GeneratedColumn<int> breakMinutes = GeneratedColumn<int>(
    'break_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(5),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    focusMinutes,
    breakMinutes,
    updatedAt,
    deviceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pomodoro_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<PomodoroSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('focus_minutes')) {
      context.handle(
        _focusMinutesMeta,
        focusMinutes.isAcceptableOrUnknown(
          data['focus_minutes']!,
          _focusMinutesMeta,
        ),
      );
    }
    if (data.containsKey('break_minutes')) {
      context.handle(
        _breakMinutesMeta,
        breakMinutes.isAcceptableOrUnknown(
          data['break_minutes']!,
          _breakMinutesMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PomodoroSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PomodoroSetting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      focusMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}focus_minutes'],
      )!,
      breakMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}break_minutes'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
    );
  }

  @override
  $PomodoroSettingsTable createAlias(String alias) {
    return $PomodoroSettingsTable(attachedDatabase, alias);
  }
}

class PomodoroSetting extends DataClass implements Insertable<PomodoroSetting> {
  final String id;
  final int focusMinutes;
  final int breakMinutes;
  final DateTime updatedAt;
  final String deviceId;
  const PomodoroSetting({
    required this.id,
    required this.focusMinutes,
    required this.breakMinutes,
    required this.updatedAt,
    required this.deviceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['focus_minutes'] = Variable<int>(focusMinutes);
    map['break_minutes'] = Variable<int>(breakMinutes);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['device_id'] = Variable<String>(deviceId);
    return map;
  }

  PomodoroSettingsCompanion toCompanion(bool nullToAbsent) {
    return PomodoroSettingsCompanion(
      id: Value(id),
      focusMinutes: Value(focusMinutes),
      breakMinutes: Value(breakMinutes),
      updatedAt: Value(updatedAt),
      deviceId: Value(deviceId),
    );
  }

  factory PomodoroSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PomodoroSetting(
      id: serializer.fromJson<String>(json['id']),
      focusMinutes: serializer.fromJson<int>(json['focusMinutes']),
      breakMinutes: serializer.fromJson<int>(json['breakMinutes']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'focusMinutes': serializer.toJson<int>(focusMinutes),
      'breakMinutes': serializer.toJson<int>(breakMinutes),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deviceId': serializer.toJson<String>(deviceId),
    };
  }

  PomodoroSetting copyWith({
    String? id,
    int? focusMinutes,
    int? breakMinutes,
    DateTime? updatedAt,
    String? deviceId,
  }) => PomodoroSetting(
    id: id ?? this.id,
    focusMinutes: focusMinutes ?? this.focusMinutes,
    breakMinutes: breakMinutes ?? this.breakMinutes,
    updatedAt: updatedAt ?? this.updatedAt,
    deviceId: deviceId ?? this.deviceId,
  );
  PomodoroSetting copyWithCompanion(PomodoroSettingsCompanion data) {
    return PomodoroSetting(
      id: data.id.present ? data.id.value : this.id,
      focusMinutes: data.focusMinutes.present
          ? data.focusMinutes.value
          : this.focusMinutes,
      breakMinutes: data.breakMinutes.present
          ? data.breakMinutes.value
          : this.breakMinutes,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PomodoroSetting(')
          ..write('id: $id, ')
          ..write('focusMinutes: $focusMinutes, ')
          ..write('breakMinutes: $breakMinutes, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deviceId: $deviceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, focusMinutes, breakMinutes, updatedAt, deviceId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PomodoroSetting &&
          other.id == this.id &&
          other.focusMinutes == this.focusMinutes &&
          other.breakMinutes == this.breakMinutes &&
          other.updatedAt == this.updatedAt &&
          other.deviceId == this.deviceId);
}

class PomodoroSettingsCompanion extends UpdateCompanion<PomodoroSetting> {
  final Value<String> id;
  final Value<int> focusMinutes;
  final Value<int> breakMinutes;
  final Value<DateTime> updatedAt;
  final Value<String> deviceId;
  final Value<int> rowid;
  const PomodoroSettingsCompanion({
    this.id = const Value.absent(),
    this.focusMinutes = const Value.absent(),
    this.breakMinutes = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PomodoroSettingsCompanion.insert({
    required String id,
    this.focusMinutes = const Value.absent(),
    this.breakMinutes = const Value.absent(),
    required DateTime updatedAt,
    required String deviceId,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       deviceId = Value(deviceId);
  static Insertable<PomodoroSetting> custom({
    Expression<String>? id,
    Expression<int>? focusMinutes,
    Expression<int>? breakMinutes,
    Expression<DateTime>? updatedAt,
    Expression<String>? deviceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (focusMinutes != null) 'focus_minutes': focusMinutes,
      if (breakMinutes != null) 'break_minutes': breakMinutes,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PomodoroSettingsCompanion copyWith({
    Value<String>? id,
    Value<int>? focusMinutes,
    Value<int>? breakMinutes,
    Value<DateTime>? updatedAt,
    Value<String>? deviceId,
    Value<int>? rowid,
  }) {
    return PomodoroSettingsCompanion(
      id: id ?? this.id,
      focusMinutes: focusMinutes ?? this.focusMinutes,
      breakMinutes: breakMinutes ?? this.breakMinutes,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (focusMinutes.present) {
      map['focus_minutes'] = Variable<int>(focusMinutes.value);
    }
    if (breakMinutes.present) {
      map['break_minutes'] = Variable<int>(breakMinutes.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PomodoroSettingsCompanion(')
          ..write('id: $id, ')
          ..write('focusMinutes: $focusMinutes, ')
          ..write('breakMinutes: $breakMinutes, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SteamStatusPresetRecordsTable extends SteamStatusPresetRecords
    with TableInfo<$SteamStatusPresetRecordsTable, SteamStatusPresetRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SteamStatusPresetRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _steamStatusDisplayTextMeta =
      const VerificationMeta('steamStatusDisplayText');
  @override
  late final GeneratedColumn<String> steamStatusDisplayText =
      GeneratedColumn<String>(
        'status_text',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _relatedSteamAppIdMeta = const VerificationMeta(
    'relatedSteamAppId',
  );
  @override
  late final GeneratedColumn<int> relatedSteamAppId = GeneratedColumn<int>(
    'app_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _richPresenceTokenTextMeta =
      const VerificationMeta('richPresenceTokenText');
  @override
  late final GeneratedColumn<String> richPresenceTokenText =
      GeneratedColumn<String>(
        'rich_text',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    steamStatusDisplayText,
    relatedSteamAppId,
    richPresenceTokenText,
    createdAt,
    updatedAt,
    deletedAt,
    deviceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'steam_status_presets';
  @override
  VerificationContext validateIntegrity(
    Insertable<SteamStatusPresetRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('status_text')) {
      context.handle(
        _steamStatusDisplayTextMeta,
        steamStatusDisplayText.isAcceptableOrUnknown(
          data['status_text']!,
          _steamStatusDisplayTextMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_steamStatusDisplayTextMeta);
    }
    if (data.containsKey('app_id')) {
      context.handle(
        _relatedSteamAppIdMeta,
        relatedSteamAppId.isAcceptableOrUnknown(
          data['app_id']!,
          _relatedSteamAppIdMeta,
        ),
      );
    }
    if (data.containsKey('rich_text')) {
      context.handle(
        _richPresenceTokenTextMeta,
        richPresenceTokenText.isAcceptableOrUnknown(
          data['rich_text']!,
          _richPresenceTokenTextMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SteamStatusPresetRecord map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SteamStatusPresetRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      steamStatusDisplayText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status_text'],
      )!,
      relatedSteamAppId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}app_id'],
      ),
      richPresenceTokenText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rich_text'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
    );
  }

  @override
  $SteamStatusPresetRecordsTable createAlias(String alias) {
    return $SteamStatusPresetRecordsTable(attachedDatabase, alias);
  }
}

class SteamStatusPresetRecord extends DataClass
    implements Insertable<SteamStatusPresetRecord> {
  final String id;
  final String steamStatusDisplayText;
  final int? relatedSteamAppId;
  final String? richPresenceTokenText;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String deviceId;
  const SteamStatusPresetRecord({
    required this.id,
    required this.steamStatusDisplayText,
    this.relatedSteamAppId,
    this.richPresenceTokenText,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.deviceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['status_text'] = Variable<String>(steamStatusDisplayText);
    if (!nullToAbsent || relatedSteamAppId != null) {
      map['app_id'] = Variable<int>(relatedSteamAppId);
    }
    if (!nullToAbsent || richPresenceTokenText != null) {
      map['rich_text'] = Variable<String>(richPresenceTokenText);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['device_id'] = Variable<String>(deviceId);
    return map;
  }

  SteamStatusPresetRecordsCompanion toCompanion(bool nullToAbsent) {
    return SteamStatusPresetRecordsCompanion(
      id: Value(id),
      steamStatusDisplayText: Value(steamStatusDisplayText),
      relatedSteamAppId: relatedSteamAppId == null && nullToAbsent
          ? const Value.absent()
          : Value(relatedSteamAppId),
      richPresenceTokenText: richPresenceTokenText == null && nullToAbsent
          ? const Value.absent()
          : Value(richPresenceTokenText),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: Value(deviceId),
    );
  }

  factory SteamStatusPresetRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SteamStatusPresetRecord(
      id: serializer.fromJson<String>(json['id']),
      steamStatusDisplayText: serializer.fromJson<String>(
        json['steamStatusDisplayText'],
      ),
      relatedSteamAppId: serializer.fromJson<int?>(json['relatedSteamAppId']),
      richPresenceTokenText: serializer.fromJson<String?>(
        json['richPresenceTokenText'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'steamStatusDisplayText': serializer.toJson<String>(
        steamStatusDisplayText,
      ),
      'relatedSteamAppId': serializer.toJson<int?>(relatedSteamAppId),
      'richPresenceTokenText': serializer.toJson<String?>(
        richPresenceTokenText,
      ),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'deviceId': serializer.toJson<String>(deviceId),
    };
  }

  SteamStatusPresetRecord copyWith({
    String? id,
    String? steamStatusDisplayText,
    Value<int?> relatedSteamAppId = const Value.absent(),
    Value<String?> richPresenceTokenText = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? deviceId,
  }) => SteamStatusPresetRecord(
    id: id ?? this.id,
    steamStatusDisplayText:
        steamStatusDisplayText ?? this.steamStatusDisplayText,
    relatedSteamAppId: relatedSteamAppId.present
        ? relatedSteamAppId.value
        : this.relatedSteamAppId,
    richPresenceTokenText: richPresenceTokenText.present
        ? richPresenceTokenText.value
        : this.richPresenceTokenText,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
  );
  SteamStatusPresetRecord copyWithCompanion(
    SteamStatusPresetRecordsCompanion data,
  ) {
    return SteamStatusPresetRecord(
      id: data.id.present ? data.id.value : this.id,
      steamStatusDisplayText: data.steamStatusDisplayText.present
          ? data.steamStatusDisplayText.value
          : this.steamStatusDisplayText,
      relatedSteamAppId: data.relatedSteamAppId.present
          ? data.relatedSteamAppId.value
          : this.relatedSteamAppId,
      richPresenceTokenText: data.richPresenceTokenText.present
          ? data.richPresenceTokenText.value
          : this.richPresenceTokenText,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SteamStatusPresetRecord(')
          ..write('id: $id, ')
          ..write('steamStatusDisplayText: $steamStatusDisplayText, ')
          ..write('relatedSteamAppId: $relatedSteamAppId, ')
          ..write('richPresenceTokenText: $richPresenceTokenText, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    steamStatusDisplayText,
    relatedSteamAppId,
    richPresenceTokenText,
    createdAt,
    updatedAt,
    deletedAt,
    deviceId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SteamStatusPresetRecord &&
          other.id == this.id &&
          other.steamStatusDisplayText == this.steamStatusDisplayText &&
          other.relatedSteamAppId == this.relatedSteamAppId &&
          other.richPresenceTokenText == this.richPresenceTokenText &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId);
}

class SteamStatusPresetRecordsCompanion
    extends UpdateCompanion<SteamStatusPresetRecord> {
  final Value<String> id;
  final Value<String> steamStatusDisplayText;
  final Value<int?> relatedSteamAppId;
  final Value<String?> richPresenceTokenText;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> deviceId;
  final Value<int> rowid;
  const SteamStatusPresetRecordsCompanion({
    this.id = const Value.absent(),
    this.steamStatusDisplayText = const Value.absent(),
    this.relatedSteamAppId = const Value.absent(),
    this.richPresenceTokenText = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SteamStatusPresetRecordsCompanion.insert({
    required String id,
    required String steamStatusDisplayText,
    this.relatedSteamAppId = const Value.absent(),
    this.richPresenceTokenText = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String deviceId,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       steamStatusDisplayText = Value(steamStatusDisplayText),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       deviceId = Value(deviceId);
  static Insertable<SteamStatusPresetRecord> custom({
    Expression<String>? id,
    Expression<String>? steamStatusDisplayText,
    Expression<int>? relatedSteamAppId,
    Expression<String>? richPresenceTokenText,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? deviceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (steamStatusDisplayText != null) 'status_text': steamStatusDisplayText,
      if (relatedSteamAppId != null) 'app_id': relatedSteamAppId,
      if (richPresenceTokenText != null) 'rich_text': richPresenceTokenText,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SteamStatusPresetRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? steamStatusDisplayText,
    Value<int?>? relatedSteamAppId,
    Value<String?>? richPresenceTokenText,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? deviceId,
    Value<int>? rowid,
  }) {
    return SteamStatusPresetRecordsCompanion(
      id: id ?? this.id,
      steamStatusDisplayText:
          steamStatusDisplayText ?? this.steamStatusDisplayText,
      relatedSteamAppId: relatedSteamAppId ?? this.relatedSteamAppId,
      richPresenceTokenText:
          richPresenceTokenText ?? this.richPresenceTokenText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (steamStatusDisplayText.present) {
      map['status_text'] = Variable<String>(steamStatusDisplayText.value);
    }
    if (relatedSteamAppId.present) {
      map['app_id'] = Variable<int>(relatedSteamAppId.value);
    }
    if (richPresenceTokenText.present) {
      map['rich_text'] = Variable<String>(richPresenceTokenText.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SteamStatusPresetRecordsCompanion(')
          ..write('id: $id, ')
          ..write('steamStatusDisplayText: $steamStatusDisplayText, ')
          ..write('relatedSteamAppId: $relatedSteamAppId, ')
          ..write('richPresenceTokenText: $richPresenceTokenText, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SteamStatusHistoryRecordsTable extends SteamStatusHistoryRecords
    with TableInfo<$SteamStatusHistoryRecordsTable, SteamStatusHistoryRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SteamStatusHistoryRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _steamStatusDisplayTextMeta =
      const VerificationMeta('steamStatusDisplayText');
  @override
  late final GeneratedColumn<String> steamStatusDisplayText =
      GeneratedColumn<String>(
        'status_text',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _relatedSteamAppIdMeta = const VerificationMeta(
    'relatedSteamAppId',
  );
  @override
  late final GeneratedColumn<int> relatedSteamAppId = GeneratedColumn<int>(
    'app_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _richPresenceTokenTextMeta =
      const VerificationMeta('richPresenceTokenText');
  @override
  late final GeneratedColumn<String> richPresenceTokenText =
      GeneratedColumn<String>(
        'rich_text',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    steamStatusDisplayText,
    relatedSteamAppId,
    richPresenceTokenText,
    createdAt,
    updatedAt,
    deletedAt,
    deviceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'steam_status_history_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<SteamStatusHistoryRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('status_text')) {
      context.handle(
        _steamStatusDisplayTextMeta,
        steamStatusDisplayText.isAcceptableOrUnknown(
          data['status_text']!,
          _steamStatusDisplayTextMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_steamStatusDisplayTextMeta);
    }
    if (data.containsKey('app_id')) {
      context.handle(
        _relatedSteamAppIdMeta,
        relatedSteamAppId.isAcceptableOrUnknown(
          data['app_id']!,
          _relatedSteamAppIdMeta,
        ),
      );
    }
    if (data.containsKey('rich_text')) {
      context.handle(
        _richPresenceTokenTextMeta,
        richPresenceTokenText.isAcceptableOrUnknown(
          data['rich_text']!,
          _richPresenceTokenTextMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SteamStatusHistoryRecord map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SteamStatusHistoryRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      steamStatusDisplayText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status_text'],
      )!,
      relatedSteamAppId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}app_id'],
      ),
      richPresenceTokenText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rich_text'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
    );
  }

  @override
  $SteamStatusHistoryRecordsTable createAlias(String alias) {
    return $SteamStatusHistoryRecordsTable(attachedDatabase, alias);
  }
}

class SteamStatusHistoryRecord extends DataClass
    implements Insertable<SteamStatusHistoryRecord> {
  final String id;
  final String steamStatusDisplayText;
  final int? relatedSteamAppId;
  final String? richPresenceTokenText;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String deviceId;
  const SteamStatusHistoryRecord({
    required this.id,
    required this.steamStatusDisplayText,
    this.relatedSteamAppId,
    this.richPresenceTokenText,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.deviceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['status_text'] = Variable<String>(steamStatusDisplayText);
    if (!nullToAbsent || relatedSteamAppId != null) {
      map['app_id'] = Variable<int>(relatedSteamAppId);
    }
    if (!nullToAbsent || richPresenceTokenText != null) {
      map['rich_text'] = Variable<String>(richPresenceTokenText);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['device_id'] = Variable<String>(deviceId);
    return map;
  }

  SteamStatusHistoryRecordsCompanion toCompanion(bool nullToAbsent) {
    return SteamStatusHistoryRecordsCompanion(
      id: Value(id),
      steamStatusDisplayText: Value(steamStatusDisplayText),
      relatedSteamAppId: relatedSteamAppId == null && nullToAbsent
          ? const Value.absent()
          : Value(relatedSteamAppId),
      richPresenceTokenText: richPresenceTokenText == null && nullToAbsent
          ? const Value.absent()
          : Value(richPresenceTokenText),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: Value(deviceId),
    );
  }

  factory SteamStatusHistoryRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SteamStatusHistoryRecord(
      id: serializer.fromJson<String>(json['id']),
      steamStatusDisplayText: serializer.fromJson<String>(
        json['steamStatusDisplayText'],
      ),
      relatedSteamAppId: serializer.fromJson<int?>(json['relatedSteamAppId']),
      richPresenceTokenText: serializer.fromJson<String?>(
        json['richPresenceTokenText'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'steamStatusDisplayText': serializer.toJson<String>(
        steamStatusDisplayText,
      ),
      'relatedSteamAppId': serializer.toJson<int?>(relatedSteamAppId),
      'richPresenceTokenText': serializer.toJson<String?>(
        richPresenceTokenText,
      ),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'deviceId': serializer.toJson<String>(deviceId),
    };
  }

  SteamStatusHistoryRecord copyWith({
    String? id,
    String? steamStatusDisplayText,
    Value<int?> relatedSteamAppId = const Value.absent(),
    Value<String?> richPresenceTokenText = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? deviceId,
  }) => SteamStatusHistoryRecord(
    id: id ?? this.id,
    steamStatusDisplayText:
        steamStatusDisplayText ?? this.steamStatusDisplayText,
    relatedSteamAppId: relatedSteamAppId.present
        ? relatedSteamAppId.value
        : this.relatedSteamAppId,
    richPresenceTokenText: richPresenceTokenText.present
        ? richPresenceTokenText.value
        : this.richPresenceTokenText,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
  );
  SteamStatusHistoryRecord copyWithCompanion(
    SteamStatusHistoryRecordsCompanion data,
  ) {
    return SteamStatusHistoryRecord(
      id: data.id.present ? data.id.value : this.id,
      steamStatusDisplayText: data.steamStatusDisplayText.present
          ? data.steamStatusDisplayText.value
          : this.steamStatusDisplayText,
      relatedSteamAppId: data.relatedSteamAppId.present
          ? data.relatedSteamAppId.value
          : this.relatedSteamAppId,
      richPresenceTokenText: data.richPresenceTokenText.present
          ? data.richPresenceTokenText.value
          : this.richPresenceTokenText,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SteamStatusHistoryRecord(')
          ..write('id: $id, ')
          ..write('steamStatusDisplayText: $steamStatusDisplayText, ')
          ..write('relatedSteamAppId: $relatedSteamAppId, ')
          ..write('richPresenceTokenText: $richPresenceTokenText, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    steamStatusDisplayText,
    relatedSteamAppId,
    richPresenceTokenText,
    createdAt,
    updatedAt,
    deletedAt,
    deviceId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SteamStatusHistoryRecord &&
          other.id == this.id &&
          other.steamStatusDisplayText == this.steamStatusDisplayText &&
          other.relatedSteamAppId == this.relatedSteamAppId &&
          other.richPresenceTokenText == this.richPresenceTokenText &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId);
}

class SteamStatusHistoryRecordsCompanion
    extends UpdateCompanion<SteamStatusHistoryRecord> {
  final Value<String> id;
  final Value<String> steamStatusDisplayText;
  final Value<int?> relatedSteamAppId;
  final Value<String?> richPresenceTokenText;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> deviceId;
  final Value<int> rowid;
  const SteamStatusHistoryRecordsCompanion({
    this.id = const Value.absent(),
    this.steamStatusDisplayText = const Value.absent(),
    this.relatedSteamAppId = const Value.absent(),
    this.richPresenceTokenText = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SteamStatusHistoryRecordsCompanion.insert({
    required String id,
    required String steamStatusDisplayText,
    this.relatedSteamAppId = const Value.absent(),
    this.richPresenceTokenText = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String deviceId,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       steamStatusDisplayText = Value(steamStatusDisplayText),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       deviceId = Value(deviceId);
  static Insertable<SteamStatusHistoryRecord> custom({
    Expression<String>? id,
    Expression<String>? steamStatusDisplayText,
    Expression<int>? relatedSteamAppId,
    Expression<String>? richPresenceTokenText,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? deviceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (steamStatusDisplayText != null) 'status_text': steamStatusDisplayText,
      if (relatedSteamAppId != null) 'app_id': relatedSteamAppId,
      if (richPresenceTokenText != null) 'rich_text': richPresenceTokenText,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SteamStatusHistoryRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? steamStatusDisplayText,
    Value<int?>? relatedSteamAppId,
    Value<String?>? richPresenceTokenText,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? deviceId,
    Value<int>? rowid,
  }) {
    return SteamStatusHistoryRecordsCompanion(
      id: id ?? this.id,
      steamStatusDisplayText:
          steamStatusDisplayText ?? this.steamStatusDisplayText,
      relatedSteamAppId: relatedSteamAppId ?? this.relatedSteamAppId,
      richPresenceTokenText:
          richPresenceTokenText ?? this.richPresenceTokenText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (steamStatusDisplayText.present) {
      map['status_text'] = Variable<String>(steamStatusDisplayText.value);
    }
    if (relatedSteamAppId.present) {
      map['app_id'] = Variable<int>(relatedSteamAppId.value);
    }
    if (richPresenceTokenText.present) {
      map['rich_text'] = Variable<String>(richPresenceTokenText.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SteamStatusHistoryRecordsCompanion(')
          ..write('id: $id, ')
          ..write('steamStatusDisplayText: $steamStatusDisplayText, ')
          ..write('relatedSteamAppId: $relatedSteamAppId, ')
          ..write('richPresenceTokenText: $richPresenceTokenText, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GetTokenCredentialSnapshotRecordsTable
    extends GetTokenCredentialSnapshotRecords
    with
        TableInfo<
          $GetTokenCredentialSnapshotRecordsTable,
          GetTokenCredentialSnapshotRecord
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GetTokenCredentialSnapshotRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authIndexMeta = const VerificationMeta(
    'authIndex',
  );
  @override
  late final GeneratedColumn<String> authIndex = GeneratedColumn<String>(
    'auth_index',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _planTypeMeta = const VerificationMeta(
    'planType',
  );
  @override
  late final GeneratedColumn<String> planType = GeneratedColumn<String>(
    'plan_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _credentialNameMeta = const VerificationMeta(
    'credentialName',
  );
  @override
  late final GeneratedColumn<String> credentialName = GeneratedColumn<String>(
    'credential_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usedPercentMeta = const VerificationMeta(
    'usedPercent',
  );
  @override
  late final GeneratedColumn<double> usedPercent = GeneratedColumn<double>(
    'used_percent',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remainingPercentMeta = const VerificationMeta(
    'remainingPercent',
  );
  @override
  late final GeneratedColumn<double> remainingPercent = GeneratedColumn<double>(
    'remaining_percent',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _limitReachedMeta = const VerificationMeta(
    'limitReached',
  );
  @override
  late final GeneratedColumn<bool> limitReached = GeneratedColumn<bool>(
    'limit_reached',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("limit_reached" IN (0, 1))',
    ),
  );
  static const VerificationMeta _errorMeta = const VerificationMeta('error');
  @override
  late final GeneratedColumn<String> error = GeneratedColumn<String>(
    'error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _resetAtMeta = const VerificationMeta(
    'resetAt',
  );
  @override
  late final GeneratedColumn<DateTime> resetAt = GeneratedColumn<DateTime>(
    'reset_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _resetAfterSecondsMeta = const VerificationMeta(
    'resetAfterSeconds',
  );
  @override
  late final GeneratedColumn<int> resetAfterSeconds = GeneratedColumn<int>(
    'reset_after_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _limitWindowSecondsMeta =
      const VerificationMeta('limitWindowSeconds');
  @override
  late final GeneratedColumn<int> limitWindowSeconds = GeneratedColumn<int>(
    'limit_window_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rawJsonMeta = const VerificationMeta(
    'rawJson',
  );
  @override
  late final GeneratedColumn<String> rawJson = GeneratedColumn<String>(
    'raw_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSuccessPreservedMeta =
      const VerificationMeta('lastSuccessPreserved');
  @override
  late final GeneratedColumn<bool> lastSuccessPreserved = GeneratedColumn<bool>(
    'last_success_preserved',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("last_success_preserved" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    email,
    authIndex,
    accountId,
    planType,
    credentialName,
    status,
    usedPercent,
    remainingPercent,
    limitReached,
    error,
    resetAt,
    resetAfterSeconds,
    limitWindowSeconds,
    rawJson,
    lastSuccessPreserved,
    updatedAt,
    deviceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'get_token_credential_snapshots';
  @override
  VerificationContext validateIntegrity(
    Insertable<GetTokenCredentialSnapshotRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('auth_index')) {
      context.handle(
        _authIndexMeta,
        authIndex.isAcceptableOrUnknown(data['auth_index']!, _authIndexMeta),
      );
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    }
    if (data.containsKey('plan_type')) {
      context.handle(
        _planTypeMeta,
        planType.isAcceptableOrUnknown(data['plan_type']!, _planTypeMeta),
      );
    }
    if (data.containsKey('credential_name')) {
      context.handle(
        _credentialNameMeta,
        credentialName.isAcceptableOrUnknown(
          data['credential_name']!,
          _credentialNameMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('used_percent')) {
      context.handle(
        _usedPercentMeta,
        usedPercent.isAcceptableOrUnknown(
          data['used_percent']!,
          _usedPercentMeta,
        ),
      );
    }
    if (data.containsKey('remaining_percent')) {
      context.handle(
        _remainingPercentMeta,
        remainingPercent.isAcceptableOrUnknown(
          data['remaining_percent']!,
          _remainingPercentMeta,
        ),
      );
    }
    if (data.containsKey('limit_reached')) {
      context.handle(
        _limitReachedMeta,
        limitReached.isAcceptableOrUnknown(
          data['limit_reached']!,
          _limitReachedMeta,
        ),
      );
    }
    if (data.containsKey('error')) {
      context.handle(
        _errorMeta,
        error.isAcceptableOrUnknown(data['error']!, _errorMeta),
      );
    }
    if (data.containsKey('reset_at')) {
      context.handle(
        _resetAtMeta,
        resetAt.isAcceptableOrUnknown(data['reset_at']!, _resetAtMeta),
      );
    }
    if (data.containsKey('reset_after_seconds')) {
      context.handle(
        _resetAfterSecondsMeta,
        resetAfterSeconds.isAcceptableOrUnknown(
          data['reset_after_seconds']!,
          _resetAfterSecondsMeta,
        ),
      );
    }
    if (data.containsKey('limit_window_seconds')) {
      context.handle(
        _limitWindowSecondsMeta,
        limitWindowSeconds.isAcceptableOrUnknown(
          data['limit_window_seconds']!,
          _limitWindowSecondsMeta,
        ),
      );
    }
    if (data.containsKey('raw_json')) {
      context.handle(
        _rawJsonMeta,
        rawJson.isAcceptableOrUnknown(data['raw_json']!, _rawJsonMeta),
      );
    }
    if (data.containsKey('last_success_preserved')) {
      context.handle(
        _lastSuccessPreservedMeta,
        lastSuccessPreserved.isAcceptableOrUnknown(
          data['last_success_preserved']!,
          _lastSuccessPreservedMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GetTokenCredentialSnapshotRecord map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GetTokenCredentialSnapshotRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      authIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}auth_index'],
      ),
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      ),
      planType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan_type'],
      ),
      credentialName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}credential_name'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      usedPercent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}used_percent'],
      ),
      remainingPercent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}remaining_percent'],
      ),
      limitReached: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}limit_reached'],
      ),
      error: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error'],
      ),
      resetAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}reset_at'],
      ),
      resetAfterSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reset_after_seconds'],
      ),
      limitWindowSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}limit_window_seconds'],
      ),
      rawJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_json'],
      ),
      lastSuccessPreserved: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}last_success_preserved'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
    );
  }

  @override
  $GetTokenCredentialSnapshotRecordsTable createAlias(String alias) {
    return $GetTokenCredentialSnapshotRecordsTable(attachedDatabase, alias);
  }
}

class GetTokenCredentialSnapshotRecord extends DataClass
    implements Insertable<GetTokenCredentialSnapshotRecord> {
  final String id;
  final String email;
  final String? authIndex;
  final String? accountId;
  final String? planType;
  final String? credentialName;
  final String status;
  final double? usedPercent;
  final double? remainingPercent;
  final bool? limitReached;
  final String? error;
  final DateTime? resetAt;
  final int? resetAfterSeconds;
  final int? limitWindowSeconds;
  final String? rawJson;
  final bool lastSuccessPreserved;
  final DateTime updatedAt;
  final String deviceId;
  const GetTokenCredentialSnapshotRecord({
    required this.id,
    required this.email,
    this.authIndex,
    this.accountId,
    this.planType,
    this.credentialName,
    required this.status,
    this.usedPercent,
    this.remainingPercent,
    this.limitReached,
    this.error,
    this.resetAt,
    this.resetAfterSeconds,
    this.limitWindowSeconds,
    this.rawJson,
    required this.lastSuccessPreserved,
    required this.updatedAt,
    required this.deviceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['email'] = Variable<String>(email);
    if (!nullToAbsent || authIndex != null) {
      map['auth_index'] = Variable<String>(authIndex);
    }
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<String>(accountId);
    }
    if (!nullToAbsent || planType != null) {
      map['plan_type'] = Variable<String>(planType);
    }
    if (!nullToAbsent || credentialName != null) {
      map['credential_name'] = Variable<String>(credentialName);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || usedPercent != null) {
      map['used_percent'] = Variable<double>(usedPercent);
    }
    if (!nullToAbsent || remainingPercent != null) {
      map['remaining_percent'] = Variable<double>(remainingPercent);
    }
    if (!nullToAbsent || limitReached != null) {
      map['limit_reached'] = Variable<bool>(limitReached);
    }
    if (!nullToAbsent || error != null) {
      map['error'] = Variable<String>(error);
    }
    if (!nullToAbsent || resetAt != null) {
      map['reset_at'] = Variable<DateTime>(resetAt);
    }
    if (!nullToAbsent || resetAfterSeconds != null) {
      map['reset_after_seconds'] = Variable<int>(resetAfterSeconds);
    }
    if (!nullToAbsent || limitWindowSeconds != null) {
      map['limit_window_seconds'] = Variable<int>(limitWindowSeconds);
    }
    if (!nullToAbsent || rawJson != null) {
      map['raw_json'] = Variable<String>(rawJson);
    }
    map['last_success_preserved'] = Variable<bool>(lastSuccessPreserved);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['device_id'] = Variable<String>(deviceId);
    return map;
  }

  GetTokenCredentialSnapshotRecordsCompanion toCompanion(bool nullToAbsent) {
    return GetTokenCredentialSnapshotRecordsCompanion(
      id: Value(id),
      email: Value(email),
      authIndex: authIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(authIndex),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      planType: planType == null && nullToAbsent
          ? const Value.absent()
          : Value(planType),
      credentialName: credentialName == null && nullToAbsent
          ? const Value.absent()
          : Value(credentialName),
      status: Value(status),
      usedPercent: usedPercent == null && nullToAbsent
          ? const Value.absent()
          : Value(usedPercent),
      remainingPercent: remainingPercent == null && nullToAbsent
          ? const Value.absent()
          : Value(remainingPercent),
      limitReached: limitReached == null && nullToAbsent
          ? const Value.absent()
          : Value(limitReached),
      error: error == null && nullToAbsent
          ? const Value.absent()
          : Value(error),
      resetAt: resetAt == null && nullToAbsent
          ? const Value.absent()
          : Value(resetAt),
      resetAfterSeconds: resetAfterSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(resetAfterSeconds),
      limitWindowSeconds: limitWindowSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(limitWindowSeconds),
      rawJson: rawJson == null && nullToAbsent
          ? const Value.absent()
          : Value(rawJson),
      lastSuccessPreserved: Value(lastSuccessPreserved),
      updatedAt: Value(updatedAt),
      deviceId: Value(deviceId),
    );
  }

  factory GetTokenCredentialSnapshotRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GetTokenCredentialSnapshotRecord(
      id: serializer.fromJson<String>(json['id']),
      email: serializer.fromJson<String>(json['email']),
      authIndex: serializer.fromJson<String?>(json['authIndex']),
      accountId: serializer.fromJson<String?>(json['accountId']),
      planType: serializer.fromJson<String?>(json['planType']),
      credentialName: serializer.fromJson<String?>(json['credentialName']),
      status: serializer.fromJson<String>(json['status']),
      usedPercent: serializer.fromJson<double?>(json['usedPercent']),
      remainingPercent: serializer.fromJson<double?>(json['remainingPercent']),
      limitReached: serializer.fromJson<bool?>(json['limitReached']),
      error: serializer.fromJson<String?>(json['error']),
      resetAt: serializer.fromJson<DateTime?>(json['resetAt']),
      resetAfterSeconds: serializer.fromJson<int?>(json['resetAfterSeconds']),
      limitWindowSeconds: serializer.fromJson<int?>(json['limitWindowSeconds']),
      rawJson: serializer.fromJson<String?>(json['rawJson']),
      lastSuccessPreserved: serializer.fromJson<bool>(
        json['lastSuccessPreserved'],
      ),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'email': serializer.toJson<String>(email),
      'authIndex': serializer.toJson<String?>(authIndex),
      'accountId': serializer.toJson<String?>(accountId),
      'planType': serializer.toJson<String?>(planType),
      'credentialName': serializer.toJson<String?>(credentialName),
      'status': serializer.toJson<String>(status),
      'usedPercent': serializer.toJson<double?>(usedPercent),
      'remainingPercent': serializer.toJson<double?>(remainingPercent),
      'limitReached': serializer.toJson<bool?>(limitReached),
      'error': serializer.toJson<String?>(error),
      'resetAt': serializer.toJson<DateTime?>(resetAt),
      'resetAfterSeconds': serializer.toJson<int?>(resetAfterSeconds),
      'limitWindowSeconds': serializer.toJson<int?>(limitWindowSeconds),
      'rawJson': serializer.toJson<String?>(rawJson),
      'lastSuccessPreserved': serializer.toJson<bool>(lastSuccessPreserved),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deviceId': serializer.toJson<String>(deviceId),
    };
  }

  GetTokenCredentialSnapshotRecord copyWith({
    String? id,
    String? email,
    Value<String?> authIndex = const Value.absent(),
    Value<String?> accountId = const Value.absent(),
    Value<String?> planType = const Value.absent(),
    Value<String?> credentialName = const Value.absent(),
    String? status,
    Value<double?> usedPercent = const Value.absent(),
    Value<double?> remainingPercent = const Value.absent(),
    Value<bool?> limitReached = const Value.absent(),
    Value<String?> error = const Value.absent(),
    Value<DateTime?> resetAt = const Value.absent(),
    Value<int?> resetAfterSeconds = const Value.absent(),
    Value<int?> limitWindowSeconds = const Value.absent(),
    Value<String?> rawJson = const Value.absent(),
    bool? lastSuccessPreserved,
    DateTime? updatedAt,
    String? deviceId,
  }) => GetTokenCredentialSnapshotRecord(
    id: id ?? this.id,
    email: email ?? this.email,
    authIndex: authIndex.present ? authIndex.value : this.authIndex,
    accountId: accountId.present ? accountId.value : this.accountId,
    planType: planType.present ? planType.value : this.planType,
    credentialName: credentialName.present
        ? credentialName.value
        : this.credentialName,
    status: status ?? this.status,
    usedPercent: usedPercent.present ? usedPercent.value : this.usedPercent,
    remainingPercent: remainingPercent.present
        ? remainingPercent.value
        : this.remainingPercent,
    limitReached: limitReached.present ? limitReached.value : this.limitReached,
    error: error.present ? error.value : this.error,
    resetAt: resetAt.present ? resetAt.value : this.resetAt,
    resetAfterSeconds: resetAfterSeconds.present
        ? resetAfterSeconds.value
        : this.resetAfterSeconds,
    limitWindowSeconds: limitWindowSeconds.present
        ? limitWindowSeconds.value
        : this.limitWindowSeconds,
    rawJson: rawJson.present ? rawJson.value : this.rawJson,
    lastSuccessPreserved: lastSuccessPreserved ?? this.lastSuccessPreserved,
    updatedAt: updatedAt ?? this.updatedAt,
    deviceId: deviceId ?? this.deviceId,
  );
  GetTokenCredentialSnapshotRecord copyWithCompanion(
    GetTokenCredentialSnapshotRecordsCompanion data,
  ) {
    return GetTokenCredentialSnapshotRecord(
      id: data.id.present ? data.id.value : this.id,
      email: data.email.present ? data.email.value : this.email,
      authIndex: data.authIndex.present ? data.authIndex.value : this.authIndex,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      planType: data.planType.present ? data.planType.value : this.planType,
      credentialName: data.credentialName.present
          ? data.credentialName.value
          : this.credentialName,
      status: data.status.present ? data.status.value : this.status,
      usedPercent: data.usedPercent.present
          ? data.usedPercent.value
          : this.usedPercent,
      remainingPercent: data.remainingPercent.present
          ? data.remainingPercent.value
          : this.remainingPercent,
      limitReached: data.limitReached.present
          ? data.limitReached.value
          : this.limitReached,
      error: data.error.present ? data.error.value : this.error,
      resetAt: data.resetAt.present ? data.resetAt.value : this.resetAt,
      resetAfterSeconds: data.resetAfterSeconds.present
          ? data.resetAfterSeconds.value
          : this.resetAfterSeconds,
      limitWindowSeconds: data.limitWindowSeconds.present
          ? data.limitWindowSeconds.value
          : this.limitWindowSeconds,
      rawJson: data.rawJson.present ? data.rawJson.value : this.rawJson,
      lastSuccessPreserved: data.lastSuccessPreserved.present
          ? data.lastSuccessPreserved.value
          : this.lastSuccessPreserved,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GetTokenCredentialSnapshotRecord(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('authIndex: $authIndex, ')
          ..write('accountId: $accountId, ')
          ..write('planType: $planType, ')
          ..write('credentialName: $credentialName, ')
          ..write('status: $status, ')
          ..write('usedPercent: $usedPercent, ')
          ..write('remainingPercent: $remainingPercent, ')
          ..write('limitReached: $limitReached, ')
          ..write('error: $error, ')
          ..write('resetAt: $resetAt, ')
          ..write('resetAfterSeconds: $resetAfterSeconds, ')
          ..write('limitWindowSeconds: $limitWindowSeconds, ')
          ..write('rawJson: $rawJson, ')
          ..write('lastSuccessPreserved: $lastSuccessPreserved, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deviceId: $deviceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    email,
    authIndex,
    accountId,
    planType,
    credentialName,
    status,
    usedPercent,
    remainingPercent,
    limitReached,
    error,
    resetAt,
    resetAfterSeconds,
    limitWindowSeconds,
    rawJson,
    lastSuccessPreserved,
    updatedAt,
    deviceId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GetTokenCredentialSnapshotRecord &&
          other.id == this.id &&
          other.email == this.email &&
          other.authIndex == this.authIndex &&
          other.accountId == this.accountId &&
          other.planType == this.planType &&
          other.credentialName == this.credentialName &&
          other.status == this.status &&
          other.usedPercent == this.usedPercent &&
          other.remainingPercent == this.remainingPercent &&
          other.limitReached == this.limitReached &&
          other.error == this.error &&
          other.resetAt == this.resetAt &&
          other.resetAfterSeconds == this.resetAfterSeconds &&
          other.limitWindowSeconds == this.limitWindowSeconds &&
          other.rawJson == this.rawJson &&
          other.lastSuccessPreserved == this.lastSuccessPreserved &&
          other.updatedAt == this.updatedAt &&
          other.deviceId == this.deviceId);
}

class GetTokenCredentialSnapshotRecordsCompanion
    extends UpdateCompanion<GetTokenCredentialSnapshotRecord> {
  final Value<String> id;
  final Value<String> email;
  final Value<String?> authIndex;
  final Value<String?> accountId;
  final Value<String?> planType;
  final Value<String?> credentialName;
  final Value<String> status;
  final Value<double?> usedPercent;
  final Value<double?> remainingPercent;
  final Value<bool?> limitReached;
  final Value<String?> error;
  final Value<DateTime?> resetAt;
  final Value<int?> resetAfterSeconds;
  final Value<int?> limitWindowSeconds;
  final Value<String?> rawJson;
  final Value<bool> lastSuccessPreserved;
  final Value<DateTime> updatedAt;
  final Value<String> deviceId;
  final Value<int> rowid;
  const GetTokenCredentialSnapshotRecordsCompanion({
    this.id = const Value.absent(),
    this.email = const Value.absent(),
    this.authIndex = const Value.absent(),
    this.accountId = const Value.absent(),
    this.planType = const Value.absent(),
    this.credentialName = const Value.absent(),
    this.status = const Value.absent(),
    this.usedPercent = const Value.absent(),
    this.remainingPercent = const Value.absent(),
    this.limitReached = const Value.absent(),
    this.error = const Value.absent(),
    this.resetAt = const Value.absent(),
    this.resetAfterSeconds = const Value.absent(),
    this.limitWindowSeconds = const Value.absent(),
    this.rawJson = const Value.absent(),
    this.lastSuccessPreserved = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GetTokenCredentialSnapshotRecordsCompanion.insert({
    required String id,
    required String email,
    this.authIndex = const Value.absent(),
    this.accountId = const Value.absent(),
    this.planType = const Value.absent(),
    this.credentialName = const Value.absent(),
    required String status,
    this.usedPercent = const Value.absent(),
    this.remainingPercent = const Value.absent(),
    this.limitReached = const Value.absent(),
    this.error = const Value.absent(),
    this.resetAt = const Value.absent(),
    this.resetAfterSeconds = const Value.absent(),
    this.limitWindowSeconds = const Value.absent(),
    this.rawJson = const Value.absent(),
    this.lastSuccessPreserved = const Value.absent(),
    required DateTime updatedAt,
    required String deviceId,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       email = Value(email),
       status = Value(status),
       updatedAt = Value(updatedAt),
       deviceId = Value(deviceId);
  static Insertable<GetTokenCredentialSnapshotRecord> custom({
    Expression<String>? id,
    Expression<String>? email,
    Expression<String>? authIndex,
    Expression<String>? accountId,
    Expression<String>? planType,
    Expression<String>? credentialName,
    Expression<String>? status,
    Expression<double>? usedPercent,
    Expression<double>? remainingPercent,
    Expression<bool>? limitReached,
    Expression<String>? error,
    Expression<DateTime>? resetAt,
    Expression<int>? resetAfterSeconds,
    Expression<int>? limitWindowSeconds,
    Expression<String>? rawJson,
    Expression<bool>? lastSuccessPreserved,
    Expression<DateTime>? updatedAt,
    Expression<String>? deviceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (authIndex != null) 'auth_index': authIndex,
      if (accountId != null) 'account_id': accountId,
      if (planType != null) 'plan_type': planType,
      if (credentialName != null) 'credential_name': credentialName,
      if (status != null) 'status': status,
      if (usedPercent != null) 'used_percent': usedPercent,
      if (remainingPercent != null) 'remaining_percent': remainingPercent,
      if (limitReached != null) 'limit_reached': limitReached,
      if (error != null) 'error': error,
      if (resetAt != null) 'reset_at': resetAt,
      if (resetAfterSeconds != null) 'reset_after_seconds': resetAfterSeconds,
      if (limitWindowSeconds != null)
        'limit_window_seconds': limitWindowSeconds,
      if (rawJson != null) 'raw_json': rawJson,
      if (lastSuccessPreserved != null)
        'last_success_preserved': lastSuccessPreserved,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GetTokenCredentialSnapshotRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? email,
    Value<String?>? authIndex,
    Value<String?>? accountId,
    Value<String?>? planType,
    Value<String?>? credentialName,
    Value<String>? status,
    Value<double?>? usedPercent,
    Value<double?>? remainingPercent,
    Value<bool?>? limitReached,
    Value<String?>? error,
    Value<DateTime?>? resetAt,
    Value<int?>? resetAfterSeconds,
    Value<int?>? limitWindowSeconds,
    Value<String?>? rawJson,
    Value<bool>? lastSuccessPreserved,
    Value<DateTime>? updatedAt,
    Value<String>? deviceId,
    Value<int>? rowid,
  }) {
    return GetTokenCredentialSnapshotRecordsCompanion(
      id: id ?? this.id,
      email: email ?? this.email,
      authIndex: authIndex ?? this.authIndex,
      accountId: accountId ?? this.accountId,
      planType: planType ?? this.planType,
      credentialName: credentialName ?? this.credentialName,
      status: status ?? this.status,
      usedPercent: usedPercent ?? this.usedPercent,
      remainingPercent: remainingPercent ?? this.remainingPercent,
      limitReached: limitReached ?? this.limitReached,
      error: error ?? this.error,
      resetAt: resetAt ?? this.resetAt,
      resetAfterSeconds: resetAfterSeconds ?? this.resetAfterSeconds,
      limitWindowSeconds: limitWindowSeconds ?? this.limitWindowSeconds,
      rawJson: rawJson ?? this.rawJson,
      lastSuccessPreserved: lastSuccessPreserved ?? this.lastSuccessPreserved,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (authIndex.present) {
      map['auth_index'] = Variable<String>(authIndex.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (planType.present) {
      map['plan_type'] = Variable<String>(planType.value);
    }
    if (credentialName.present) {
      map['credential_name'] = Variable<String>(credentialName.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (usedPercent.present) {
      map['used_percent'] = Variable<double>(usedPercent.value);
    }
    if (remainingPercent.present) {
      map['remaining_percent'] = Variable<double>(remainingPercent.value);
    }
    if (limitReached.present) {
      map['limit_reached'] = Variable<bool>(limitReached.value);
    }
    if (error.present) {
      map['error'] = Variable<String>(error.value);
    }
    if (resetAt.present) {
      map['reset_at'] = Variable<DateTime>(resetAt.value);
    }
    if (resetAfterSeconds.present) {
      map['reset_after_seconds'] = Variable<int>(resetAfterSeconds.value);
    }
    if (limitWindowSeconds.present) {
      map['limit_window_seconds'] = Variable<int>(limitWindowSeconds.value);
    }
    if (rawJson.present) {
      map['raw_json'] = Variable<String>(rawJson.value);
    }
    if (lastSuccessPreserved.present) {
      map['last_success_preserved'] = Variable<bool>(
        lastSuccessPreserved.value,
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GetTokenCredentialSnapshotRecordsCompanion(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('authIndex: $authIndex, ')
          ..write('accountId: $accountId, ')
          ..write('planType: $planType, ')
          ..write('credentialName: $credentialName, ')
          ..write('status: $status, ')
          ..write('usedPercent: $usedPercent, ')
          ..write('remainingPercent: $remainingPercent, ')
          ..write('limitReached: $limitReached, ')
          ..write('error: $error, ')
          ..write('resetAt: $resetAt, ')
          ..write('resetAfterSeconds: $resetAfterSeconds, ')
          ..write('limitWindowSeconds: $limitWindowSeconds, ')
          ..write('rawJson: $rawJson, ')
          ..write('lastSuccessPreserved: $lastSuccessPreserved, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GetTokenCollectionStateRecordsTable
    extends GetTokenCollectionStateRecords
    with
        TableInfo<
          $GetTokenCollectionStateRecordsTable,
          GetTokenCollectionStateRecord
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GetTokenCollectionStateRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageMeta = const VerificationMeta(
    'message',
  );
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
    'message',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _processedMeta = const VerificationMeta(
    'processed',
  );
  @override
  late final GeneratedColumn<int> processed = GeneratedColumn<int>(
    'processed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalMeta = const VerificationMeta('total');
  @override
  late final GeneratedColumn<int> total = GeneratedColumn<int>(
    'total',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _progressPercentMeta = const VerificationMeta(
    'progressPercent',
  );
  @override
  late final GeneratedColumn<double> progressPercent = GeneratedColumn<double>(
    'progress_percent',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _summaryJsonMeta = const VerificationMeta(
    'summaryJson',
  );
  @override
  late final GeneratedColumn<String> summaryJson = GeneratedColumn<String>(
    'summary_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _credentialChangesJsonMeta =
      const VerificationMeta('credentialChangesJson');
  @override
  late final GeneratedColumn<String> credentialChangesJson =
      GeneratedColumn<String>(
        'credential_changes_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _refreshStatsJsonMeta = const VerificationMeta(
    'refreshStatsJson',
  );
  @override
  late final GeneratedColumn<String> refreshStatsJson = GeneratedColumn<String>(
    'refresh_stats_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    status,
    message,
    processed,
    total,
    progressPercent,
    summaryJson,
    credentialChangesJson,
    refreshStatsJson,
    createdAt,
    updatedAt,
    completedAt,
    deviceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'get_token_collection_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<GetTokenCollectionStateRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('message')) {
      context.handle(
        _messageMeta,
        message.isAcceptableOrUnknown(data['message']!, _messageMeta),
      );
    } else if (isInserting) {
      context.missing(_messageMeta);
    }
    if (data.containsKey('processed')) {
      context.handle(
        _processedMeta,
        processed.isAcceptableOrUnknown(data['processed']!, _processedMeta),
      );
    } else if (isInserting) {
      context.missing(_processedMeta);
    }
    if (data.containsKey('total')) {
      context.handle(
        _totalMeta,
        total.isAcceptableOrUnknown(data['total']!, _totalMeta),
      );
    } else if (isInserting) {
      context.missing(_totalMeta);
    }
    if (data.containsKey('progress_percent')) {
      context.handle(
        _progressPercentMeta,
        progressPercent.isAcceptableOrUnknown(
          data['progress_percent']!,
          _progressPercentMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_progressPercentMeta);
    }
    if (data.containsKey('summary_json')) {
      context.handle(
        _summaryJsonMeta,
        summaryJson.isAcceptableOrUnknown(
          data['summary_json']!,
          _summaryJsonMeta,
        ),
      );
    }
    if (data.containsKey('credential_changes_json')) {
      context.handle(
        _credentialChangesJsonMeta,
        credentialChangesJson.isAcceptableOrUnknown(
          data['credential_changes_json']!,
          _credentialChangesJsonMeta,
        ),
      );
    }
    if (data.containsKey('refresh_stats_json')) {
      context.handle(
        _refreshStatsJsonMeta,
        refreshStatsJson.isAcceptableOrUnknown(
          data['refresh_stats_json']!,
          _refreshStatsJsonMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GetTokenCollectionStateRecord map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GetTokenCollectionStateRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      message: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message'],
      )!,
      processed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}processed'],
      )!,
      total: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total'],
      )!,
      progressPercent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}progress_percent'],
      )!,
      summaryJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary_json'],
      ),
      credentialChangesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}credential_changes_json'],
      ),
      refreshStatsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}refresh_stats_json'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
    );
  }

  @override
  $GetTokenCollectionStateRecordsTable createAlias(String alias) {
    return $GetTokenCollectionStateRecordsTable(attachedDatabase, alias);
  }
}

class GetTokenCollectionStateRecord extends DataClass
    implements Insertable<GetTokenCollectionStateRecord> {
  final String id;
  final String status;
  final String message;
  final int processed;
  final int total;
  final double progressPercent;
  final String? summaryJson;
  final String? credentialChangesJson;
  final String? refreshStatsJson;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final String deviceId;
  const GetTokenCollectionStateRecord({
    required this.id,
    required this.status,
    required this.message,
    required this.processed,
    required this.total,
    required this.progressPercent,
    this.summaryJson,
    this.credentialChangesJson,
    this.refreshStatsJson,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    required this.deviceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['status'] = Variable<String>(status);
    map['message'] = Variable<String>(message);
    map['processed'] = Variable<int>(processed);
    map['total'] = Variable<int>(total);
    map['progress_percent'] = Variable<double>(progressPercent);
    if (!nullToAbsent || summaryJson != null) {
      map['summary_json'] = Variable<String>(summaryJson);
    }
    if (!nullToAbsent || credentialChangesJson != null) {
      map['credential_changes_json'] = Variable<String>(credentialChangesJson);
    }
    if (!nullToAbsent || refreshStatsJson != null) {
      map['refresh_stats_json'] = Variable<String>(refreshStatsJson);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    map['device_id'] = Variable<String>(deviceId);
    return map;
  }

  GetTokenCollectionStateRecordsCompanion toCompanion(bool nullToAbsent) {
    return GetTokenCollectionStateRecordsCompanion(
      id: Value(id),
      status: Value(status),
      message: Value(message),
      processed: Value(processed),
      total: Value(total),
      progressPercent: Value(progressPercent),
      summaryJson: summaryJson == null && nullToAbsent
          ? const Value.absent()
          : Value(summaryJson),
      credentialChangesJson: credentialChangesJson == null && nullToAbsent
          ? const Value.absent()
          : Value(credentialChangesJson),
      refreshStatsJson: refreshStatsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(refreshStatsJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      deviceId: Value(deviceId),
    );
  }

  factory GetTokenCollectionStateRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GetTokenCollectionStateRecord(
      id: serializer.fromJson<String>(json['id']),
      status: serializer.fromJson<String>(json['status']),
      message: serializer.fromJson<String>(json['message']),
      processed: serializer.fromJson<int>(json['processed']),
      total: serializer.fromJson<int>(json['total']),
      progressPercent: serializer.fromJson<double>(json['progressPercent']),
      summaryJson: serializer.fromJson<String?>(json['summaryJson']),
      credentialChangesJson: serializer.fromJson<String?>(
        json['credentialChangesJson'],
      ),
      refreshStatsJson: serializer.fromJson<String?>(json['refreshStatsJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'status': serializer.toJson<String>(status),
      'message': serializer.toJson<String>(message),
      'processed': serializer.toJson<int>(processed),
      'total': serializer.toJson<int>(total),
      'progressPercent': serializer.toJson<double>(progressPercent),
      'summaryJson': serializer.toJson<String?>(summaryJson),
      'credentialChangesJson': serializer.toJson<String?>(
        credentialChangesJson,
      ),
      'refreshStatsJson': serializer.toJson<String?>(refreshStatsJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'deviceId': serializer.toJson<String>(deviceId),
    };
  }

  GetTokenCollectionStateRecord copyWith({
    String? id,
    String? status,
    String? message,
    int? processed,
    int? total,
    double? progressPercent,
    Value<String?> summaryJson = const Value.absent(),
    Value<String?> credentialChangesJson = const Value.absent(),
    Value<String?> refreshStatsJson = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> completedAt = const Value.absent(),
    String? deviceId,
  }) => GetTokenCollectionStateRecord(
    id: id ?? this.id,
    status: status ?? this.status,
    message: message ?? this.message,
    processed: processed ?? this.processed,
    total: total ?? this.total,
    progressPercent: progressPercent ?? this.progressPercent,
    summaryJson: summaryJson.present ? summaryJson.value : this.summaryJson,
    credentialChangesJson: credentialChangesJson.present
        ? credentialChangesJson.value
        : this.credentialChangesJson,
    refreshStatsJson: refreshStatsJson.present
        ? refreshStatsJson.value
        : this.refreshStatsJson,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    deviceId: deviceId ?? this.deviceId,
  );
  GetTokenCollectionStateRecord copyWithCompanion(
    GetTokenCollectionStateRecordsCompanion data,
  ) {
    return GetTokenCollectionStateRecord(
      id: data.id.present ? data.id.value : this.id,
      status: data.status.present ? data.status.value : this.status,
      message: data.message.present ? data.message.value : this.message,
      processed: data.processed.present ? data.processed.value : this.processed,
      total: data.total.present ? data.total.value : this.total,
      progressPercent: data.progressPercent.present
          ? data.progressPercent.value
          : this.progressPercent,
      summaryJson: data.summaryJson.present
          ? data.summaryJson.value
          : this.summaryJson,
      credentialChangesJson: data.credentialChangesJson.present
          ? data.credentialChangesJson.value
          : this.credentialChangesJson,
      refreshStatsJson: data.refreshStatsJson.present
          ? data.refreshStatsJson.value
          : this.refreshStatsJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GetTokenCollectionStateRecord(')
          ..write('id: $id, ')
          ..write('status: $status, ')
          ..write('message: $message, ')
          ..write('processed: $processed, ')
          ..write('total: $total, ')
          ..write('progressPercent: $progressPercent, ')
          ..write('summaryJson: $summaryJson, ')
          ..write('credentialChangesJson: $credentialChangesJson, ')
          ..write('refreshStatsJson: $refreshStatsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('deviceId: $deviceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    status,
    message,
    processed,
    total,
    progressPercent,
    summaryJson,
    credentialChangesJson,
    refreshStatsJson,
    createdAt,
    updatedAt,
    completedAt,
    deviceId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GetTokenCollectionStateRecord &&
          other.id == this.id &&
          other.status == this.status &&
          other.message == this.message &&
          other.processed == this.processed &&
          other.total == this.total &&
          other.progressPercent == this.progressPercent &&
          other.summaryJson == this.summaryJson &&
          other.credentialChangesJson == this.credentialChangesJson &&
          other.refreshStatsJson == this.refreshStatsJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.completedAt == this.completedAt &&
          other.deviceId == this.deviceId);
}

class GetTokenCollectionStateRecordsCompanion
    extends UpdateCompanion<GetTokenCollectionStateRecord> {
  final Value<String> id;
  final Value<String> status;
  final Value<String> message;
  final Value<int> processed;
  final Value<int> total;
  final Value<double> progressPercent;
  final Value<String?> summaryJson;
  final Value<String?> credentialChangesJson;
  final Value<String?> refreshStatsJson;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> completedAt;
  final Value<String> deviceId;
  final Value<int> rowid;
  const GetTokenCollectionStateRecordsCompanion({
    this.id = const Value.absent(),
    this.status = const Value.absent(),
    this.message = const Value.absent(),
    this.processed = const Value.absent(),
    this.total = const Value.absent(),
    this.progressPercent = const Value.absent(),
    this.summaryJson = const Value.absent(),
    this.credentialChangesJson = const Value.absent(),
    this.refreshStatsJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GetTokenCollectionStateRecordsCompanion.insert({
    required String id,
    required String status,
    required String message,
    required int processed,
    required int total,
    required double progressPercent,
    this.summaryJson = const Value.absent(),
    this.credentialChangesJson = const Value.absent(),
    this.refreshStatsJson = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.completedAt = const Value.absent(),
    required String deviceId,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       status = Value(status),
       message = Value(message),
       processed = Value(processed),
       total = Value(total),
       progressPercent = Value(progressPercent),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       deviceId = Value(deviceId);
  static Insertable<GetTokenCollectionStateRecord> custom({
    Expression<String>? id,
    Expression<String>? status,
    Expression<String>? message,
    Expression<int>? processed,
    Expression<int>? total,
    Expression<double>? progressPercent,
    Expression<String>? summaryJson,
    Expression<String>? credentialChangesJson,
    Expression<String>? refreshStatsJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? completedAt,
    Expression<String>? deviceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (status != null) 'status': status,
      if (message != null) 'message': message,
      if (processed != null) 'processed': processed,
      if (total != null) 'total': total,
      if (progressPercent != null) 'progress_percent': progressPercent,
      if (summaryJson != null) 'summary_json': summaryJson,
      if (credentialChangesJson != null)
        'credential_changes_json': credentialChangesJson,
      if (refreshStatsJson != null) 'refresh_stats_json': refreshStatsJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GetTokenCollectionStateRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? status,
    Value<String>? message,
    Value<int>? processed,
    Value<int>? total,
    Value<double>? progressPercent,
    Value<String?>? summaryJson,
    Value<String?>? credentialChangesJson,
    Value<String?>? refreshStatsJson,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? completedAt,
    Value<String>? deviceId,
    Value<int>? rowid,
  }) {
    return GetTokenCollectionStateRecordsCompanion(
      id: id ?? this.id,
      status: status ?? this.status,
      message: message ?? this.message,
      processed: processed ?? this.processed,
      total: total ?? this.total,
      progressPercent: progressPercent ?? this.progressPercent,
      summaryJson: summaryJson ?? this.summaryJson,
      credentialChangesJson:
          credentialChangesJson ?? this.credentialChangesJson,
      refreshStatsJson: refreshStatsJson ?? this.refreshStatsJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      deviceId: deviceId ?? this.deviceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (processed.present) {
      map['processed'] = Variable<int>(processed.value);
    }
    if (total.present) {
      map['total'] = Variable<int>(total.value);
    }
    if (progressPercent.present) {
      map['progress_percent'] = Variable<double>(progressPercent.value);
    }
    if (summaryJson.present) {
      map['summary_json'] = Variable<String>(summaryJson.value);
    }
    if (credentialChangesJson.present) {
      map['credential_changes_json'] = Variable<String>(
        credentialChangesJson.value,
      );
    }
    if (refreshStatsJson.present) {
      map['refresh_stats_json'] = Variable<String>(refreshStatsJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GetTokenCollectionStateRecordsCompanion(')
          ..write('id: $id, ')
          ..write('status: $status, ')
          ..write('message: $message, ')
          ..write('processed: $processed, ')
          ..write('total: $total, ')
          ..write('progressPercent: $progressPercent, ')
          ..write('summaryJson: $summaryJson, ')
          ..write('credentialChangesJson: $credentialChangesJson, ')
          ..write('refreshStatsJson: $refreshStatsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GetTokenUsageEventRecordsTable extends GetTokenUsageEventRecords
    with TableInfo<$GetTokenUsageEventRecordsTable, GetTokenUsageEventRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GetTokenUsageEventRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authIndexMeta = const VerificationMeta(
    'authIndex',
  );
  @override
  late final GeneratedColumn<String> authIndex = GeneratedColumn<String>(
    'auth_index',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceTypeMeta = const VerificationMeta(
    'sourceType',
  );
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
    'source_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _failedMeta = const VerificationMeta('failed');
  @override
  late final GeneratedColumn<bool> failed = GeneratedColumn<bool>(
    'failed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("failed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inputTokensMeta = const VerificationMeta(
    'inputTokens',
  );
  @override
  late final GeneratedColumn<int> inputTokens = GeneratedColumn<int>(
    'input_tokens',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _outputTokensMeta = const VerificationMeta(
    'outputTokens',
  );
  @override
  late final GeneratedColumn<int> outputTokens = GeneratedColumn<int>(
    'output_tokens',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _reasoningTokensMeta = const VerificationMeta(
    'reasoningTokens',
  );
  @override
  late final GeneratedColumn<int> reasoningTokens = GeneratedColumn<int>(
    'reasoning_tokens',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _cachedTokensMeta = const VerificationMeta(
    'cachedTokens',
  );
  @override
  late final GeneratedColumn<int> cachedTokens = GeneratedColumn<int>(
    'cached_tokens',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalTokensMeta = const VerificationMeta(
    'totalTokens',
  );
  @override
  late final GeneratedColumn<int> totalTokens = GeneratedColumn<int>(
    'total_tokens',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _rawJsonMeta = const VerificationMeta(
    'rawJson',
  );
  @override
  late final GeneratedColumn<String> rawJson = GeneratedColumn<String>(
    'raw_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    authIndex,
    source,
    sourceType,
    failed,
    model,
    timestamp,
    inputTokens,
    outputTokens,
    reasoningTokens,
    cachedTokens,
    totalTokens,
    rawJson,
    updatedAt,
    deviceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'get_token_usage_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<GetTokenUsageEventRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('auth_index')) {
      context.handle(
        _authIndexMeta,
        authIndex.isAcceptableOrUnknown(data['auth_index']!, _authIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_authIndexMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('source_type')) {
      context.handle(
        _sourceTypeMeta,
        sourceType.isAcceptableOrUnknown(data['source_type']!, _sourceTypeMeta),
      );
    }
    if (data.containsKey('failed')) {
      context.handle(
        _failedMeta,
        failed.isAcceptableOrUnknown(data['failed']!, _failedMeta),
      );
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('input_tokens')) {
      context.handle(
        _inputTokensMeta,
        inputTokens.isAcceptableOrUnknown(
          data['input_tokens']!,
          _inputTokensMeta,
        ),
      );
    }
    if (data.containsKey('output_tokens')) {
      context.handle(
        _outputTokensMeta,
        outputTokens.isAcceptableOrUnknown(
          data['output_tokens']!,
          _outputTokensMeta,
        ),
      );
    }
    if (data.containsKey('reasoning_tokens')) {
      context.handle(
        _reasoningTokensMeta,
        reasoningTokens.isAcceptableOrUnknown(
          data['reasoning_tokens']!,
          _reasoningTokensMeta,
        ),
      );
    }
    if (data.containsKey('cached_tokens')) {
      context.handle(
        _cachedTokensMeta,
        cachedTokens.isAcceptableOrUnknown(
          data['cached_tokens']!,
          _cachedTokensMeta,
        ),
      );
    }
    if (data.containsKey('total_tokens')) {
      context.handle(
        _totalTokensMeta,
        totalTokens.isAcceptableOrUnknown(
          data['total_tokens']!,
          _totalTokensMeta,
        ),
      );
    }
    if (data.containsKey('raw_json')) {
      context.handle(
        _rawJsonMeta,
        rawJson.isAcceptableOrUnknown(data['raw_json']!, _rawJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_rawJsonMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GetTokenUsageEventRecord map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GetTokenUsageEventRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      authIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}auth_index'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      sourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_type'],
      ),
      failed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}failed'],
      )!,
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      ),
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      inputTokens: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}input_tokens'],
      )!,
      outputTokens: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}output_tokens'],
      )!,
      reasoningTokens: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reasoning_tokens'],
      )!,
      cachedTokens: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cached_tokens'],
      )!,
      totalTokens: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_tokens'],
      )!,
      rawJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_json'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
    );
  }

  @override
  $GetTokenUsageEventRecordsTable createAlias(String alias) {
    return $GetTokenUsageEventRecordsTable(attachedDatabase, alias);
  }
}

class GetTokenUsageEventRecord extends DataClass
    implements Insertable<GetTokenUsageEventRecord> {
  final String id;
  final String authIndex;
  final String source;
  final String? sourceType;
  final bool failed;
  final String? model;
  final DateTime timestamp;
  final int inputTokens;
  final int outputTokens;
  final int reasoningTokens;
  final int cachedTokens;
  final int totalTokens;
  final String rawJson;
  final DateTime updatedAt;
  final String deviceId;
  const GetTokenUsageEventRecord({
    required this.id,
    required this.authIndex,
    required this.source,
    this.sourceType,
    required this.failed,
    this.model,
    required this.timestamp,
    required this.inputTokens,
    required this.outputTokens,
    required this.reasoningTokens,
    required this.cachedTokens,
    required this.totalTokens,
    required this.rawJson,
    required this.updatedAt,
    required this.deviceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['auth_index'] = Variable<String>(authIndex);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || sourceType != null) {
      map['source_type'] = Variable<String>(sourceType);
    }
    map['failed'] = Variable<bool>(failed);
    if (!nullToAbsent || model != null) {
      map['model'] = Variable<String>(model);
    }
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['input_tokens'] = Variable<int>(inputTokens);
    map['output_tokens'] = Variable<int>(outputTokens);
    map['reasoning_tokens'] = Variable<int>(reasoningTokens);
    map['cached_tokens'] = Variable<int>(cachedTokens);
    map['total_tokens'] = Variable<int>(totalTokens);
    map['raw_json'] = Variable<String>(rawJson);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['device_id'] = Variable<String>(deviceId);
    return map;
  }

  GetTokenUsageEventRecordsCompanion toCompanion(bool nullToAbsent) {
    return GetTokenUsageEventRecordsCompanion(
      id: Value(id),
      authIndex: Value(authIndex),
      source: Value(source),
      sourceType: sourceType == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceType),
      failed: Value(failed),
      model: model == null && nullToAbsent
          ? const Value.absent()
          : Value(model),
      timestamp: Value(timestamp),
      inputTokens: Value(inputTokens),
      outputTokens: Value(outputTokens),
      reasoningTokens: Value(reasoningTokens),
      cachedTokens: Value(cachedTokens),
      totalTokens: Value(totalTokens),
      rawJson: Value(rawJson),
      updatedAt: Value(updatedAt),
      deviceId: Value(deviceId),
    );
  }

  factory GetTokenUsageEventRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GetTokenUsageEventRecord(
      id: serializer.fromJson<String>(json['id']),
      authIndex: serializer.fromJson<String>(json['authIndex']),
      source: serializer.fromJson<String>(json['source']),
      sourceType: serializer.fromJson<String?>(json['sourceType']),
      failed: serializer.fromJson<bool>(json['failed']),
      model: serializer.fromJson<String?>(json['model']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      inputTokens: serializer.fromJson<int>(json['inputTokens']),
      outputTokens: serializer.fromJson<int>(json['outputTokens']),
      reasoningTokens: serializer.fromJson<int>(json['reasoningTokens']),
      cachedTokens: serializer.fromJson<int>(json['cachedTokens']),
      totalTokens: serializer.fromJson<int>(json['totalTokens']),
      rawJson: serializer.fromJson<String>(json['rawJson']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'authIndex': serializer.toJson<String>(authIndex),
      'source': serializer.toJson<String>(source),
      'sourceType': serializer.toJson<String?>(sourceType),
      'failed': serializer.toJson<bool>(failed),
      'model': serializer.toJson<String?>(model),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'inputTokens': serializer.toJson<int>(inputTokens),
      'outputTokens': serializer.toJson<int>(outputTokens),
      'reasoningTokens': serializer.toJson<int>(reasoningTokens),
      'cachedTokens': serializer.toJson<int>(cachedTokens),
      'totalTokens': serializer.toJson<int>(totalTokens),
      'rawJson': serializer.toJson<String>(rawJson),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deviceId': serializer.toJson<String>(deviceId),
    };
  }

  GetTokenUsageEventRecord copyWith({
    String? id,
    String? authIndex,
    String? source,
    Value<String?> sourceType = const Value.absent(),
    bool? failed,
    Value<String?> model = const Value.absent(),
    DateTime? timestamp,
    int? inputTokens,
    int? outputTokens,
    int? reasoningTokens,
    int? cachedTokens,
    int? totalTokens,
    String? rawJson,
    DateTime? updatedAt,
    String? deviceId,
  }) => GetTokenUsageEventRecord(
    id: id ?? this.id,
    authIndex: authIndex ?? this.authIndex,
    source: source ?? this.source,
    sourceType: sourceType.present ? sourceType.value : this.sourceType,
    failed: failed ?? this.failed,
    model: model.present ? model.value : this.model,
    timestamp: timestamp ?? this.timestamp,
    inputTokens: inputTokens ?? this.inputTokens,
    outputTokens: outputTokens ?? this.outputTokens,
    reasoningTokens: reasoningTokens ?? this.reasoningTokens,
    cachedTokens: cachedTokens ?? this.cachedTokens,
    totalTokens: totalTokens ?? this.totalTokens,
    rawJson: rawJson ?? this.rawJson,
    updatedAt: updatedAt ?? this.updatedAt,
    deviceId: deviceId ?? this.deviceId,
  );
  GetTokenUsageEventRecord copyWithCompanion(
    GetTokenUsageEventRecordsCompanion data,
  ) {
    return GetTokenUsageEventRecord(
      id: data.id.present ? data.id.value : this.id,
      authIndex: data.authIndex.present ? data.authIndex.value : this.authIndex,
      source: data.source.present ? data.source.value : this.source,
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      failed: data.failed.present ? data.failed.value : this.failed,
      model: data.model.present ? data.model.value : this.model,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      inputTokens: data.inputTokens.present
          ? data.inputTokens.value
          : this.inputTokens,
      outputTokens: data.outputTokens.present
          ? data.outputTokens.value
          : this.outputTokens,
      reasoningTokens: data.reasoningTokens.present
          ? data.reasoningTokens.value
          : this.reasoningTokens,
      cachedTokens: data.cachedTokens.present
          ? data.cachedTokens.value
          : this.cachedTokens,
      totalTokens: data.totalTokens.present
          ? data.totalTokens.value
          : this.totalTokens,
      rawJson: data.rawJson.present ? data.rawJson.value : this.rawJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GetTokenUsageEventRecord(')
          ..write('id: $id, ')
          ..write('authIndex: $authIndex, ')
          ..write('source: $source, ')
          ..write('sourceType: $sourceType, ')
          ..write('failed: $failed, ')
          ..write('model: $model, ')
          ..write('timestamp: $timestamp, ')
          ..write('inputTokens: $inputTokens, ')
          ..write('outputTokens: $outputTokens, ')
          ..write('reasoningTokens: $reasoningTokens, ')
          ..write('cachedTokens: $cachedTokens, ')
          ..write('totalTokens: $totalTokens, ')
          ..write('rawJson: $rawJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deviceId: $deviceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    authIndex,
    source,
    sourceType,
    failed,
    model,
    timestamp,
    inputTokens,
    outputTokens,
    reasoningTokens,
    cachedTokens,
    totalTokens,
    rawJson,
    updatedAt,
    deviceId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GetTokenUsageEventRecord &&
          other.id == this.id &&
          other.authIndex == this.authIndex &&
          other.source == this.source &&
          other.sourceType == this.sourceType &&
          other.failed == this.failed &&
          other.model == this.model &&
          other.timestamp == this.timestamp &&
          other.inputTokens == this.inputTokens &&
          other.outputTokens == this.outputTokens &&
          other.reasoningTokens == this.reasoningTokens &&
          other.cachedTokens == this.cachedTokens &&
          other.totalTokens == this.totalTokens &&
          other.rawJson == this.rawJson &&
          other.updatedAt == this.updatedAt &&
          other.deviceId == this.deviceId);
}

class GetTokenUsageEventRecordsCompanion
    extends UpdateCompanion<GetTokenUsageEventRecord> {
  final Value<String> id;
  final Value<String> authIndex;
  final Value<String> source;
  final Value<String?> sourceType;
  final Value<bool> failed;
  final Value<String?> model;
  final Value<DateTime> timestamp;
  final Value<int> inputTokens;
  final Value<int> outputTokens;
  final Value<int> reasoningTokens;
  final Value<int> cachedTokens;
  final Value<int> totalTokens;
  final Value<String> rawJson;
  final Value<DateTime> updatedAt;
  final Value<String> deviceId;
  final Value<int> rowid;
  const GetTokenUsageEventRecordsCompanion({
    this.id = const Value.absent(),
    this.authIndex = const Value.absent(),
    this.source = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.failed = const Value.absent(),
    this.model = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.inputTokens = const Value.absent(),
    this.outputTokens = const Value.absent(),
    this.reasoningTokens = const Value.absent(),
    this.cachedTokens = const Value.absent(),
    this.totalTokens = const Value.absent(),
    this.rawJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GetTokenUsageEventRecordsCompanion.insert({
    required String id,
    required String authIndex,
    required String source,
    this.sourceType = const Value.absent(),
    this.failed = const Value.absent(),
    this.model = const Value.absent(),
    required DateTime timestamp,
    this.inputTokens = const Value.absent(),
    this.outputTokens = const Value.absent(),
    this.reasoningTokens = const Value.absent(),
    this.cachedTokens = const Value.absent(),
    this.totalTokens = const Value.absent(),
    required String rawJson,
    required DateTime updatedAt,
    required String deviceId,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       authIndex = Value(authIndex),
       source = Value(source),
       timestamp = Value(timestamp),
       rawJson = Value(rawJson),
       updatedAt = Value(updatedAt),
       deviceId = Value(deviceId);
  static Insertable<GetTokenUsageEventRecord> custom({
    Expression<String>? id,
    Expression<String>? authIndex,
    Expression<String>? source,
    Expression<String>? sourceType,
    Expression<bool>? failed,
    Expression<String>? model,
    Expression<DateTime>? timestamp,
    Expression<int>? inputTokens,
    Expression<int>? outputTokens,
    Expression<int>? reasoningTokens,
    Expression<int>? cachedTokens,
    Expression<int>? totalTokens,
    Expression<String>? rawJson,
    Expression<DateTime>? updatedAt,
    Expression<String>? deviceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (authIndex != null) 'auth_index': authIndex,
      if (source != null) 'source': source,
      if (sourceType != null) 'source_type': sourceType,
      if (failed != null) 'failed': failed,
      if (model != null) 'model': model,
      if (timestamp != null) 'timestamp': timestamp,
      if (inputTokens != null) 'input_tokens': inputTokens,
      if (outputTokens != null) 'output_tokens': outputTokens,
      if (reasoningTokens != null) 'reasoning_tokens': reasoningTokens,
      if (cachedTokens != null) 'cached_tokens': cachedTokens,
      if (totalTokens != null) 'total_tokens': totalTokens,
      if (rawJson != null) 'raw_json': rawJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GetTokenUsageEventRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? authIndex,
    Value<String>? source,
    Value<String?>? sourceType,
    Value<bool>? failed,
    Value<String?>? model,
    Value<DateTime>? timestamp,
    Value<int>? inputTokens,
    Value<int>? outputTokens,
    Value<int>? reasoningTokens,
    Value<int>? cachedTokens,
    Value<int>? totalTokens,
    Value<String>? rawJson,
    Value<DateTime>? updatedAt,
    Value<String>? deviceId,
    Value<int>? rowid,
  }) {
    return GetTokenUsageEventRecordsCompanion(
      id: id ?? this.id,
      authIndex: authIndex ?? this.authIndex,
      source: source ?? this.source,
      sourceType: sourceType ?? this.sourceType,
      failed: failed ?? this.failed,
      model: model ?? this.model,
      timestamp: timestamp ?? this.timestamp,
      inputTokens: inputTokens ?? this.inputTokens,
      outputTokens: outputTokens ?? this.outputTokens,
      reasoningTokens: reasoningTokens ?? this.reasoningTokens,
      cachedTokens: cachedTokens ?? this.cachedTokens,
      totalTokens: totalTokens ?? this.totalTokens,
      rawJson: rawJson ?? this.rawJson,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (authIndex.present) {
      map['auth_index'] = Variable<String>(authIndex.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (failed.present) {
      map['failed'] = Variable<bool>(failed.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (inputTokens.present) {
      map['input_tokens'] = Variable<int>(inputTokens.value);
    }
    if (outputTokens.present) {
      map['output_tokens'] = Variable<int>(outputTokens.value);
    }
    if (reasoningTokens.present) {
      map['reasoning_tokens'] = Variable<int>(reasoningTokens.value);
    }
    if (cachedTokens.present) {
      map['cached_tokens'] = Variable<int>(cachedTokens.value);
    }
    if (totalTokens.present) {
      map['total_tokens'] = Variable<int>(totalTokens.value);
    }
    if (rawJson.present) {
      map['raw_json'] = Variable<String>(rawJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GetTokenUsageEventRecordsCompanion(')
          ..write('id: $id, ')
          ..write('authIndex: $authIndex, ')
          ..write('source: $source, ')
          ..write('sourceType: $sourceType, ')
          ..write('failed: $failed, ')
          ..write('model: $model, ')
          ..write('timestamp: $timestamp, ')
          ..write('inputTokens: $inputTokens, ')
          ..write('outputTokens: $outputTokens, ')
          ..write('reasoningTokens: $reasoningTokens, ')
          ..write('cachedTokens: $cachedTokens, ')
          ..write('totalTokens: $totalTokens, ')
          ..write('rawJson: $rawJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GetTokenUsageQueryStateRecordsTable
    extends GetTokenUsageQueryStateRecords
    with
        TableInfo<
          $GetTokenUsageQueryStateRecordsTable,
          GetTokenUsageQueryStateRecord
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GetTokenUsageQueryStateRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paramsJsonMeta = const VerificationMeta(
    'paramsJson',
  );
  @override
  late final GeneratedColumn<String> paramsJson = GeneratedColumn<String>(
    'params_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _summaryJsonMeta = const VerificationMeta(
    'summaryJson',
  );
  @override
  late final GeneratedColumn<String> summaryJson = GeneratedColumn<String>(
    'summary_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _upstreamJsonMeta = const VerificationMeta(
    'upstreamJson',
  );
  @override
  late final GeneratedColumn<String> upstreamJson = GeneratedColumn<String>(
    'upstream_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rowsJsonMeta = const VerificationMeta(
    'rowsJson',
  );
  @override
  late final GeneratedColumn<String> rowsJson = GeneratedColumn<String>(
    'rows_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventTableCountMeta = const VerificationMeta(
    'eventTableCount',
  );
  @override
  late final GeneratedColumn<int> eventTableCount = GeneratedColumn<int>(
    'event_table_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addedEventCountMeta = const VerificationMeta(
    'addedEventCount',
  );
  @override
  late final GeneratedColumn<int> addedEventCount = GeneratedColumn<int>(
    'added_event_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    paramsJson,
    summaryJson,
    upstreamJson,
    rowsJson,
    eventTableCount,
    addedEventCount,
    updatedAt,
    deviceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'get_token_usage_query_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<GetTokenUsageQueryStateRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('params_json')) {
      context.handle(
        _paramsJsonMeta,
        paramsJson.isAcceptableOrUnknown(data['params_json']!, _paramsJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_paramsJsonMeta);
    }
    if (data.containsKey('summary_json')) {
      context.handle(
        _summaryJsonMeta,
        summaryJson.isAcceptableOrUnknown(
          data['summary_json']!,
          _summaryJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_summaryJsonMeta);
    }
    if (data.containsKey('upstream_json')) {
      context.handle(
        _upstreamJsonMeta,
        upstreamJson.isAcceptableOrUnknown(
          data['upstream_json']!,
          _upstreamJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_upstreamJsonMeta);
    }
    if (data.containsKey('rows_json')) {
      context.handle(
        _rowsJsonMeta,
        rowsJson.isAcceptableOrUnknown(data['rows_json']!, _rowsJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_rowsJsonMeta);
    }
    if (data.containsKey('event_table_count')) {
      context.handle(
        _eventTableCountMeta,
        eventTableCount.isAcceptableOrUnknown(
          data['event_table_count']!,
          _eventTableCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_eventTableCountMeta);
    }
    if (data.containsKey('added_event_count')) {
      context.handle(
        _addedEventCountMeta,
        addedEventCount.isAcceptableOrUnknown(
          data['added_event_count']!,
          _addedEventCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_addedEventCountMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GetTokenUsageQueryStateRecord map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GetTokenUsageQueryStateRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      paramsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}params_json'],
      )!,
      summaryJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary_json'],
      )!,
      upstreamJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}upstream_json'],
      )!,
      rowsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rows_json'],
      )!,
      eventTableCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}event_table_count'],
      )!,
      addedEventCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}added_event_count'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
    );
  }

  @override
  $GetTokenUsageQueryStateRecordsTable createAlias(String alias) {
    return $GetTokenUsageQueryStateRecordsTable(attachedDatabase, alias);
  }
}

class GetTokenUsageQueryStateRecord extends DataClass
    implements Insertable<GetTokenUsageQueryStateRecord> {
  final String id;
  final String paramsJson;
  final String summaryJson;
  final String upstreamJson;
  final String rowsJson;
  final int eventTableCount;
  final int addedEventCount;
  final DateTime updatedAt;
  final String deviceId;
  const GetTokenUsageQueryStateRecord({
    required this.id,
    required this.paramsJson,
    required this.summaryJson,
    required this.upstreamJson,
    required this.rowsJson,
    required this.eventTableCount,
    required this.addedEventCount,
    required this.updatedAt,
    required this.deviceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['params_json'] = Variable<String>(paramsJson);
    map['summary_json'] = Variable<String>(summaryJson);
    map['upstream_json'] = Variable<String>(upstreamJson);
    map['rows_json'] = Variable<String>(rowsJson);
    map['event_table_count'] = Variable<int>(eventTableCount);
    map['added_event_count'] = Variable<int>(addedEventCount);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['device_id'] = Variable<String>(deviceId);
    return map;
  }

  GetTokenUsageQueryStateRecordsCompanion toCompanion(bool nullToAbsent) {
    return GetTokenUsageQueryStateRecordsCompanion(
      id: Value(id),
      paramsJson: Value(paramsJson),
      summaryJson: Value(summaryJson),
      upstreamJson: Value(upstreamJson),
      rowsJson: Value(rowsJson),
      eventTableCount: Value(eventTableCount),
      addedEventCount: Value(addedEventCount),
      updatedAt: Value(updatedAt),
      deviceId: Value(deviceId),
    );
  }

  factory GetTokenUsageQueryStateRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GetTokenUsageQueryStateRecord(
      id: serializer.fromJson<String>(json['id']),
      paramsJson: serializer.fromJson<String>(json['paramsJson']),
      summaryJson: serializer.fromJson<String>(json['summaryJson']),
      upstreamJson: serializer.fromJson<String>(json['upstreamJson']),
      rowsJson: serializer.fromJson<String>(json['rowsJson']),
      eventTableCount: serializer.fromJson<int>(json['eventTableCount']),
      addedEventCount: serializer.fromJson<int>(json['addedEventCount']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'paramsJson': serializer.toJson<String>(paramsJson),
      'summaryJson': serializer.toJson<String>(summaryJson),
      'upstreamJson': serializer.toJson<String>(upstreamJson),
      'rowsJson': serializer.toJson<String>(rowsJson),
      'eventTableCount': serializer.toJson<int>(eventTableCount),
      'addedEventCount': serializer.toJson<int>(addedEventCount),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deviceId': serializer.toJson<String>(deviceId),
    };
  }

  GetTokenUsageQueryStateRecord copyWith({
    String? id,
    String? paramsJson,
    String? summaryJson,
    String? upstreamJson,
    String? rowsJson,
    int? eventTableCount,
    int? addedEventCount,
    DateTime? updatedAt,
    String? deviceId,
  }) => GetTokenUsageQueryStateRecord(
    id: id ?? this.id,
    paramsJson: paramsJson ?? this.paramsJson,
    summaryJson: summaryJson ?? this.summaryJson,
    upstreamJson: upstreamJson ?? this.upstreamJson,
    rowsJson: rowsJson ?? this.rowsJson,
    eventTableCount: eventTableCount ?? this.eventTableCount,
    addedEventCount: addedEventCount ?? this.addedEventCount,
    updatedAt: updatedAt ?? this.updatedAt,
    deviceId: deviceId ?? this.deviceId,
  );
  GetTokenUsageQueryStateRecord copyWithCompanion(
    GetTokenUsageQueryStateRecordsCompanion data,
  ) {
    return GetTokenUsageQueryStateRecord(
      id: data.id.present ? data.id.value : this.id,
      paramsJson: data.paramsJson.present
          ? data.paramsJson.value
          : this.paramsJson,
      summaryJson: data.summaryJson.present
          ? data.summaryJson.value
          : this.summaryJson,
      upstreamJson: data.upstreamJson.present
          ? data.upstreamJson.value
          : this.upstreamJson,
      rowsJson: data.rowsJson.present ? data.rowsJson.value : this.rowsJson,
      eventTableCount: data.eventTableCount.present
          ? data.eventTableCount.value
          : this.eventTableCount,
      addedEventCount: data.addedEventCount.present
          ? data.addedEventCount.value
          : this.addedEventCount,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GetTokenUsageQueryStateRecord(')
          ..write('id: $id, ')
          ..write('paramsJson: $paramsJson, ')
          ..write('summaryJson: $summaryJson, ')
          ..write('upstreamJson: $upstreamJson, ')
          ..write('rowsJson: $rowsJson, ')
          ..write('eventTableCount: $eventTableCount, ')
          ..write('addedEventCount: $addedEventCount, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deviceId: $deviceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    paramsJson,
    summaryJson,
    upstreamJson,
    rowsJson,
    eventTableCount,
    addedEventCount,
    updatedAt,
    deviceId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GetTokenUsageQueryStateRecord &&
          other.id == this.id &&
          other.paramsJson == this.paramsJson &&
          other.summaryJson == this.summaryJson &&
          other.upstreamJson == this.upstreamJson &&
          other.rowsJson == this.rowsJson &&
          other.eventTableCount == this.eventTableCount &&
          other.addedEventCount == this.addedEventCount &&
          other.updatedAt == this.updatedAt &&
          other.deviceId == this.deviceId);
}

class GetTokenUsageQueryStateRecordsCompanion
    extends UpdateCompanion<GetTokenUsageQueryStateRecord> {
  final Value<String> id;
  final Value<String> paramsJson;
  final Value<String> summaryJson;
  final Value<String> upstreamJson;
  final Value<String> rowsJson;
  final Value<int> eventTableCount;
  final Value<int> addedEventCount;
  final Value<DateTime> updatedAt;
  final Value<String> deviceId;
  final Value<int> rowid;
  const GetTokenUsageQueryStateRecordsCompanion({
    this.id = const Value.absent(),
    this.paramsJson = const Value.absent(),
    this.summaryJson = const Value.absent(),
    this.upstreamJson = const Value.absent(),
    this.rowsJson = const Value.absent(),
    this.eventTableCount = const Value.absent(),
    this.addedEventCount = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GetTokenUsageQueryStateRecordsCompanion.insert({
    required String id,
    required String paramsJson,
    required String summaryJson,
    required String upstreamJson,
    required String rowsJson,
    required int eventTableCount,
    required int addedEventCount,
    required DateTime updatedAt,
    required String deviceId,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       paramsJson = Value(paramsJson),
       summaryJson = Value(summaryJson),
       upstreamJson = Value(upstreamJson),
       rowsJson = Value(rowsJson),
       eventTableCount = Value(eventTableCount),
       addedEventCount = Value(addedEventCount),
       updatedAt = Value(updatedAt),
       deviceId = Value(deviceId);
  static Insertable<GetTokenUsageQueryStateRecord> custom({
    Expression<String>? id,
    Expression<String>? paramsJson,
    Expression<String>? summaryJson,
    Expression<String>? upstreamJson,
    Expression<String>? rowsJson,
    Expression<int>? eventTableCount,
    Expression<int>? addedEventCount,
    Expression<DateTime>? updatedAt,
    Expression<String>? deviceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (paramsJson != null) 'params_json': paramsJson,
      if (summaryJson != null) 'summary_json': summaryJson,
      if (upstreamJson != null) 'upstream_json': upstreamJson,
      if (rowsJson != null) 'rows_json': rowsJson,
      if (eventTableCount != null) 'event_table_count': eventTableCount,
      if (addedEventCount != null) 'added_event_count': addedEventCount,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GetTokenUsageQueryStateRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? paramsJson,
    Value<String>? summaryJson,
    Value<String>? upstreamJson,
    Value<String>? rowsJson,
    Value<int>? eventTableCount,
    Value<int>? addedEventCount,
    Value<DateTime>? updatedAt,
    Value<String>? deviceId,
    Value<int>? rowid,
  }) {
    return GetTokenUsageQueryStateRecordsCompanion(
      id: id ?? this.id,
      paramsJson: paramsJson ?? this.paramsJson,
      summaryJson: summaryJson ?? this.summaryJson,
      upstreamJson: upstreamJson ?? this.upstreamJson,
      rowsJson: rowsJson ?? this.rowsJson,
      eventTableCount: eventTableCount ?? this.eventTableCount,
      addedEventCount: addedEventCount ?? this.addedEventCount,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (paramsJson.present) {
      map['params_json'] = Variable<String>(paramsJson.value);
    }
    if (summaryJson.present) {
      map['summary_json'] = Variable<String>(summaryJson.value);
    }
    if (upstreamJson.present) {
      map['upstream_json'] = Variable<String>(upstreamJson.value);
    }
    if (rowsJson.present) {
      map['rows_json'] = Variable<String>(rowsJson.value);
    }
    if (eventTableCount.present) {
      map['event_table_count'] = Variable<int>(eventTableCount.value);
    }
    if (addedEventCount.present) {
      map['added_event_count'] = Variable<int>(addedEventCount.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GetTokenUsageQueryStateRecordsCompanion(')
          ..write('id: $id, ')
          ..write('paramsJson: $paramsJson, ')
          ..write('summaryJson: $summaryJson, ')
          ..write('upstreamJson: $upstreamJson, ')
          ..write('rowsJson: $rowsJson, ')
          ..write('eventTableCount: $eventTableCount, ')
          ..write('addedEventCount: $addedEventCount, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $NotesTable notes = $NotesTable(this);
  late final $TodosTable todos = $TodosTable(this);
  late final $LedgerEntriesTable ledgerEntries = $LedgerEntriesTable(this);
  late final $CountdownEventsTable countdownEvents = $CountdownEventsTable(
    this,
  );
  late final $PomodoroSessionsTable pomodoroSessions = $PomodoroSessionsTable(
    this,
  );
  late final $PomodoroSettingsTable pomodoroSettings = $PomodoroSettingsTable(
    this,
  );
  late final $SteamStatusPresetRecordsTable steamStatusPresetRecords =
      $SteamStatusPresetRecordsTable(this);
  late final $SteamStatusHistoryRecordsTable steamStatusHistoryRecords =
      $SteamStatusHistoryRecordsTable(this);
  late final $GetTokenCredentialSnapshotRecordsTable
  getTokenCredentialSnapshotRecords = $GetTokenCredentialSnapshotRecordsTable(
    this,
  );
  late final $GetTokenCollectionStateRecordsTable
  getTokenCollectionStateRecords = $GetTokenCollectionStateRecordsTable(this);
  late final $GetTokenUsageEventRecordsTable getTokenUsageEventRecords =
      $GetTokenUsageEventRecordsTable(this);
  late final $GetTokenUsageQueryStateRecordsTable
  getTokenUsageQueryStateRecords = $GetTokenUsageQueryStateRecordsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    appSettings,
    notes,
    todos,
    ledgerEntries,
    countdownEvents,
    pomodoroSessions,
    pomodoroSettings,
    steamStatusPresetRecords,
    steamStatusHistoryRecords,
    getTokenCredentialSnapshotRecords,
    getTokenCollectionStateRecords,
    getTokenUsageEventRecords,
    getTokenUsageQueryStateRecords,
  ];
}

typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String value,
      required DateTime updatedAt,
      required String deviceId,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<DateTime> updatedAt,
      Value<String> deviceId,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion(
                key: key,
                value: value,
                updatedAt: updatedAt,
                deviceId: deviceId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                required DateTime updatedAt,
                required String deviceId,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
                updatedAt: updatedAt,
                deviceId: deviceId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;
typedef $$NotesTableCreateCompanionBuilder =
    NotesCompanion Function({
      required String id,
      required String title,
      required String content,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      required String deviceId,
      Value<int> rowid,
    });
typedef $$NotesTableUpdateCompanionBuilder =
    NotesCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> content,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> deviceId,
      Value<int> rowid,
    });

class $$NotesTableFilterComposer extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NotesTableOrderingComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);
}

class $$NotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotesTable,
          Note,
          $$NotesTableFilterComposer,
          $$NotesTableOrderingComposer,
          $$NotesTableAnnotationComposer,
          $$NotesTableCreateCompanionBuilder,
          $$NotesTableUpdateCompanionBuilder,
          (Note, BaseReferences<_$AppDatabase, $NotesTable, Note>),
          Note,
          PrefetchHooks Function()
        > {
  $$NotesTableTableManager(_$AppDatabase db, $NotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotesCompanion(
                id: id,
                title: title,
                content: content,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String content,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String deviceId,
                Value<int> rowid = const Value.absent(),
              }) => NotesCompanion.insert(
                id: id,
                title: title,
                content: content,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotesTable,
      Note,
      $$NotesTableFilterComposer,
      $$NotesTableOrderingComposer,
      $$NotesTableAnnotationComposer,
      $$NotesTableCreateCompanionBuilder,
      $$NotesTableUpdateCompanionBuilder,
      (Note, BaseReferences<_$AppDatabase, $NotesTable, Note>),
      Note,
      PrefetchHooks Function()
    >;
typedef $$TodosTableCreateCompanionBuilder =
    TodosCompanion Function({
      required String id,
      required String title,
      Value<bool> completed,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      required String deviceId,
      Value<int> rowid,
    });
typedef $$TodosTableUpdateCompanionBuilder =
    TodosCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<bool> completed,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> deviceId,
      Value<int> rowid,
    });

class $$TodosTableFilterComposer extends Composer<_$AppDatabase, $TodosTable> {
  $$TodosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TodosTableOrderingComposer
    extends Composer<_$AppDatabase, $TodosTable> {
  $$TodosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TodosTableAnnotationComposer
    extends Composer<_$AppDatabase, $TodosTable> {
  $$TodosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);
}

class $$TodosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TodosTable,
          Todo,
          $$TodosTableFilterComposer,
          $$TodosTableOrderingComposer,
          $$TodosTableAnnotationComposer,
          $$TodosTableCreateCompanionBuilder,
          $$TodosTableUpdateCompanionBuilder,
          (Todo, BaseReferences<_$AppDatabase, $TodosTable, Todo>),
          Todo,
          PrefetchHooks Function()
        > {
  $$TodosTableTableManager(_$AppDatabase db, $TodosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TodosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TodosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TodosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TodosCompanion(
                id: id,
                title: title,
                completed: completed,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<bool> completed = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String deviceId,
                Value<int> rowid = const Value.absent(),
              }) => TodosCompanion.insert(
                id: id,
                title: title,
                completed: completed,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TodosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TodosTable,
      Todo,
      $$TodosTableFilterComposer,
      $$TodosTableOrderingComposer,
      $$TodosTableAnnotationComposer,
      $$TodosTableCreateCompanionBuilder,
      $$TodosTableUpdateCompanionBuilder,
      (Todo, BaseReferences<_$AppDatabase, $TodosTable, Todo>),
      Todo,
      PrefetchHooks Function()
    >;
typedef $$LedgerEntriesTableCreateCompanionBuilder =
    LedgerEntriesCompanion Function({
      required String id,
      required String type,
      required double amount,
      required String note,
      required DateTime occurredAt,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      required String deviceId,
      Value<int> rowid,
    });
typedef $$LedgerEntriesTableUpdateCompanionBuilder =
    LedgerEntriesCompanion Function({
      Value<String> id,
      Value<String> type,
      Value<double> amount,
      Value<String> note,
      Value<DateTime> occurredAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> deviceId,
      Value<int> rowid,
    });

class $$LedgerEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $LedgerEntriesTable> {
  $$LedgerEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LedgerEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $LedgerEntriesTable> {
  $$LedgerEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LedgerEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LedgerEntriesTable> {
  $$LedgerEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);
}

class $$LedgerEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LedgerEntriesTable,
          LedgerEntry,
          $$LedgerEntriesTableFilterComposer,
          $$LedgerEntriesTableOrderingComposer,
          $$LedgerEntriesTableAnnotationComposer,
          $$LedgerEntriesTableCreateCompanionBuilder,
          $$LedgerEntriesTableUpdateCompanionBuilder,
          (
            LedgerEntry,
            BaseReferences<_$AppDatabase, $LedgerEntriesTable, LedgerEntry>,
          ),
          LedgerEntry,
          PrefetchHooks Function()
        > {
  $$LedgerEntriesTableTableManager(_$AppDatabase db, $LedgerEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LedgerEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LedgerEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LedgerEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LedgerEntriesCompanion(
                id: id,
                type: type,
                amount: amount,
                note: note,
                occurredAt: occurredAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String type,
                required double amount,
                required String note,
                required DateTime occurredAt,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String deviceId,
                Value<int> rowid = const Value.absent(),
              }) => LedgerEntriesCompanion.insert(
                id: id,
                type: type,
                amount: amount,
                note: note,
                occurredAt: occurredAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LedgerEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LedgerEntriesTable,
      LedgerEntry,
      $$LedgerEntriesTableFilterComposer,
      $$LedgerEntriesTableOrderingComposer,
      $$LedgerEntriesTableAnnotationComposer,
      $$LedgerEntriesTableCreateCompanionBuilder,
      $$LedgerEntriesTableUpdateCompanionBuilder,
      (
        LedgerEntry,
        BaseReferences<_$AppDatabase, $LedgerEntriesTable, LedgerEntry>,
      ),
      LedgerEntry,
      PrefetchHooks Function()
    >;
typedef $$CountdownEventsTableCreateCompanionBuilder =
    CountdownEventsCompanion Function({
      required String id,
      required String title,
      required DateTime targetDate,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      required String deviceId,
      Value<int> rowid,
    });
typedef $$CountdownEventsTableUpdateCompanionBuilder =
    CountdownEventsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<DateTime> targetDate,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> deviceId,
      Value<int> rowid,
    });

class $$CountdownEventsTableFilterComposer
    extends Composer<_$AppDatabase, $CountdownEventsTable> {
  $$CountdownEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CountdownEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $CountdownEventsTable> {
  $$CountdownEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CountdownEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CountdownEventsTable> {
  $$CountdownEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<DateTime> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);
}

class $$CountdownEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CountdownEventsTable,
          CountdownEvent,
          $$CountdownEventsTableFilterComposer,
          $$CountdownEventsTableOrderingComposer,
          $$CountdownEventsTableAnnotationComposer,
          $$CountdownEventsTableCreateCompanionBuilder,
          $$CountdownEventsTableUpdateCompanionBuilder,
          (
            CountdownEvent,
            BaseReferences<
              _$AppDatabase,
              $CountdownEventsTable,
              CountdownEvent
            >,
          ),
          CountdownEvent,
          PrefetchHooks Function()
        > {
  $$CountdownEventsTableTableManager(
    _$AppDatabase db,
    $CountdownEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CountdownEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CountdownEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CountdownEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<DateTime> targetDate = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CountdownEventsCompanion(
                id: id,
                title: title,
                targetDate: targetDate,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required DateTime targetDate,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String deviceId,
                Value<int> rowid = const Value.absent(),
              }) => CountdownEventsCompanion.insert(
                id: id,
                title: title,
                targetDate: targetDate,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CountdownEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CountdownEventsTable,
      CountdownEvent,
      $$CountdownEventsTableFilterComposer,
      $$CountdownEventsTableOrderingComposer,
      $$CountdownEventsTableAnnotationComposer,
      $$CountdownEventsTableCreateCompanionBuilder,
      $$CountdownEventsTableUpdateCompanionBuilder,
      (
        CountdownEvent,
        BaseReferences<_$AppDatabase, $CountdownEventsTable, CountdownEvent>,
      ),
      CountdownEvent,
      PrefetchHooks Function()
    >;
typedef $$PomodoroSessionsTableCreateCompanionBuilder =
    PomodoroSessionsCompanion Function({
      required String id,
      required int minutes,
      required String note,
      required DateTime completedAt,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      required String deviceId,
      Value<int> rowid,
    });
typedef $$PomodoroSessionsTableUpdateCompanionBuilder =
    PomodoroSessionsCompanion Function({
      Value<String> id,
      Value<int> minutes,
      Value<String> note,
      Value<DateTime> completedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> deviceId,
      Value<int> rowid,
    });

class $$PomodoroSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $PomodoroSessionsTable> {
  $$PomodoroSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minutes => $composableBuilder(
    column: $table.minutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PomodoroSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $PomodoroSessionsTable> {
  $$PomodoroSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minutes => $composableBuilder(
    column: $table.minutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PomodoroSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PomodoroSessionsTable> {
  $$PomodoroSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get minutes =>
      $composableBuilder(column: $table.minutes, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);
}

class $$PomodoroSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PomodoroSessionsTable,
          PomodoroSession,
          $$PomodoroSessionsTableFilterComposer,
          $$PomodoroSessionsTableOrderingComposer,
          $$PomodoroSessionsTableAnnotationComposer,
          $$PomodoroSessionsTableCreateCompanionBuilder,
          $$PomodoroSessionsTableUpdateCompanionBuilder,
          (
            PomodoroSession,
            BaseReferences<
              _$AppDatabase,
              $PomodoroSessionsTable,
              PomodoroSession
            >,
          ),
          PomodoroSession,
          PrefetchHooks Function()
        > {
  $$PomodoroSessionsTableTableManager(
    _$AppDatabase db,
    $PomodoroSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PomodoroSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PomodoroSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PomodoroSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> minutes = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<DateTime> completedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PomodoroSessionsCompanion(
                id: id,
                minutes: minutes,
                note: note,
                completedAt: completedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int minutes,
                required String note,
                required DateTime completedAt,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String deviceId,
                Value<int> rowid = const Value.absent(),
              }) => PomodoroSessionsCompanion.insert(
                id: id,
                minutes: minutes,
                note: note,
                completedAt: completedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PomodoroSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PomodoroSessionsTable,
      PomodoroSession,
      $$PomodoroSessionsTableFilterComposer,
      $$PomodoroSessionsTableOrderingComposer,
      $$PomodoroSessionsTableAnnotationComposer,
      $$PomodoroSessionsTableCreateCompanionBuilder,
      $$PomodoroSessionsTableUpdateCompanionBuilder,
      (
        PomodoroSession,
        BaseReferences<_$AppDatabase, $PomodoroSessionsTable, PomodoroSession>,
      ),
      PomodoroSession,
      PrefetchHooks Function()
    >;
typedef $$PomodoroSettingsTableCreateCompanionBuilder =
    PomodoroSettingsCompanion Function({
      required String id,
      Value<int> focusMinutes,
      Value<int> breakMinutes,
      required DateTime updatedAt,
      required String deviceId,
      Value<int> rowid,
    });
typedef $$PomodoroSettingsTableUpdateCompanionBuilder =
    PomodoroSettingsCompanion Function({
      Value<String> id,
      Value<int> focusMinutes,
      Value<int> breakMinutes,
      Value<DateTime> updatedAt,
      Value<String> deviceId,
      Value<int> rowid,
    });

class $$PomodoroSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $PomodoroSettingsTable> {
  $$PomodoroSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get focusMinutes => $composableBuilder(
    column: $table.focusMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get breakMinutes => $composableBuilder(
    column: $table.breakMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PomodoroSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $PomodoroSettingsTable> {
  $$PomodoroSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get focusMinutes => $composableBuilder(
    column: $table.focusMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get breakMinutes => $composableBuilder(
    column: $table.breakMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PomodoroSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PomodoroSettingsTable> {
  $$PomodoroSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get focusMinutes => $composableBuilder(
    column: $table.focusMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get breakMinutes => $composableBuilder(
    column: $table.breakMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);
}

class $$PomodoroSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PomodoroSettingsTable,
          PomodoroSetting,
          $$PomodoroSettingsTableFilterComposer,
          $$PomodoroSettingsTableOrderingComposer,
          $$PomodoroSettingsTableAnnotationComposer,
          $$PomodoroSettingsTableCreateCompanionBuilder,
          $$PomodoroSettingsTableUpdateCompanionBuilder,
          (
            PomodoroSetting,
            BaseReferences<
              _$AppDatabase,
              $PomodoroSettingsTable,
              PomodoroSetting
            >,
          ),
          PomodoroSetting,
          PrefetchHooks Function()
        > {
  $$PomodoroSettingsTableTableManager(
    _$AppDatabase db,
    $PomodoroSettingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PomodoroSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PomodoroSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PomodoroSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> focusMinutes = const Value.absent(),
                Value<int> breakMinutes = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PomodoroSettingsCompanion(
                id: id,
                focusMinutes: focusMinutes,
                breakMinutes: breakMinutes,
                updatedAt: updatedAt,
                deviceId: deviceId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<int> focusMinutes = const Value.absent(),
                Value<int> breakMinutes = const Value.absent(),
                required DateTime updatedAt,
                required String deviceId,
                Value<int> rowid = const Value.absent(),
              }) => PomodoroSettingsCompanion.insert(
                id: id,
                focusMinutes: focusMinutes,
                breakMinutes: breakMinutes,
                updatedAt: updatedAt,
                deviceId: deviceId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PomodoroSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PomodoroSettingsTable,
      PomodoroSetting,
      $$PomodoroSettingsTableFilterComposer,
      $$PomodoroSettingsTableOrderingComposer,
      $$PomodoroSettingsTableAnnotationComposer,
      $$PomodoroSettingsTableCreateCompanionBuilder,
      $$PomodoroSettingsTableUpdateCompanionBuilder,
      (
        PomodoroSetting,
        BaseReferences<_$AppDatabase, $PomodoroSettingsTable, PomodoroSetting>,
      ),
      PomodoroSetting,
      PrefetchHooks Function()
    >;
typedef $$SteamStatusPresetRecordsTableCreateCompanionBuilder =
    SteamStatusPresetRecordsCompanion Function({
      required String id,
      required String steamStatusDisplayText,
      Value<int?> relatedSteamAppId,
      Value<String?> richPresenceTokenText,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      required String deviceId,
      Value<int> rowid,
    });
typedef $$SteamStatusPresetRecordsTableUpdateCompanionBuilder =
    SteamStatusPresetRecordsCompanion Function({
      Value<String> id,
      Value<String> steamStatusDisplayText,
      Value<int?> relatedSteamAppId,
      Value<String?> richPresenceTokenText,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> deviceId,
      Value<int> rowid,
    });

class $$SteamStatusPresetRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $SteamStatusPresetRecordsTable> {
  $$SteamStatusPresetRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get steamStatusDisplayText => $composableBuilder(
    column: $table.steamStatusDisplayText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get relatedSteamAppId => $composableBuilder(
    column: $table.relatedSteamAppId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get richPresenceTokenText => $composableBuilder(
    column: $table.richPresenceTokenText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SteamStatusPresetRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $SteamStatusPresetRecordsTable> {
  $$SteamStatusPresetRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get steamStatusDisplayText => $composableBuilder(
    column: $table.steamStatusDisplayText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get relatedSteamAppId => $composableBuilder(
    column: $table.relatedSteamAppId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get richPresenceTokenText => $composableBuilder(
    column: $table.richPresenceTokenText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SteamStatusPresetRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SteamStatusPresetRecordsTable> {
  $$SteamStatusPresetRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get steamStatusDisplayText => $composableBuilder(
    column: $table.steamStatusDisplayText,
    builder: (column) => column,
  );

  GeneratedColumn<int> get relatedSteamAppId => $composableBuilder(
    column: $table.relatedSteamAppId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get richPresenceTokenText => $composableBuilder(
    column: $table.richPresenceTokenText,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);
}

class $$SteamStatusPresetRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SteamStatusPresetRecordsTable,
          SteamStatusPresetRecord,
          $$SteamStatusPresetRecordsTableFilterComposer,
          $$SteamStatusPresetRecordsTableOrderingComposer,
          $$SteamStatusPresetRecordsTableAnnotationComposer,
          $$SteamStatusPresetRecordsTableCreateCompanionBuilder,
          $$SteamStatusPresetRecordsTableUpdateCompanionBuilder,
          (
            SteamStatusPresetRecord,
            BaseReferences<
              _$AppDatabase,
              $SteamStatusPresetRecordsTable,
              SteamStatusPresetRecord
            >,
          ),
          SteamStatusPresetRecord,
          PrefetchHooks Function()
        > {
  $$SteamStatusPresetRecordsTableTableManager(
    _$AppDatabase db,
    $SteamStatusPresetRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SteamStatusPresetRecordsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$SteamStatusPresetRecordsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SteamStatusPresetRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> steamStatusDisplayText = const Value.absent(),
                Value<int?> relatedSteamAppId = const Value.absent(),
                Value<String?> richPresenceTokenText = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SteamStatusPresetRecordsCompanion(
                id: id,
                steamStatusDisplayText: steamStatusDisplayText,
                relatedSteamAppId: relatedSteamAppId,
                richPresenceTokenText: richPresenceTokenText,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String steamStatusDisplayText,
                Value<int?> relatedSteamAppId = const Value.absent(),
                Value<String?> richPresenceTokenText = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String deviceId,
                Value<int> rowid = const Value.absent(),
              }) => SteamStatusPresetRecordsCompanion.insert(
                id: id,
                steamStatusDisplayText: steamStatusDisplayText,
                relatedSteamAppId: relatedSteamAppId,
                richPresenceTokenText: richPresenceTokenText,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SteamStatusPresetRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SteamStatusPresetRecordsTable,
      SteamStatusPresetRecord,
      $$SteamStatusPresetRecordsTableFilterComposer,
      $$SteamStatusPresetRecordsTableOrderingComposer,
      $$SteamStatusPresetRecordsTableAnnotationComposer,
      $$SteamStatusPresetRecordsTableCreateCompanionBuilder,
      $$SteamStatusPresetRecordsTableUpdateCompanionBuilder,
      (
        SteamStatusPresetRecord,
        BaseReferences<
          _$AppDatabase,
          $SteamStatusPresetRecordsTable,
          SteamStatusPresetRecord
        >,
      ),
      SteamStatusPresetRecord,
      PrefetchHooks Function()
    >;
typedef $$SteamStatusHistoryRecordsTableCreateCompanionBuilder =
    SteamStatusHistoryRecordsCompanion Function({
      required String id,
      required String steamStatusDisplayText,
      Value<int?> relatedSteamAppId,
      Value<String?> richPresenceTokenText,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      required String deviceId,
      Value<int> rowid,
    });
typedef $$SteamStatusHistoryRecordsTableUpdateCompanionBuilder =
    SteamStatusHistoryRecordsCompanion Function({
      Value<String> id,
      Value<String> steamStatusDisplayText,
      Value<int?> relatedSteamAppId,
      Value<String?> richPresenceTokenText,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> deviceId,
      Value<int> rowid,
    });

class $$SteamStatusHistoryRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $SteamStatusHistoryRecordsTable> {
  $$SteamStatusHistoryRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get steamStatusDisplayText => $composableBuilder(
    column: $table.steamStatusDisplayText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get relatedSteamAppId => $composableBuilder(
    column: $table.relatedSteamAppId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get richPresenceTokenText => $composableBuilder(
    column: $table.richPresenceTokenText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SteamStatusHistoryRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $SteamStatusHistoryRecordsTable> {
  $$SteamStatusHistoryRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get steamStatusDisplayText => $composableBuilder(
    column: $table.steamStatusDisplayText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get relatedSteamAppId => $composableBuilder(
    column: $table.relatedSteamAppId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get richPresenceTokenText => $composableBuilder(
    column: $table.richPresenceTokenText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SteamStatusHistoryRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SteamStatusHistoryRecordsTable> {
  $$SteamStatusHistoryRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get steamStatusDisplayText => $composableBuilder(
    column: $table.steamStatusDisplayText,
    builder: (column) => column,
  );

  GeneratedColumn<int> get relatedSteamAppId => $composableBuilder(
    column: $table.relatedSteamAppId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get richPresenceTokenText => $composableBuilder(
    column: $table.richPresenceTokenText,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);
}

class $$SteamStatusHistoryRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SteamStatusHistoryRecordsTable,
          SteamStatusHistoryRecord,
          $$SteamStatusHistoryRecordsTableFilterComposer,
          $$SteamStatusHistoryRecordsTableOrderingComposer,
          $$SteamStatusHistoryRecordsTableAnnotationComposer,
          $$SteamStatusHistoryRecordsTableCreateCompanionBuilder,
          $$SteamStatusHistoryRecordsTableUpdateCompanionBuilder,
          (
            SteamStatusHistoryRecord,
            BaseReferences<
              _$AppDatabase,
              $SteamStatusHistoryRecordsTable,
              SteamStatusHistoryRecord
            >,
          ),
          SteamStatusHistoryRecord,
          PrefetchHooks Function()
        > {
  $$SteamStatusHistoryRecordsTableTableManager(
    _$AppDatabase db,
    $SteamStatusHistoryRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SteamStatusHistoryRecordsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$SteamStatusHistoryRecordsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SteamStatusHistoryRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> steamStatusDisplayText = const Value.absent(),
                Value<int?> relatedSteamAppId = const Value.absent(),
                Value<String?> richPresenceTokenText = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SteamStatusHistoryRecordsCompanion(
                id: id,
                steamStatusDisplayText: steamStatusDisplayText,
                relatedSteamAppId: relatedSteamAppId,
                richPresenceTokenText: richPresenceTokenText,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String steamStatusDisplayText,
                Value<int?> relatedSteamAppId = const Value.absent(),
                Value<String?> richPresenceTokenText = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String deviceId,
                Value<int> rowid = const Value.absent(),
              }) => SteamStatusHistoryRecordsCompanion.insert(
                id: id,
                steamStatusDisplayText: steamStatusDisplayText,
                relatedSteamAppId: relatedSteamAppId,
                richPresenceTokenText: richPresenceTokenText,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SteamStatusHistoryRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SteamStatusHistoryRecordsTable,
      SteamStatusHistoryRecord,
      $$SteamStatusHistoryRecordsTableFilterComposer,
      $$SteamStatusHistoryRecordsTableOrderingComposer,
      $$SteamStatusHistoryRecordsTableAnnotationComposer,
      $$SteamStatusHistoryRecordsTableCreateCompanionBuilder,
      $$SteamStatusHistoryRecordsTableUpdateCompanionBuilder,
      (
        SteamStatusHistoryRecord,
        BaseReferences<
          _$AppDatabase,
          $SteamStatusHistoryRecordsTable,
          SteamStatusHistoryRecord
        >,
      ),
      SteamStatusHistoryRecord,
      PrefetchHooks Function()
    >;
typedef $$GetTokenCredentialSnapshotRecordsTableCreateCompanionBuilder =
    GetTokenCredentialSnapshotRecordsCompanion Function({
      required String id,
      required String email,
      Value<String?> authIndex,
      Value<String?> accountId,
      Value<String?> planType,
      Value<String?> credentialName,
      required String status,
      Value<double?> usedPercent,
      Value<double?> remainingPercent,
      Value<bool?> limitReached,
      Value<String?> error,
      Value<DateTime?> resetAt,
      Value<int?> resetAfterSeconds,
      Value<int?> limitWindowSeconds,
      Value<String?> rawJson,
      Value<bool> lastSuccessPreserved,
      required DateTime updatedAt,
      required String deviceId,
      Value<int> rowid,
    });
typedef $$GetTokenCredentialSnapshotRecordsTableUpdateCompanionBuilder =
    GetTokenCredentialSnapshotRecordsCompanion Function({
      Value<String> id,
      Value<String> email,
      Value<String?> authIndex,
      Value<String?> accountId,
      Value<String?> planType,
      Value<String?> credentialName,
      Value<String> status,
      Value<double?> usedPercent,
      Value<double?> remainingPercent,
      Value<bool?> limitReached,
      Value<String?> error,
      Value<DateTime?> resetAt,
      Value<int?> resetAfterSeconds,
      Value<int?> limitWindowSeconds,
      Value<String?> rawJson,
      Value<bool> lastSuccessPreserved,
      Value<DateTime> updatedAt,
      Value<String> deviceId,
      Value<int> rowid,
    });

class $$GetTokenCredentialSnapshotRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $GetTokenCredentialSnapshotRecordsTable> {
  $$GetTokenCredentialSnapshotRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authIndex => $composableBuilder(
    column: $table.authIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get planType => $composableBuilder(
    column: $table.planType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get credentialName => $composableBuilder(
    column: $table.credentialName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get usedPercent => $composableBuilder(
    column: $table.usedPercent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get remainingPercent => $composableBuilder(
    column: $table.remainingPercent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get limitReached => $composableBuilder(
    column: $table.limitReached,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get resetAt => $composableBuilder(
    column: $table.resetAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get resetAfterSeconds => $composableBuilder(
    column: $table.resetAfterSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get limitWindowSeconds => $composableBuilder(
    column: $table.limitWindowSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawJson => $composableBuilder(
    column: $table.rawJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get lastSuccessPreserved => $composableBuilder(
    column: $table.lastSuccessPreserved,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GetTokenCredentialSnapshotRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $GetTokenCredentialSnapshotRecordsTable> {
  $$GetTokenCredentialSnapshotRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authIndex => $composableBuilder(
    column: $table.authIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get planType => $composableBuilder(
    column: $table.planType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get credentialName => $composableBuilder(
    column: $table.credentialName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get usedPercent => $composableBuilder(
    column: $table.usedPercent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get remainingPercent => $composableBuilder(
    column: $table.remainingPercent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get limitReached => $composableBuilder(
    column: $table.limitReached,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get resetAt => $composableBuilder(
    column: $table.resetAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get resetAfterSeconds => $composableBuilder(
    column: $table.resetAfterSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get limitWindowSeconds => $composableBuilder(
    column: $table.limitWindowSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawJson => $composableBuilder(
    column: $table.rawJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get lastSuccessPreserved => $composableBuilder(
    column: $table.lastSuccessPreserved,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GetTokenCredentialSnapshotRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GetTokenCredentialSnapshotRecordsTable> {
  $$GetTokenCredentialSnapshotRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get authIndex =>
      $composableBuilder(column: $table.authIndex, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get planType =>
      $composableBuilder(column: $table.planType, builder: (column) => column);

  GeneratedColumn<String> get credentialName => $composableBuilder(
    column: $table.credentialName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<double> get usedPercent => $composableBuilder(
    column: $table.usedPercent,
    builder: (column) => column,
  );

  GeneratedColumn<double> get remainingPercent => $composableBuilder(
    column: $table.remainingPercent,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get limitReached => $composableBuilder(
    column: $table.limitReached,
    builder: (column) => column,
  );

  GeneratedColumn<String> get error =>
      $composableBuilder(column: $table.error, builder: (column) => column);

  GeneratedColumn<DateTime> get resetAt =>
      $composableBuilder(column: $table.resetAt, builder: (column) => column);

  GeneratedColumn<int> get resetAfterSeconds => $composableBuilder(
    column: $table.resetAfterSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get limitWindowSeconds => $composableBuilder(
    column: $table.limitWindowSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rawJson =>
      $composableBuilder(column: $table.rawJson, builder: (column) => column);

  GeneratedColumn<bool> get lastSuccessPreserved => $composableBuilder(
    column: $table.lastSuccessPreserved,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);
}

class $$GetTokenCredentialSnapshotRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GetTokenCredentialSnapshotRecordsTable,
          GetTokenCredentialSnapshotRecord,
          $$GetTokenCredentialSnapshotRecordsTableFilterComposer,
          $$GetTokenCredentialSnapshotRecordsTableOrderingComposer,
          $$GetTokenCredentialSnapshotRecordsTableAnnotationComposer,
          $$GetTokenCredentialSnapshotRecordsTableCreateCompanionBuilder,
          $$GetTokenCredentialSnapshotRecordsTableUpdateCompanionBuilder,
          (
            GetTokenCredentialSnapshotRecord,
            BaseReferences<
              _$AppDatabase,
              $GetTokenCredentialSnapshotRecordsTable,
              GetTokenCredentialSnapshotRecord
            >,
          ),
          GetTokenCredentialSnapshotRecord,
          PrefetchHooks Function()
        > {
  $$GetTokenCredentialSnapshotRecordsTableTableManager(
    _$AppDatabase db,
    $GetTokenCredentialSnapshotRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GetTokenCredentialSnapshotRecordsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$GetTokenCredentialSnapshotRecordsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$GetTokenCredentialSnapshotRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String?> authIndex = const Value.absent(),
                Value<String?> accountId = const Value.absent(),
                Value<String?> planType = const Value.absent(),
                Value<String?> credentialName = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<double?> usedPercent = const Value.absent(),
                Value<double?> remainingPercent = const Value.absent(),
                Value<bool?> limitReached = const Value.absent(),
                Value<String?> error = const Value.absent(),
                Value<DateTime?> resetAt = const Value.absent(),
                Value<int?> resetAfterSeconds = const Value.absent(),
                Value<int?> limitWindowSeconds = const Value.absent(),
                Value<String?> rawJson = const Value.absent(),
                Value<bool> lastSuccessPreserved = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GetTokenCredentialSnapshotRecordsCompanion(
                id: id,
                email: email,
                authIndex: authIndex,
                accountId: accountId,
                planType: planType,
                credentialName: credentialName,
                status: status,
                usedPercent: usedPercent,
                remainingPercent: remainingPercent,
                limitReached: limitReached,
                error: error,
                resetAt: resetAt,
                resetAfterSeconds: resetAfterSeconds,
                limitWindowSeconds: limitWindowSeconds,
                rawJson: rawJson,
                lastSuccessPreserved: lastSuccessPreserved,
                updatedAt: updatedAt,
                deviceId: deviceId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String email,
                Value<String?> authIndex = const Value.absent(),
                Value<String?> accountId = const Value.absent(),
                Value<String?> planType = const Value.absent(),
                Value<String?> credentialName = const Value.absent(),
                required String status,
                Value<double?> usedPercent = const Value.absent(),
                Value<double?> remainingPercent = const Value.absent(),
                Value<bool?> limitReached = const Value.absent(),
                Value<String?> error = const Value.absent(),
                Value<DateTime?> resetAt = const Value.absent(),
                Value<int?> resetAfterSeconds = const Value.absent(),
                Value<int?> limitWindowSeconds = const Value.absent(),
                Value<String?> rawJson = const Value.absent(),
                Value<bool> lastSuccessPreserved = const Value.absent(),
                required DateTime updatedAt,
                required String deviceId,
                Value<int> rowid = const Value.absent(),
              }) => GetTokenCredentialSnapshotRecordsCompanion.insert(
                id: id,
                email: email,
                authIndex: authIndex,
                accountId: accountId,
                planType: planType,
                credentialName: credentialName,
                status: status,
                usedPercent: usedPercent,
                remainingPercent: remainingPercent,
                limitReached: limitReached,
                error: error,
                resetAt: resetAt,
                resetAfterSeconds: resetAfterSeconds,
                limitWindowSeconds: limitWindowSeconds,
                rawJson: rawJson,
                lastSuccessPreserved: lastSuccessPreserved,
                updatedAt: updatedAt,
                deviceId: deviceId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GetTokenCredentialSnapshotRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GetTokenCredentialSnapshotRecordsTable,
      GetTokenCredentialSnapshotRecord,
      $$GetTokenCredentialSnapshotRecordsTableFilterComposer,
      $$GetTokenCredentialSnapshotRecordsTableOrderingComposer,
      $$GetTokenCredentialSnapshotRecordsTableAnnotationComposer,
      $$GetTokenCredentialSnapshotRecordsTableCreateCompanionBuilder,
      $$GetTokenCredentialSnapshotRecordsTableUpdateCompanionBuilder,
      (
        GetTokenCredentialSnapshotRecord,
        BaseReferences<
          _$AppDatabase,
          $GetTokenCredentialSnapshotRecordsTable,
          GetTokenCredentialSnapshotRecord
        >,
      ),
      GetTokenCredentialSnapshotRecord,
      PrefetchHooks Function()
    >;
typedef $$GetTokenCollectionStateRecordsTableCreateCompanionBuilder =
    GetTokenCollectionStateRecordsCompanion Function({
      required String id,
      required String status,
      required String message,
      required int processed,
      required int total,
      required double progressPercent,
      Value<String?> summaryJson,
      Value<String?> credentialChangesJson,
      Value<String?> refreshStatsJson,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> completedAt,
      required String deviceId,
      Value<int> rowid,
    });
typedef $$GetTokenCollectionStateRecordsTableUpdateCompanionBuilder =
    GetTokenCollectionStateRecordsCompanion Function({
      Value<String> id,
      Value<String> status,
      Value<String> message,
      Value<int> processed,
      Value<int> total,
      Value<double> progressPercent,
      Value<String?> summaryJson,
      Value<String?> credentialChangesJson,
      Value<String?> refreshStatsJson,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> completedAt,
      Value<String> deviceId,
      Value<int> rowid,
    });

class $$GetTokenCollectionStateRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $GetTokenCollectionStateRecordsTable> {
  $$GetTokenCollectionStateRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get processed => $composableBuilder(
    column: $table.processed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get progressPercent => $composableBuilder(
    column: $table.progressPercent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summaryJson => $composableBuilder(
    column: $table.summaryJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get credentialChangesJson => $composableBuilder(
    column: $table.credentialChangesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get refreshStatsJson => $composableBuilder(
    column: $table.refreshStatsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GetTokenCollectionStateRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $GetTokenCollectionStateRecordsTable> {
  $$GetTokenCollectionStateRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get processed => $composableBuilder(
    column: $table.processed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get progressPercent => $composableBuilder(
    column: $table.progressPercent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summaryJson => $composableBuilder(
    column: $table.summaryJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get credentialChangesJson => $composableBuilder(
    column: $table.credentialChangesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get refreshStatsJson => $composableBuilder(
    column: $table.refreshStatsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GetTokenCollectionStateRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GetTokenCollectionStateRecordsTable> {
  $$GetTokenCollectionStateRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<int> get processed =>
      $composableBuilder(column: $table.processed, builder: (column) => column);

  GeneratedColumn<int> get total =>
      $composableBuilder(column: $table.total, builder: (column) => column);

  GeneratedColumn<double> get progressPercent => $composableBuilder(
    column: $table.progressPercent,
    builder: (column) => column,
  );

  GeneratedColumn<String> get summaryJson => $composableBuilder(
    column: $table.summaryJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get credentialChangesJson => $composableBuilder(
    column: $table.credentialChangesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get refreshStatsJson => $composableBuilder(
    column: $table.refreshStatsJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);
}

class $$GetTokenCollectionStateRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GetTokenCollectionStateRecordsTable,
          GetTokenCollectionStateRecord,
          $$GetTokenCollectionStateRecordsTableFilterComposer,
          $$GetTokenCollectionStateRecordsTableOrderingComposer,
          $$GetTokenCollectionStateRecordsTableAnnotationComposer,
          $$GetTokenCollectionStateRecordsTableCreateCompanionBuilder,
          $$GetTokenCollectionStateRecordsTableUpdateCompanionBuilder,
          (
            GetTokenCollectionStateRecord,
            BaseReferences<
              _$AppDatabase,
              $GetTokenCollectionStateRecordsTable,
              GetTokenCollectionStateRecord
            >,
          ),
          GetTokenCollectionStateRecord,
          PrefetchHooks Function()
        > {
  $$GetTokenCollectionStateRecordsTableTableManager(
    _$AppDatabase db,
    $GetTokenCollectionStateRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GetTokenCollectionStateRecordsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$GetTokenCollectionStateRecordsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$GetTokenCollectionStateRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> message = const Value.absent(),
                Value<int> processed = const Value.absent(),
                Value<int> total = const Value.absent(),
                Value<double> progressPercent = const Value.absent(),
                Value<String?> summaryJson = const Value.absent(),
                Value<String?> credentialChangesJson = const Value.absent(),
                Value<String?> refreshStatsJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GetTokenCollectionStateRecordsCompanion(
                id: id,
                status: status,
                message: message,
                processed: processed,
                total: total,
                progressPercent: progressPercent,
                summaryJson: summaryJson,
                credentialChangesJson: credentialChangesJson,
                refreshStatsJson: refreshStatsJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                completedAt: completedAt,
                deviceId: deviceId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String status,
                required String message,
                required int processed,
                required int total,
                required double progressPercent,
                Value<String?> summaryJson = const Value.absent(),
                Value<String?> credentialChangesJson = const Value.absent(),
                Value<String?> refreshStatsJson = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> completedAt = const Value.absent(),
                required String deviceId,
                Value<int> rowid = const Value.absent(),
              }) => GetTokenCollectionStateRecordsCompanion.insert(
                id: id,
                status: status,
                message: message,
                processed: processed,
                total: total,
                progressPercent: progressPercent,
                summaryJson: summaryJson,
                credentialChangesJson: credentialChangesJson,
                refreshStatsJson: refreshStatsJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                completedAt: completedAt,
                deviceId: deviceId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GetTokenCollectionStateRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GetTokenCollectionStateRecordsTable,
      GetTokenCollectionStateRecord,
      $$GetTokenCollectionStateRecordsTableFilterComposer,
      $$GetTokenCollectionStateRecordsTableOrderingComposer,
      $$GetTokenCollectionStateRecordsTableAnnotationComposer,
      $$GetTokenCollectionStateRecordsTableCreateCompanionBuilder,
      $$GetTokenCollectionStateRecordsTableUpdateCompanionBuilder,
      (
        GetTokenCollectionStateRecord,
        BaseReferences<
          _$AppDatabase,
          $GetTokenCollectionStateRecordsTable,
          GetTokenCollectionStateRecord
        >,
      ),
      GetTokenCollectionStateRecord,
      PrefetchHooks Function()
    >;
typedef $$GetTokenUsageEventRecordsTableCreateCompanionBuilder =
    GetTokenUsageEventRecordsCompanion Function({
      required String id,
      required String authIndex,
      required String source,
      Value<String?> sourceType,
      Value<bool> failed,
      Value<String?> model,
      required DateTime timestamp,
      Value<int> inputTokens,
      Value<int> outputTokens,
      Value<int> reasoningTokens,
      Value<int> cachedTokens,
      Value<int> totalTokens,
      required String rawJson,
      required DateTime updatedAt,
      required String deviceId,
      Value<int> rowid,
    });
typedef $$GetTokenUsageEventRecordsTableUpdateCompanionBuilder =
    GetTokenUsageEventRecordsCompanion Function({
      Value<String> id,
      Value<String> authIndex,
      Value<String> source,
      Value<String?> sourceType,
      Value<bool> failed,
      Value<String?> model,
      Value<DateTime> timestamp,
      Value<int> inputTokens,
      Value<int> outputTokens,
      Value<int> reasoningTokens,
      Value<int> cachedTokens,
      Value<int> totalTokens,
      Value<String> rawJson,
      Value<DateTime> updatedAt,
      Value<String> deviceId,
      Value<int> rowid,
    });

class $$GetTokenUsageEventRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $GetTokenUsageEventRecordsTable> {
  $$GetTokenUsageEventRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authIndex => $composableBuilder(
    column: $table.authIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get failed => $composableBuilder(
    column: $table.failed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get inputTokens => $composableBuilder(
    column: $table.inputTokens,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get outputTokens => $composableBuilder(
    column: $table.outputTokens,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reasoningTokens => $composableBuilder(
    column: $table.reasoningTokens,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cachedTokens => $composableBuilder(
    column: $table.cachedTokens,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalTokens => $composableBuilder(
    column: $table.totalTokens,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawJson => $composableBuilder(
    column: $table.rawJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GetTokenUsageEventRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $GetTokenUsageEventRecordsTable> {
  $$GetTokenUsageEventRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authIndex => $composableBuilder(
    column: $table.authIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get failed => $composableBuilder(
    column: $table.failed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get inputTokens => $composableBuilder(
    column: $table.inputTokens,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get outputTokens => $composableBuilder(
    column: $table.outputTokens,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reasoningTokens => $composableBuilder(
    column: $table.reasoningTokens,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cachedTokens => $composableBuilder(
    column: $table.cachedTokens,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalTokens => $composableBuilder(
    column: $table.totalTokens,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawJson => $composableBuilder(
    column: $table.rawJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GetTokenUsageEventRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GetTokenUsageEventRecordsTable> {
  $$GetTokenUsageEventRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get authIndex =>
      $composableBuilder(column: $table.authIndex, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get failed =>
      $composableBuilder(column: $table.failed, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<int> get inputTokens => $composableBuilder(
    column: $table.inputTokens,
    builder: (column) => column,
  );

  GeneratedColumn<int> get outputTokens => $composableBuilder(
    column: $table.outputTokens,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reasoningTokens => $composableBuilder(
    column: $table.reasoningTokens,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cachedTokens => $composableBuilder(
    column: $table.cachedTokens,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalTokens => $composableBuilder(
    column: $table.totalTokens,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rawJson =>
      $composableBuilder(column: $table.rawJson, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);
}

class $$GetTokenUsageEventRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GetTokenUsageEventRecordsTable,
          GetTokenUsageEventRecord,
          $$GetTokenUsageEventRecordsTableFilterComposer,
          $$GetTokenUsageEventRecordsTableOrderingComposer,
          $$GetTokenUsageEventRecordsTableAnnotationComposer,
          $$GetTokenUsageEventRecordsTableCreateCompanionBuilder,
          $$GetTokenUsageEventRecordsTableUpdateCompanionBuilder,
          (
            GetTokenUsageEventRecord,
            BaseReferences<
              _$AppDatabase,
              $GetTokenUsageEventRecordsTable,
              GetTokenUsageEventRecord
            >,
          ),
          GetTokenUsageEventRecord,
          PrefetchHooks Function()
        > {
  $$GetTokenUsageEventRecordsTableTableManager(
    _$AppDatabase db,
    $GetTokenUsageEventRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GetTokenUsageEventRecordsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$GetTokenUsageEventRecordsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$GetTokenUsageEventRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> authIndex = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> sourceType = const Value.absent(),
                Value<bool> failed = const Value.absent(),
                Value<String?> model = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<int> inputTokens = const Value.absent(),
                Value<int> outputTokens = const Value.absent(),
                Value<int> reasoningTokens = const Value.absent(),
                Value<int> cachedTokens = const Value.absent(),
                Value<int> totalTokens = const Value.absent(),
                Value<String> rawJson = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GetTokenUsageEventRecordsCompanion(
                id: id,
                authIndex: authIndex,
                source: source,
                sourceType: sourceType,
                failed: failed,
                model: model,
                timestamp: timestamp,
                inputTokens: inputTokens,
                outputTokens: outputTokens,
                reasoningTokens: reasoningTokens,
                cachedTokens: cachedTokens,
                totalTokens: totalTokens,
                rawJson: rawJson,
                updatedAt: updatedAt,
                deviceId: deviceId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String authIndex,
                required String source,
                Value<String?> sourceType = const Value.absent(),
                Value<bool> failed = const Value.absent(),
                Value<String?> model = const Value.absent(),
                required DateTime timestamp,
                Value<int> inputTokens = const Value.absent(),
                Value<int> outputTokens = const Value.absent(),
                Value<int> reasoningTokens = const Value.absent(),
                Value<int> cachedTokens = const Value.absent(),
                Value<int> totalTokens = const Value.absent(),
                required String rawJson,
                required DateTime updatedAt,
                required String deviceId,
                Value<int> rowid = const Value.absent(),
              }) => GetTokenUsageEventRecordsCompanion.insert(
                id: id,
                authIndex: authIndex,
                source: source,
                sourceType: sourceType,
                failed: failed,
                model: model,
                timestamp: timestamp,
                inputTokens: inputTokens,
                outputTokens: outputTokens,
                reasoningTokens: reasoningTokens,
                cachedTokens: cachedTokens,
                totalTokens: totalTokens,
                rawJson: rawJson,
                updatedAt: updatedAt,
                deviceId: deviceId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GetTokenUsageEventRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GetTokenUsageEventRecordsTable,
      GetTokenUsageEventRecord,
      $$GetTokenUsageEventRecordsTableFilterComposer,
      $$GetTokenUsageEventRecordsTableOrderingComposer,
      $$GetTokenUsageEventRecordsTableAnnotationComposer,
      $$GetTokenUsageEventRecordsTableCreateCompanionBuilder,
      $$GetTokenUsageEventRecordsTableUpdateCompanionBuilder,
      (
        GetTokenUsageEventRecord,
        BaseReferences<
          _$AppDatabase,
          $GetTokenUsageEventRecordsTable,
          GetTokenUsageEventRecord
        >,
      ),
      GetTokenUsageEventRecord,
      PrefetchHooks Function()
    >;
typedef $$GetTokenUsageQueryStateRecordsTableCreateCompanionBuilder =
    GetTokenUsageQueryStateRecordsCompanion Function({
      required String id,
      required String paramsJson,
      required String summaryJson,
      required String upstreamJson,
      required String rowsJson,
      required int eventTableCount,
      required int addedEventCount,
      required DateTime updatedAt,
      required String deviceId,
      Value<int> rowid,
    });
typedef $$GetTokenUsageQueryStateRecordsTableUpdateCompanionBuilder =
    GetTokenUsageQueryStateRecordsCompanion Function({
      Value<String> id,
      Value<String> paramsJson,
      Value<String> summaryJson,
      Value<String> upstreamJson,
      Value<String> rowsJson,
      Value<int> eventTableCount,
      Value<int> addedEventCount,
      Value<DateTime> updatedAt,
      Value<String> deviceId,
      Value<int> rowid,
    });

class $$GetTokenUsageQueryStateRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $GetTokenUsageQueryStateRecordsTable> {
  $$GetTokenUsageQueryStateRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paramsJson => $composableBuilder(
    column: $table.paramsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summaryJson => $composableBuilder(
    column: $table.summaryJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get upstreamJson => $composableBuilder(
    column: $table.upstreamJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rowsJson => $composableBuilder(
    column: $table.rowsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get eventTableCount => $composableBuilder(
    column: $table.eventTableCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get addedEventCount => $composableBuilder(
    column: $table.addedEventCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GetTokenUsageQueryStateRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $GetTokenUsageQueryStateRecordsTable> {
  $$GetTokenUsageQueryStateRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paramsJson => $composableBuilder(
    column: $table.paramsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summaryJson => $composableBuilder(
    column: $table.summaryJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get upstreamJson => $composableBuilder(
    column: $table.upstreamJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rowsJson => $composableBuilder(
    column: $table.rowsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get eventTableCount => $composableBuilder(
    column: $table.eventTableCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get addedEventCount => $composableBuilder(
    column: $table.addedEventCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GetTokenUsageQueryStateRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GetTokenUsageQueryStateRecordsTable> {
  $$GetTokenUsageQueryStateRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get paramsJson => $composableBuilder(
    column: $table.paramsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get summaryJson => $composableBuilder(
    column: $table.summaryJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get upstreamJson => $composableBuilder(
    column: $table.upstreamJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rowsJson =>
      $composableBuilder(column: $table.rowsJson, builder: (column) => column);

  GeneratedColumn<int> get eventTableCount => $composableBuilder(
    column: $table.eventTableCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get addedEventCount => $composableBuilder(
    column: $table.addedEventCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);
}

class $$GetTokenUsageQueryStateRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GetTokenUsageQueryStateRecordsTable,
          GetTokenUsageQueryStateRecord,
          $$GetTokenUsageQueryStateRecordsTableFilterComposer,
          $$GetTokenUsageQueryStateRecordsTableOrderingComposer,
          $$GetTokenUsageQueryStateRecordsTableAnnotationComposer,
          $$GetTokenUsageQueryStateRecordsTableCreateCompanionBuilder,
          $$GetTokenUsageQueryStateRecordsTableUpdateCompanionBuilder,
          (
            GetTokenUsageQueryStateRecord,
            BaseReferences<
              _$AppDatabase,
              $GetTokenUsageQueryStateRecordsTable,
              GetTokenUsageQueryStateRecord
            >,
          ),
          GetTokenUsageQueryStateRecord,
          PrefetchHooks Function()
        > {
  $$GetTokenUsageQueryStateRecordsTableTableManager(
    _$AppDatabase db,
    $GetTokenUsageQueryStateRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GetTokenUsageQueryStateRecordsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$GetTokenUsageQueryStateRecordsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$GetTokenUsageQueryStateRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> paramsJson = const Value.absent(),
                Value<String> summaryJson = const Value.absent(),
                Value<String> upstreamJson = const Value.absent(),
                Value<String> rowsJson = const Value.absent(),
                Value<int> eventTableCount = const Value.absent(),
                Value<int> addedEventCount = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GetTokenUsageQueryStateRecordsCompanion(
                id: id,
                paramsJson: paramsJson,
                summaryJson: summaryJson,
                upstreamJson: upstreamJson,
                rowsJson: rowsJson,
                eventTableCount: eventTableCount,
                addedEventCount: addedEventCount,
                updatedAt: updatedAt,
                deviceId: deviceId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String paramsJson,
                required String summaryJson,
                required String upstreamJson,
                required String rowsJson,
                required int eventTableCount,
                required int addedEventCount,
                required DateTime updatedAt,
                required String deviceId,
                Value<int> rowid = const Value.absent(),
              }) => GetTokenUsageQueryStateRecordsCompanion.insert(
                id: id,
                paramsJson: paramsJson,
                summaryJson: summaryJson,
                upstreamJson: upstreamJson,
                rowsJson: rowsJson,
                eventTableCount: eventTableCount,
                addedEventCount: addedEventCount,
                updatedAt: updatedAt,
                deviceId: deviceId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GetTokenUsageQueryStateRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GetTokenUsageQueryStateRecordsTable,
      GetTokenUsageQueryStateRecord,
      $$GetTokenUsageQueryStateRecordsTableFilterComposer,
      $$GetTokenUsageQueryStateRecordsTableOrderingComposer,
      $$GetTokenUsageQueryStateRecordsTableAnnotationComposer,
      $$GetTokenUsageQueryStateRecordsTableCreateCompanionBuilder,
      $$GetTokenUsageQueryStateRecordsTableUpdateCompanionBuilder,
      (
        GetTokenUsageQueryStateRecord,
        BaseReferences<
          _$AppDatabase,
          $GetTokenUsageQueryStateRecordsTable,
          GetTokenUsageQueryStateRecord
        >,
      ),
      GetTokenUsageQueryStateRecord,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$NotesTableTableManager get notes =>
      $$NotesTableTableManager(_db, _db.notes);
  $$TodosTableTableManager get todos =>
      $$TodosTableTableManager(_db, _db.todos);
  $$LedgerEntriesTableTableManager get ledgerEntries =>
      $$LedgerEntriesTableTableManager(_db, _db.ledgerEntries);
  $$CountdownEventsTableTableManager get countdownEvents =>
      $$CountdownEventsTableTableManager(_db, _db.countdownEvents);
  $$PomodoroSessionsTableTableManager get pomodoroSessions =>
      $$PomodoroSessionsTableTableManager(_db, _db.pomodoroSessions);
  $$PomodoroSettingsTableTableManager get pomodoroSettings =>
      $$PomodoroSettingsTableTableManager(_db, _db.pomodoroSettings);
  $$SteamStatusPresetRecordsTableTableManager get steamStatusPresetRecords =>
      $$SteamStatusPresetRecordsTableTableManager(
        _db,
        _db.steamStatusPresetRecords,
      );
  $$SteamStatusHistoryRecordsTableTableManager get steamStatusHistoryRecords =>
      $$SteamStatusHistoryRecordsTableTableManager(
        _db,
        _db.steamStatusHistoryRecords,
      );
  $$GetTokenCredentialSnapshotRecordsTableTableManager
  get getTokenCredentialSnapshotRecords =>
      $$GetTokenCredentialSnapshotRecordsTableTableManager(
        _db,
        _db.getTokenCredentialSnapshotRecords,
      );
  $$GetTokenCollectionStateRecordsTableTableManager
  get getTokenCollectionStateRecords =>
      $$GetTokenCollectionStateRecordsTableTableManager(
        _db,
        _db.getTokenCollectionStateRecords,
      );
  $$GetTokenUsageEventRecordsTableTableManager get getTokenUsageEventRecords =>
      $$GetTokenUsageEventRecordsTableTableManager(
        _db,
        _db.getTokenUsageEventRecords,
      );
  $$GetTokenUsageQueryStateRecordsTableTableManager
  get getTokenUsageQueryStateRecords =>
      $$GetTokenUsageQueryStateRecordsTableTableManager(
        _db,
        _db.getTokenUsageQueryStateRecords,
      );
}
