// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $DbCharactersTable extends DbCharacters
    with TableInfo<$DbCharactersTable, CharacterRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DbCharactersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _typedCharacterMeta =
      const VerificationMeta('typedCharacter');
  @override
  late final GeneratedColumn<String> typedCharacter = GeneratedColumn<String>(
      'typed_character', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('?'));
  static const VerificationMeta _definitionMeta =
      const VerificationMeta('definition');
  @override
  late final GeneratedColumn<String> definition = GeneratedColumn<String>(
      'definition', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _isStarredMeta =
      const VerificationMeta('isStarred');
  @override
  late final GeneratedColumn<bool> isStarred = GeneratedColumn<bool>(
      'is_starred', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_starred" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isHardMeta = const VerificationMeta('isHard');
  @override
  late final GeneratedColumn<bool> isHard = GeneratedColumn<bool>(
      'is_hard', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_hard" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isArchivedMeta =
      const VerificationMeta('isArchived');
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
      'is_archived', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_archived" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _handwritingMeta =
      const VerificationMeta('handwriting');
  @override
  late final GeneratedColumn<Uint8List> handwriting =
      GeneratedColumn<Uint8List>('handwriting', aliasedName, true,
          type: DriftSqlType.blob, requiredDuringInsert: false);
  static const VerificationMeta _timesSeenMeta =
      const VerificationMeta('timesSeen');
  @override
  late final GeneratedColumn<int> timesSeen = GeneratedColumn<int>(
      'times_seen', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _timesCorrectMeta =
      const VerificationMeta('timesCorrect');
  @override
  late final GeneratedColumn<int> timesCorrect = GeneratedColumn<int>(
      'times_correct', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _timesIncorrectMeta =
      const VerificationMeta('timesIncorrect');
  @override
  late final GeneratedColumn<int> timesIncorrect = GeneratedColumn<int>(
      'times_incorrect', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastReviewedAtMeta =
      const VerificationMeta('lastReviewedAt');
  @override
  late final GeneratedColumn<DateTime> lastReviewedAt =
      GeneratedColumn<DateTime>('last_reviewed_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        typedCharacter,
        definition,
        notes,
        isStarred,
        isHard,
        isArchived,
        createdAt,
        updatedAt,
        handwriting,
        timesSeen,
        timesCorrect,
        timesIncorrect,
        lastReviewedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'characters';
  @override
  VerificationContext validateIntegrity(Insertable<CharacterRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('typed_character')) {
      context.handle(
          _typedCharacterMeta,
          typedCharacter.isAcceptableOrUnknown(
              data['typed_character']!, _typedCharacterMeta));
    }
    if (data.containsKey('definition')) {
      context.handle(
          _definitionMeta,
          definition.isAcceptableOrUnknown(
              data['definition']!, _definitionMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('is_starred')) {
      context.handle(_isStarredMeta,
          isStarred.isAcceptableOrUnknown(data['is_starred']!, _isStarredMeta));
    }
    if (data.containsKey('is_hard')) {
      context.handle(_isHardMeta,
          isHard.isAcceptableOrUnknown(data['is_hard']!, _isHardMeta));
    }
    if (data.containsKey('is_archived')) {
      context.handle(
          _isArchivedMeta,
          isArchived.isAcceptableOrUnknown(
              data['is_archived']!, _isArchivedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('handwriting')) {
      context.handle(
          _handwritingMeta,
          handwriting.isAcceptableOrUnknown(
              data['handwriting']!, _handwritingMeta));
    }
    if (data.containsKey('times_seen')) {
      context.handle(_timesSeenMeta,
          timesSeen.isAcceptableOrUnknown(data['times_seen']!, _timesSeenMeta));
    }
    if (data.containsKey('times_correct')) {
      context.handle(
          _timesCorrectMeta,
          timesCorrect.isAcceptableOrUnknown(
              data['times_correct']!, _timesCorrectMeta));
    }
    if (data.containsKey('times_incorrect')) {
      context.handle(
          _timesIncorrectMeta,
          timesIncorrect.isAcceptableOrUnknown(
              data['times_incorrect']!, _timesIncorrectMeta));
    }
    if (data.containsKey('last_reviewed_at')) {
      context.handle(
          _lastReviewedAtMeta,
          lastReviewedAt.isAcceptableOrUnknown(
              data['last_reviewed_at']!, _lastReviewedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CharacterRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CharacterRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      typedCharacter: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}typed_character'])!,
      definition: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}definition'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes'])!,
      isStarred: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_starred'])!,
      isHard: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_hard'])!,
      isArchived: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_archived'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      handwriting: attachedDatabase.typeMapping
          .read(DriftSqlType.blob, data['${effectivePrefix}handwriting']),
      timesSeen: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}times_seen'])!,
      timesCorrect: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}times_correct'])!,
      timesIncorrect: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}times_incorrect'])!,
      lastReviewedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_reviewed_at']),
    );
  }

  @override
  $DbCharactersTable createAlias(String alias) {
    return $DbCharactersTable(attachedDatabase, alias);
  }
}

class CharacterRow extends DataClass implements Insertable<CharacterRow> {
  final int id;
  final String typedCharacter;
  final String definition;
  final String notes;
  final bool isStarred;
  final bool isHard;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Packed handwriting strokes (see [StrokeCodec]); null = not drawn yet.
  final Uint8List? handwriting;
  final int timesSeen;
  final int timesCorrect;
  final int timesIncorrect;
  final DateTime? lastReviewedAt;
  const CharacterRow(
      {required this.id,
      required this.typedCharacter,
      required this.definition,
      required this.notes,
      required this.isStarred,
      required this.isHard,
      required this.isArchived,
      required this.createdAt,
      required this.updatedAt,
      this.handwriting,
      required this.timesSeen,
      required this.timesCorrect,
      required this.timesIncorrect,
      this.lastReviewedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['typed_character'] = Variable<String>(typedCharacter);
    map['definition'] = Variable<String>(definition);
    map['notes'] = Variable<String>(notes);
    map['is_starred'] = Variable<bool>(isStarred);
    map['is_hard'] = Variable<bool>(isHard);
    map['is_archived'] = Variable<bool>(isArchived);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || handwriting != null) {
      map['handwriting'] = Variable<Uint8List>(handwriting);
    }
    map['times_seen'] = Variable<int>(timesSeen);
    map['times_correct'] = Variable<int>(timesCorrect);
    map['times_incorrect'] = Variable<int>(timesIncorrect);
    if (!nullToAbsent || lastReviewedAt != null) {
      map['last_reviewed_at'] = Variable<DateTime>(lastReviewedAt);
    }
    return map;
  }

  DbCharactersCompanion toCompanion(bool nullToAbsent) {
    return DbCharactersCompanion(
      id: Value(id),
      typedCharacter: Value(typedCharacter),
      definition: Value(definition),
      notes: Value(notes),
      isStarred: Value(isStarred),
      isHard: Value(isHard),
      isArchived: Value(isArchived),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      handwriting: handwriting == null && nullToAbsent
          ? const Value.absent()
          : Value(handwriting),
      timesSeen: Value(timesSeen),
      timesCorrect: Value(timesCorrect),
      timesIncorrect: Value(timesIncorrect),
      lastReviewedAt: lastReviewedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReviewedAt),
    );
  }

  factory CharacterRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CharacterRow(
      id: serializer.fromJson<int>(json['id']),
      typedCharacter: serializer.fromJson<String>(json['typedCharacter']),
      definition: serializer.fromJson<String>(json['definition']),
      notes: serializer.fromJson<String>(json['notes']),
      isStarred: serializer.fromJson<bool>(json['isStarred']),
      isHard: serializer.fromJson<bool>(json['isHard']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      handwriting: serializer.fromJson<Uint8List?>(json['handwriting']),
      timesSeen: serializer.fromJson<int>(json['timesSeen']),
      timesCorrect: serializer.fromJson<int>(json['timesCorrect']),
      timesIncorrect: serializer.fromJson<int>(json['timesIncorrect']),
      lastReviewedAt: serializer.fromJson<DateTime?>(json['lastReviewedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'typedCharacter': serializer.toJson<String>(typedCharacter),
      'definition': serializer.toJson<String>(definition),
      'notes': serializer.toJson<String>(notes),
      'isStarred': serializer.toJson<bool>(isStarred),
      'isHard': serializer.toJson<bool>(isHard),
      'isArchived': serializer.toJson<bool>(isArchived),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'handwriting': serializer.toJson<Uint8List?>(handwriting),
      'timesSeen': serializer.toJson<int>(timesSeen),
      'timesCorrect': serializer.toJson<int>(timesCorrect),
      'timesIncorrect': serializer.toJson<int>(timesIncorrect),
      'lastReviewedAt': serializer.toJson<DateTime?>(lastReviewedAt),
    };
  }

  CharacterRow copyWith(
          {int? id,
          String? typedCharacter,
          String? definition,
          String? notes,
          bool? isStarred,
          bool? isHard,
          bool? isArchived,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<Uint8List?> handwriting = const Value.absent(),
          int? timesSeen,
          int? timesCorrect,
          int? timesIncorrect,
          Value<DateTime?> lastReviewedAt = const Value.absent()}) =>
      CharacterRow(
        id: id ?? this.id,
        typedCharacter: typedCharacter ?? this.typedCharacter,
        definition: definition ?? this.definition,
        notes: notes ?? this.notes,
        isStarred: isStarred ?? this.isStarred,
        isHard: isHard ?? this.isHard,
        isArchived: isArchived ?? this.isArchived,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        handwriting: handwriting.present ? handwriting.value : this.handwriting,
        timesSeen: timesSeen ?? this.timesSeen,
        timesCorrect: timesCorrect ?? this.timesCorrect,
        timesIncorrect: timesIncorrect ?? this.timesIncorrect,
        lastReviewedAt:
            lastReviewedAt.present ? lastReviewedAt.value : this.lastReviewedAt,
      );
  CharacterRow copyWithCompanion(DbCharactersCompanion data) {
    return CharacterRow(
      id: data.id.present ? data.id.value : this.id,
      typedCharacter: data.typedCharacter.present
          ? data.typedCharacter.value
          : this.typedCharacter,
      definition:
          data.definition.present ? data.definition.value : this.definition,
      notes: data.notes.present ? data.notes.value : this.notes,
      isStarred: data.isStarred.present ? data.isStarred.value : this.isStarred,
      isHard: data.isHard.present ? data.isHard.value : this.isHard,
      isArchived:
          data.isArchived.present ? data.isArchived.value : this.isArchived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      handwriting:
          data.handwriting.present ? data.handwriting.value : this.handwriting,
      timesSeen: data.timesSeen.present ? data.timesSeen.value : this.timesSeen,
      timesCorrect: data.timesCorrect.present
          ? data.timesCorrect.value
          : this.timesCorrect,
      timesIncorrect: data.timesIncorrect.present
          ? data.timesIncorrect.value
          : this.timesIncorrect,
      lastReviewedAt: data.lastReviewedAt.present
          ? data.lastReviewedAt.value
          : this.lastReviewedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CharacterRow(')
          ..write('id: $id, ')
          ..write('typedCharacter: $typedCharacter, ')
          ..write('definition: $definition, ')
          ..write('notes: $notes, ')
          ..write('isStarred: $isStarred, ')
          ..write('isHard: $isHard, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('handwriting: $handwriting, ')
          ..write('timesSeen: $timesSeen, ')
          ..write('timesCorrect: $timesCorrect, ')
          ..write('timesIncorrect: $timesIncorrect, ')
          ..write('lastReviewedAt: $lastReviewedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      typedCharacter,
      definition,
      notes,
      isStarred,
      isHard,
      isArchived,
      createdAt,
      updatedAt,
      $driftBlobEquality.hash(handwriting),
      timesSeen,
      timesCorrect,
      timesIncorrect,
      lastReviewedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CharacterRow &&
          other.id == this.id &&
          other.typedCharacter == this.typedCharacter &&
          other.definition == this.definition &&
          other.notes == this.notes &&
          other.isStarred == this.isStarred &&
          other.isHard == this.isHard &&
          other.isArchived == this.isArchived &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          $driftBlobEquality.equals(other.handwriting, this.handwriting) &&
          other.timesSeen == this.timesSeen &&
          other.timesCorrect == this.timesCorrect &&
          other.timesIncorrect == this.timesIncorrect &&
          other.lastReviewedAt == this.lastReviewedAt);
}

class DbCharactersCompanion extends UpdateCompanion<CharacterRow> {
  final Value<int> id;
  final Value<String> typedCharacter;
  final Value<String> definition;
  final Value<String> notes;
  final Value<bool> isStarred;
  final Value<bool> isHard;
  final Value<bool> isArchived;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<Uint8List?> handwriting;
  final Value<int> timesSeen;
  final Value<int> timesCorrect;
  final Value<int> timesIncorrect;
  final Value<DateTime?> lastReviewedAt;
  const DbCharactersCompanion({
    this.id = const Value.absent(),
    this.typedCharacter = const Value.absent(),
    this.definition = const Value.absent(),
    this.notes = const Value.absent(),
    this.isStarred = const Value.absent(),
    this.isHard = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.handwriting = const Value.absent(),
    this.timesSeen = const Value.absent(),
    this.timesCorrect = const Value.absent(),
    this.timesIncorrect = const Value.absent(),
    this.lastReviewedAt = const Value.absent(),
  });
  DbCharactersCompanion.insert({
    this.id = const Value.absent(),
    this.typedCharacter = const Value.absent(),
    this.definition = const Value.absent(),
    this.notes = const Value.absent(),
    this.isStarred = const Value.absent(),
    this.isHard = const Value.absent(),
    this.isArchived = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.handwriting = const Value.absent(),
    this.timesSeen = const Value.absent(),
    this.timesCorrect = const Value.absent(),
    this.timesIncorrect = const Value.absent(),
    this.lastReviewedAt = const Value.absent(),
  })  : createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<CharacterRow> custom({
    Expression<int>? id,
    Expression<String>? typedCharacter,
    Expression<String>? definition,
    Expression<String>? notes,
    Expression<bool>? isStarred,
    Expression<bool>? isHard,
    Expression<bool>? isArchived,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<Uint8List>? handwriting,
    Expression<int>? timesSeen,
    Expression<int>? timesCorrect,
    Expression<int>? timesIncorrect,
    Expression<DateTime>? lastReviewedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (typedCharacter != null) 'typed_character': typedCharacter,
      if (definition != null) 'definition': definition,
      if (notes != null) 'notes': notes,
      if (isStarred != null) 'is_starred': isStarred,
      if (isHard != null) 'is_hard': isHard,
      if (isArchived != null) 'is_archived': isArchived,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (handwriting != null) 'handwriting': handwriting,
      if (timesSeen != null) 'times_seen': timesSeen,
      if (timesCorrect != null) 'times_correct': timesCorrect,
      if (timesIncorrect != null) 'times_incorrect': timesIncorrect,
      if (lastReviewedAt != null) 'last_reviewed_at': lastReviewedAt,
    });
  }

  DbCharactersCompanion copyWith(
      {Value<int>? id,
      Value<String>? typedCharacter,
      Value<String>? definition,
      Value<String>? notes,
      Value<bool>? isStarred,
      Value<bool>? isHard,
      Value<bool>? isArchived,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<Uint8List?>? handwriting,
      Value<int>? timesSeen,
      Value<int>? timesCorrect,
      Value<int>? timesIncorrect,
      Value<DateTime?>? lastReviewedAt}) {
    return DbCharactersCompanion(
      id: id ?? this.id,
      typedCharacter: typedCharacter ?? this.typedCharacter,
      definition: definition ?? this.definition,
      notes: notes ?? this.notes,
      isStarred: isStarred ?? this.isStarred,
      isHard: isHard ?? this.isHard,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      handwriting: handwriting ?? this.handwriting,
      timesSeen: timesSeen ?? this.timesSeen,
      timesCorrect: timesCorrect ?? this.timesCorrect,
      timesIncorrect: timesIncorrect ?? this.timesIncorrect,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (typedCharacter.present) {
      map['typed_character'] = Variable<String>(typedCharacter.value);
    }
    if (definition.present) {
      map['definition'] = Variable<String>(definition.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isStarred.present) {
      map['is_starred'] = Variable<bool>(isStarred.value);
    }
    if (isHard.present) {
      map['is_hard'] = Variable<bool>(isHard.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (handwriting.present) {
      map['handwriting'] = Variable<Uint8List>(handwriting.value);
    }
    if (timesSeen.present) {
      map['times_seen'] = Variable<int>(timesSeen.value);
    }
    if (timesCorrect.present) {
      map['times_correct'] = Variable<int>(timesCorrect.value);
    }
    if (timesIncorrect.present) {
      map['times_incorrect'] = Variable<int>(timesIncorrect.value);
    }
    if (lastReviewedAt.present) {
      map['last_reviewed_at'] = Variable<DateTime>(lastReviewedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DbCharactersCompanion(')
          ..write('id: $id, ')
          ..write('typedCharacter: $typedCharacter, ')
          ..write('definition: $definition, ')
          ..write('notes: $notes, ')
          ..write('isStarred: $isStarred, ')
          ..write('isHard: $isHard, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('handwriting: $handwriting, ')
          ..write('timesSeen: $timesSeen, ')
          ..write('timesCorrect: $timesCorrect, ')
          ..write('timesIncorrect: $timesIncorrect, ')
          ..write('lastReviewedAt: $lastReviewedAt')
          ..write(')'))
        .toString();
  }
}

class $DbTagsTable extends DbTags with TableInfo<$DbTagsTable, TagRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DbTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  VerificationContext validateIntegrity(Insertable<TagRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {name},
      ];
  @override
  TagRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TagRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
    );
  }

  @override
  $DbTagsTable createAlias(String alias) {
    return $DbTagsTable(attachedDatabase, alias);
  }
}

class TagRow extends DataClass implements Insertable<TagRow> {
  final int id;
  final String name;
  const TagRow({required this.id, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    return map;
  }

  DbTagsCompanion toCompanion(bool nullToAbsent) {
    return DbTagsCompanion(
      id: Value(id),
      name: Value(name),
    );
  }

  factory TagRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TagRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
    };
  }

  TagRow copyWith({int? id, String? name}) => TagRow(
        id: id ?? this.id,
        name: name ?? this.name,
      );
  TagRow copyWithCompanion(DbTagsCompanion data) {
    return TagRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TagRow(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TagRow && other.id == this.id && other.name == this.name);
}

class DbTagsCompanion extends UpdateCompanion<TagRow> {
  final Value<int> id;
  final Value<String> name;
  const DbTagsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
  });
  DbTagsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
  }) : name = Value(name);
  static Insertable<TagRow> custom({
    Expression<int>? id,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    });
  }

  DbTagsCompanion copyWith({Value<int>? id, Value<String>? name}) {
    return DbTagsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DbTagsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

class $DbCharacterTagsTable extends DbCharacterTags
    with TableInfo<$DbCharacterTagsTable, CharacterTagRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DbCharacterTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _characterIdMeta =
      const VerificationMeta('characterId');
  @override
  late final GeneratedColumn<int> characterId = GeneratedColumn<int>(
      'character_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<int> tagId = GeneratedColumn<int>(
      'tag_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _positionMeta =
      const VerificationMeta('position');
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
      'position', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [characterId, tagId, position];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'character_tags';
  @override
  VerificationContext validateIntegrity(Insertable<CharacterTagRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('character_id')) {
      context.handle(
          _characterIdMeta,
          characterId.isAcceptableOrUnknown(
              data['character_id']!, _characterIdMeta));
    } else if (isInserting) {
      context.missing(_characterIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
          _tagIdMeta, tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta));
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(_positionMeta,
          position.isAcceptableOrUnknown(data['position']!, _positionMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {characterId, tagId};
  @override
  CharacterTagRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CharacterTagRow(
      characterId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}character_id'])!,
      tagId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tag_id'])!,
      position: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}position'])!,
    );
  }

  @override
  $DbCharacterTagsTable createAlias(String alias) {
    return $DbCharacterTagsTable(attachedDatabase, alias);
  }
}

class CharacterTagRow extends DataClass implements Insertable<CharacterTagRow> {
  final int characterId;
  final int tagId;
  final int position;
  const CharacterTagRow(
      {required this.characterId, required this.tagId, required this.position});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['character_id'] = Variable<int>(characterId);
    map['tag_id'] = Variable<int>(tagId);
    map['position'] = Variable<int>(position);
    return map;
  }

  DbCharacterTagsCompanion toCompanion(bool nullToAbsent) {
    return DbCharacterTagsCompanion(
      characterId: Value(characterId),
      tagId: Value(tagId),
      position: Value(position),
    );
  }

  factory CharacterTagRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CharacterTagRow(
      characterId: serializer.fromJson<int>(json['characterId']),
      tagId: serializer.fromJson<int>(json['tagId']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'characterId': serializer.toJson<int>(characterId),
      'tagId': serializer.toJson<int>(tagId),
      'position': serializer.toJson<int>(position),
    };
  }

  CharacterTagRow copyWith({int? characterId, int? tagId, int? position}) =>
      CharacterTagRow(
        characterId: characterId ?? this.characterId,
        tagId: tagId ?? this.tagId,
        position: position ?? this.position,
      );
  CharacterTagRow copyWithCompanion(DbCharacterTagsCompanion data) {
    return CharacterTagRow(
      characterId:
          data.characterId.present ? data.characterId.value : this.characterId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CharacterTagRow(')
          ..write('characterId: $characterId, ')
          ..write('tagId: $tagId, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(characterId, tagId, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CharacterTagRow &&
          other.characterId == this.characterId &&
          other.tagId == this.tagId &&
          other.position == this.position);
}

class DbCharacterTagsCompanion extends UpdateCompanion<CharacterTagRow> {
  final Value<int> characterId;
  final Value<int> tagId;
  final Value<int> position;
  final Value<int> rowid;
  const DbCharacterTagsCompanion({
    this.characterId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DbCharacterTagsCompanion.insert({
    required int characterId,
    required int tagId,
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : characterId = Value(characterId),
        tagId = Value(tagId);
  static Insertable<CharacterTagRow> custom({
    Expression<int>? characterId,
    Expression<int>? tagId,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (characterId != null) 'character_id': characterId,
      if (tagId != null) 'tag_id': tagId,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DbCharacterTagsCompanion copyWith(
      {Value<int>? characterId,
      Value<int>? tagId,
      Value<int>? position,
      Value<int>? rowid}) {
    return DbCharacterTagsCompanion(
      characterId: characterId ?? this.characterId,
      tagId: tagId ?? this.tagId,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (characterId.present) {
      map['character_id'] = Variable<int>(characterId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<int>(tagId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DbCharacterTagsCompanion(')
          ..write('characterId: $characterId, ')
          ..write('tagId: $tagId, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DbCharacterReferencesTable extends DbCharacterReferences
    with TableInfo<$DbCharacterReferencesTable, CharacterReferenceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DbCharacterReferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _characterAIdMeta =
      const VerificationMeta('characterAId');
  @override
  late final GeneratedColumn<int> characterAId = GeneratedColumn<int>(
      'character_a_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _characterBIdMeta =
      const VerificationMeta('characterBId');
  @override
  late final GeneratedColumn<int> characterBId = GeneratedColumn<int>(
      'character_b_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [characterAId, characterBId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'character_references';
  @override
  VerificationContext validateIntegrity(
      Insertable<CharacterReferenceRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('character_a_id')) {
      context.handle(
          _characterAIdMeta,
          characterAId.isAcceptableOrUnknown(
              data['character_a_id']!, _characterAIdMeta));
    } else if (isInserting) {
      context.missing(_characterAIdMeta);
    }
    if (data.containsKey('character_b_id')) {
      context.handle(
          _characterBIdMeta,
          characterBId.isAcceptableOrUnknown(
              data['character_b_id']!, _characterBIdMeta));
    } else if (isInserting) {
      context.missing(_characterBIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {characterAId, characterBId};
  @override
  CharacterReferenceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CharacterReferenceRow(
      characterAId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}character_a_id'])!,
      characterBId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}character_b_id'])!,
    );
  }

  @override
  $DbCharacterReferencesTable createAlias(String alias) {
    return $DbCharacterReferencesTable(attachedDatabase, alias);
  }
}

class CharacterReferenceRow extends DataClass
    implements Insertable<CharacterReferenceRow> {
  final int characterAId;
  final int characterBId;
  const CharacterReferenceRow(
      {required this.characterAId, required this.characterBId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['character_a_id'] = Variable<int>(characterAId);
    map['character_b_id'] = Variable<int>(characterBId);
    return map;
  }

  DbCharacterReferencesCompanion toCompanion(bool nullToAbsent) {
    return DbCharacterReferencesCompanion(
      characterAId: Value(characterAId),
      characterBId: Value(characterBId),
    );
  }

  factory CharacterReferenceRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CharacterReferenceRow(
      characterAId: serializer.fromJson<int>(json['characterAId']),
      characterBId: serializer.fromJson<int>(json['characterBId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'characterAId': serializer.toJson<int>(characterAId),
      'characterBId': serializer.toJson<int>(characterBId),
    };
  }

  CharacterReferenceRow copyWith({int? characterAId, int? characterBId}) =>
      CharacterReferenceRow(
        characterAId: characterAId ?? this.characterAId,
        characterBId: characterBId ?? this.characterBId,
      );
  CharacterReferenceRow copyWithCompanion(DbCharacterReferencesCompanion data) {
    return CharacterReferenceRow(
      characterAId: data.characterAId.present
          ? data.characterAId.value
          : this.characterAId,
      characterBId: data.characterBId.present
          ? data.characterBId.value
          : this.characterBId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CharacterReferenceRow(')
          ..write('characterAId: $characterAId, ')
          ..write('characterBId: $characterBId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(characterAId, characterBId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CharacterReferenceRow &&
          other.characterAId == this.characterAId &&
          other.characterBId == this.characterBId);
}

class DbCharacterReferencesCompanion
    extends UpdateCompanion<CharacterReferenceRow> {
  final Value<int> characterAId;
  final Value<int> characterBId;
  final Value<int> rowid;
  const DbCharacterReferencesCompanion({
    this.characterAId = const Value.absent(),
    this.characterBId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DbCharacterReferencesCompanion.insert({
    required int characterAId,
    required int characterBId,
    this.rowid = const Value.absent(),
  })  : characterAId = Value(characterAId),
        characterBId = Value(characterBId);
  static Insertable<CharacterReferenceRow> custom({
    Expression<int>? characterAId,
    Expression<int>? characterBId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (characterAId != null) 'character_a_id': characterAId,
      if (characterBId != null) 'character_b_id': characterBId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DbCharacterReferencesCompanion copyWith(
      {Value<int>? characterAId, Value<int>? characterBId, Value<int>? rowid}) {
    return DbCharacterReferencesCompanion(
      characterAId: characterAId ?? this.characterAId,
      characterBId: characterBId ?? this.characterBId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (characterAId.present) {
      map['character_a_id'] = Variable<int>(characterAId.value);
    }
    if (characterBId.present) {
      map['character_b_id'] = Variable<int>(characterBId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DbCharacterReferencesCompanion(')
          ..write('characterAId: $characterAId, ')
          ..write('characterBId: $characterBId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DbCharacterPhotosTable extends DbCharacterPhotos
    with TableInfo<$DbCharacterPhotosTable, CharacterPhotoRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DbCharacterPhotosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _characterIdMeta =
      const VerificationMeta('characterId');
  @override
  late final GeneratedColumn<int> characterId = GeneratedColumn<int>(
      'character_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _filePathMeta =
      const VerificationMeta('filePath');
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
      'file_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, characterId, filePath, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'character_photos';
  @override
  VerificationContext validateIntegrity(Insertable<CharacterPhotoRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('character_id')) {
      context.handle(
          _characterIdMeta,
          characterId.isAcceptableOrUnknown(
              data['character_id']!, _characterIdMeta));
    } else if (isInserting) {
      context.missing(_characterIdMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(_filePathMeta,
          filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta));
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CharacterPhotoRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CharacterPhotoRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      characterId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}character_id'])!,
      filePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_path'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $DbCharacterPhotosTable createAlias(String alias) {
    return $DbCharacterPhotosTable(attachedDatabase, alias);
  }
}

class CharacterPhotoRow extends DataClass
    implements Insertable<CharacterPhotoRow> {
  final int id;
  final int characterId;
  final String filePath;
  final DateTime createdAt;
  const CharacterPhotoRow(
      {required this.id,
      required this.characterId,
      required this.filePath,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['character_id'] = Variable<int>(characterId);
    map['file_path'] = Variable<String>(filePath);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DbCharacterPhotosCompanion toCompanion(bool nullToAbsent) {
    return DbCharacterPhotosCompanion(
      id: Value(id),
      characterId: Value(characterId),
      filePath: Value(filePath),
      createdAt: Value(createdAt),
    );
  }

  factory CharacterPhotoRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CharacterPhotoRow(
      id: serializer.fromJson<int>(json['id']),
      characterId: serializer.fromJson<int>(json['characterId']),
      filePath: serializer.fromJson<String>(json['filePath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'characterId': serializer.toJson<int>(characterId),
      'filePath': serializer.toJson<String>(filePath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CharacterPhotoRow copyWith(
          {int? id, int? characterId, String? filePath, DateTime? createdAt}) =>
      CharacterPhotoRow(
        id: id ?? this.id,
        characterId: characterId ?? this.characterId,
        filePath: filePath ?? this.filePath,
        createdAt: createdAt ?? this.createdAt,
      );
  CharacterPhotoRow copyWithCompanion(DbCharacterPhotosCompanion data) {
    return CharacterPhotoRow(
      id: data.id.present ? data.id.value : this.id,
      characterId:
          data.characterId.present ? data.characterId.value : this.characterId,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CharacterPhotoRow(')
          ..write('id: $id, ')
          ..write('characterId: $characterId, ')
          ..write('filePath: $filePath, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, characterId, filePath, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CharacterPhotoRow &&
          other.id == this.id &&
          other.characterId == this.characterId &&
          other.filePath == this.filePath &&
          other.createdAt == this.createdAt);
}

class DbCharacterPhotosCompanion extends UpdateCompanion<CharacterPhotoRow> {
  final Value<int> id;
  final Value<int> characterId;
  final Value<String> filePath;
  final Value<DateTime> createdAt;
  const DbCharacterPhotosCompanion({
    this.id = const Value.absent(),
    this.characterId = const Value.absent(),
    this.filePath = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  DbCharacterPhotosCompanion.insert({
    this.id = const Value.absent(),
    required int characterId,
    required String filePath,
    required DateTime createdAt,
  })  : characterId = Value(characterId),
        filePath = Value(filePath),
        createdAt = Value(createdAt);
  static Insertable<CharacterPhotoRow> custom({
    Expression<int>? id,
    Expression<int>? characterId,
    Expression<String>? filePath,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (characterId != null) 'character_id': characterId,
      if (filePath != null) 'file_path': filePath,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  DbCharacterPhotosCompanion copyWith(
      {Value<int>? id,
      Value<int>? characterId,
      Value<String>? filePath,
      Value<DateTime>? createdAt}) {
    return DbCharacterPhotosCompanion(
      id: id ?? this.id,
      characterId: characterId ?? this.characterId,
      filePath: filePath ?? this.filePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (characterId.present) {
      map['character_id'] = Variable<int>(characterId.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DbCharacterPhotosCompanion(')
          ..write('id: $id, ')
          ..write('characterId: $characterId, ')
          ..write('filePath: $filePath, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DbCharactersTable dbCharacters = $DbCharactersTable(this);
  late final $DbTagsTable dbTags = $DbTagsTable(this);
  late final $DbCharacterTagsTable dbCharacterTags =
      $DbCharacterTagsTable(this);
  late final $DbCharacterReferencesTable dbCharacterReferences =
      $DbCharacterReferencesTable(this);
  late final $DbCharacterPhotosTable dbCharacterPhotos =
      $DbCharacterPhotosTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        dbCharacters,
        dbTags,
        dbCharacterTags,
        dbCharacterReferences,
        dbCharacterPhotos
      ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$DbCharactersTableCreateCompanionBuilder = DbCharactersCompanion
    Function({
  Value<int> id,
  Value<String> typedCharacter,
  Value<String> definition,
  Value<String> notes,
  Value<bool> isStarred,
  Value<bool> isHard,
  Value<bool> isArchived,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<Uint8List?> handwriting,
  Value<int> timesSeen,
  Value<int> timesCorrect,
  Value<int> timesIncorrect,
  Value<DateTime?> lastReviewedAt,
});
typedef $$DbCharactersTableUpdateCompanionBuilder = DbCharactersCompanion
    Function({
  Value<int> id,
  Value<String> typedCharacter,
  Value<String> definition,
  Value<String> notes,
  Value<bool> isStarred,
  Value<bool> isHard,
  Value<bool> isArchived,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<Uint8List?> handwriting,
  Value<int> timesSeen,
  Value<int> timesCorrect,
  Value<int> timesIncorrect,
  Value<DateTime?> lastReviewedAt,
});

class $$DbCharactersTableFilterComposer
    extends Composer<_$AppDatabase, $DbCharactersTable> {
  $$DbCharactersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get typedCharacter => $composableBuilder(
      column: $table.typedCharacter,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get definition => $composableBuilder(
      column: $table.definition, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isStarred => $composableBuilder(
      column: $table.isStarred, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isHard => $composableBuilder(
      column: $table.isHard, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<Uint8List> get handwriting => $composableBuilder(
      column: $table.handwriting, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get timesSeen => $composableBuilder(
      column: $table.timesSeen, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get timesCorrect => $composableBuilder(
      column: $table.timesCorrect, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get timesIncorrect => $composableBuilder(
      column: $table.timesIncorrect,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastReviewedAt => $composableBuilder(
      column: $table.lastReviewedAt,
      builder: (column) => ColumnFilters(column));
}

class $$DbCharactersTableOrderingComposer
    extends Composer<_$AppDatabase, $DbCharactersTable> {
  $$DbCharactersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get typedCharacter => $composableBuilder(
      column: $table.typedCharacter,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get definition => $composableBuilder(
      column: $table.definition, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isStarred => $composableBuilder(
      column: $table.isStarred, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isHard => $composableBuilder(
      column: $table.isHard, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<Uint8List> get handwriting => $composableBuilder(
      column: $table.handwriting, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get timesSeen => $composableBuilder(
      column: $table.timesSeen, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get timesCorrect => $composableBuilder(
      column: $table.timesCorrect,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get timesIncorrect => $composableBuilder(
      column: $table.timesIncorrect,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastReviewedAt => $composableBuilder(
      column: $table.lastReviewedAt,
      builder: (column) => ColumnOrderings(column));
}

class $$DbCharactersTableAnnotationComposer
    extends Composer<_$AppDatabase, $DbCharactersTable> {
  $$DbCharactersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get typedCharacter => $composableBuilder(
      column: $table.typedCharacter, builder: (column) => column);

  GeneratedColumn<String> get definition => $composableBuilder(
      column: $table.definition, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get isStarred =>
      $composableBuilder(column: $table.isStarred, builder: (column) => column);

  GeneratedColumn<bool> get isHard =>
      $composableBuilder(column: $table.isHard, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<Uint8List> get handwriting => $composableBuilder(
      column: $table.handwriting, builder: (column) => column);

  GeneratedColumn<int> get timesSeen =>
      $composableBuilder(column: $table.timesSeen, builder: (column) => column);

  GeneratedColumn<int> get timesCorrect => $composableBuilder(
      column: $table.timesCorrect, builder: (column) => column);

  GeneratedColumn<int> get timesIncorrect => $composableBuilder(
      column: $table.timesIncorrect, builder: (column) => column);

  GeneratedColumn<DateTime> get lastReviewedAt => $composableBuilder(
      column: $table.lastReviewedAt, builder: (column) => column);
}

class $$DbCharactersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DbCharactersTable,
    CharacterRow,
    $$DbCharactersTableFilterComposer,
    $$DbCharactersTableOrderingComposer,
    $$DbCharactersTableAnnotationComposer,
    $$DbCharactersTableCreateCompanionBuilder,
    $$DbCharactersTableUpdateCompanionBuilder,
    (
      CharacterRow,
      BaseReferences<_$AppDatabase, $DbCharactersTable, CharacterRow>
    ),
    CharacterRow,
    PrefetchHooks Function()> {
  $$DbCharactersTableTableManager(_$AppDatabase db, $DbCharactersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DbCharactersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DbCharactersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DbCharactersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> typedCharacter = const Value.absent(),
            Value<String> definition = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<bool> isStarred = const Value.absent(),
            Value<bool> isHard = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<Uint8List?> handwriting = const Value.absent(),
            Value<int> timesSeen = const Value.absent(),
            Value<int> timesCorrect = const Value.absent(),
            Value<int> timesIncorrect = const Value.absent(),
            Value<DateTime?> lastReviewedAt = const Value.absent(),
          }) =>
              DbCharactersCompanion(
            id: id,
            typedCharacter: typedCharacter,
            definition: definition,
            notes: notes,
            isStarred: isStarred,
            isHard: isHard,
            isArchived: isArchived,
            createdAt: createdAt,
            updatedAt: updatedAt,
            handwriting: handwriting,
            timesSeen: timesSeen,
            timesCorrect: timesCorrect,
            timesIncorrect: timesIncorrect,
            lastReviewedAt: lastReviewedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> typedCharacter = const Value.absent(),
            Value<String> definition = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<bool> isStarred = const Value.absent(),
            Value<bool> isHard = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<Uint8List?> handwriting = const Value.absent(),
            Value<int> timesSeen = const Value.absent(),
            Value<int> timesCorrect = const Value.absent(),
            Value<int> timesIncorrect = const Value.absent(),
            Value<DateTime?> lastReviewedAt = const Value.absent(),
          }) =>
              DbCharactersCompanion.insert(
            id: id,
            typedCharacter: typedCharacter,
            definition: definition,
            notes: notes,
            isStarred: isStarred,
            isHard: isHard,
            isArchived: isArchived,
            createdAt: createdAt,
            updatedAt: updatedAt,
            handwriting: handwriting,
            timesSeen: timesSeen,
            timesCorrect: timesCorrect,
            timesIncorrect: timesIncorrect,
            lastReviewedAt: lastReviewedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DbCharactersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DbCharactersTable,
    CharacterRow,
    $$DbCharactersTableFilterComposer,
    $$DbCharactersTableOrderingComposer,
    $$DbCharactersTableAnnotationComposer,
    $$DbCharactersTableCreateCompanionBuilder,
    $$DbCharactersTableUpdateCompanionBuilder,
    (
      CharacterRow,
      BaseReferences<_$AppDatabase, $DbCharactersTable, CharacterRow>
    ),
    CharacterRow,
    PrefetchHooks Function()>;
typedef $$DbTagsTableCreateCompanionBuilder = DbTagsCompanion Function({
  Value<int> id,
  required String name,
});
typedef $$DbTagsTableUpdateCompanionBuilder = DbTagsCompanion Function({
  Value<int> id,
  Value<String> name,
});

class $$DbTagsTableFilterComposer
    extends Composer<_$AppDatabase, $DbTagsTable> {
  $$DbTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));
}

class $$DbTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $DbTagsTable> {
  $$DbTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));
}

class $$DbTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DbTagsTable> {
  $$DbTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);
}

class $$DbTagsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DbTagsTable,
    TagRow,
    $$DbTagsTableFilterComposer,
    $$DbTagsTableOrderingComposer,
    $$DbTagsTableAnnotationComposer,
    $$DbTagsTableCreateCompanionBuilder,
    $$DbTagsTableUpdateCompanionBuilder,
    (TagRow, BaseReferences<_$AppDatabase, $DbTagsTable, TagRow>),
    TagRow,
    PrefetchHooks Function()> {
  $$DbTagsTableTableManager(_$AppDatabase db, $DbTagsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DbTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DbTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DbTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
          }) =>
              DbTagsCompanion(
            id: id,
            name: name,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
          }) =>
              DbTagsCompanion.insert(
            id: id,
            name: name,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DbTagsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DbTagsTable,
    TagRow,
    $$DbTagsTableFilterComposer,
    $$DbTagsTableOrderingComposer,
    $$DbTagsTableAnnotationComposer,
    $$DbTagsTableCreateCompanionBuilder,
    $$DbTagsTableUpdateCompanionBuilder,
    (TagRow, BaseReferences<_$AppDatabase, $DbTagsTable, TagRow>),
    TagRow,
    PrefetchHooks Function()>;
typedef $$DbCharacterTagsTableCreateCompanionBuilder = DbCharacterTagsCompanion
    Function({
  required int characterId,
  required int tagId,
  Value<int> position,
  Value<int> rowid,
});
typedef $$DbCharacterTagsTableUpdateCompanionBuilder = DbCharacterTagsCompanion
    Function({
  Value<int> characterId,
  Value<int> tagId,
  Value<int> position,
  Value<int> rowid,
});

class $$DbCharacterTagsTableFilterComposer
    extends Composer<_$AppDatabase, $DbCharacterTagsTable> {
  $$DbCharacterTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get characterId => $composableBuilder(
      column: $table.characterId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get tagId => $composableBuilder(
      column: $table.tagId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnFilters(column));
}

class $$DbCharacterTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $DbCharacterTagsTable> {
  $$DbCharacterTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get characterId => $composableBuilder(
      column: $table.characterId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get tagId => $composableBuilder(
      column: $table.tagId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnOrderings(column));
}

class $$DbCharacterTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DbCharacterTagsTable> {
  $$DbCharacterTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get characterId => $composableBuilder(
      column: $table.characterId, builder: (column) => column);

  GeneratedColumn<int> get tagId =>
      $composableBuilder(column: $table.tagId, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);
}

class $$DbCharacterTagsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DbCharacterTagsTable,
    CharacterTagRow,
    $$DbCharacterTagsTableFilterComposer,
    $$DbCharacterTagsTableOrderingComposer,
    $$DbCharacterTagsTableAnnotationComposer,
    $$DbCharacterTagsTableCreateCompanionBuilder,
    $$DbCharacterTagsTableUpdateCompanionBuilder,
    (
      CharacterTagRow,
      BaseReferences<_$AppDatabase, $DbCharacterTagsTable, CharacterTagRow>
    ),
    CharacterTagRow,
    PrefetchHooks Function()> {
  $$DbCharacterTagsTableTableManager(
      _$AppDatabase db, $DbCharacterTagsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DbCharacterTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DbCharacterTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DbCharacterTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> characterId = const Value.absent(),
            Value<int> tagId = const Value.absent(),
            Value<int> position = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DbCharacterTagsCompanion(
            characterId: characterId,
            tagId: tagId,
            position: position,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int characterId,
            required int tagId,
            Value<int> position = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DbCharacterTagsCompanion.insert(
            characterId: characterId,
            tagId: tagId,
            position: position,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DbCharacterTagsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DbCharacterTagsTable,
    CharacterTagRow,
    $$DbCharacterTagsTableFilterComposer,
    $$DbCharacterTagsTableOrderingComposer,
    $$DbCharacterTagsTableAnnotationComposer,
    $$DbCharacterTagsTableCreateCompanionBuilder,
    $$DbCharacterTagsTableUpdateCompanionBuilder,
    (
      CharacterTagRow,
      BaseReferences<_$AppDatabase, $DbCharacterTagsTable, CharacterTagRow>
    ),
    CharacterTagRow,
    PrefetchHooks Function()>;
typedef $$DbCharacterReferencesTableCreateCompanionBuilder
    = DbCharacterReferencesCompanion Function({
  required int characterAId,
  required int characterBId,
  Value<int> rowid,
});
typedef $$DbCharacterReferencesTableUpdateCompanionBuilder
    = DbCharacterReferencesCompanion Function({
  Value<int> characterAId,
  Value<int> characterBId,
  Value<int> rowid,
});

class $$DbCharacterReferencesTableFilterComposer
    extends Composer<_$AppDatabase, $DbCharacterReferencesTable> {
  $$DbCharacterReferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get characterAId => $composableBuilder(
      column: $table.characterAId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get characterBId => $composableBuilder(
      column: $table.characterBId, builder: (column) => ColumnFilters(column));
}

class $$DbCharacterReferencesTableOrderingComposer
    extends Composer<_$AppDatabase, $DbCharacterReferencesTable> {
  $$DbCharacterReferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get characterAId => $composableBuilder(
      column: $table.characterAId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get characterBId => $composableBuilder(
      column: $table.characterBId,
      builder: (column) => ColumnOrderings(column));
}

class $$DbCharacterReferencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DbCharacterReferencesTable> {
  $$DbCharacterReferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get characterAId => $composableBuilder(
      column: $table.characterAId, builder: (column) => column);

  GeneratedColumn<int> get characterBId => $composableBuilder(
      column: $table.characterBId, builder: (column) => column);
}

class $$DbCharacterReferencesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DbCharacterReferencesTable,
    CharacterReferenceRow,
    $$DbCharacterReferencesTableFilterComposer,
    $$DbCharacterReferencesTableOrderingComposer,
    $$DbCharacterReferencesTableAnnotationComposer,
    $$DbCharacterReferencesTableCreateCompanionBuilder,
    $$DbCharacterReferencesTableUpdateCompanionBuilder,
    (
      CharacterReferenceRow,
      BaseReferences<_$AppDatabase, $DbCharacterReferencesTable,
          CharacterReferenceRow>
    ),
    CharacterReferenceRow,
    PrefetchHooks Function()> {
  $$DbCharacterReferencesTableTableManager(
      _$AppDatabase db, $DbCharacterReferencesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DbCharacterReferencesTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$DbCharacterReferencesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DbCharacterReferencesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> characterAId = const Value.absent(),
            Value<int> characterBId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DbCharacterReferencesCompanion(
            characterAId: characterAId,
            characterBId: characterBId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int characterAId,
            required int characterBId,
            Value<int> rowid = const Value.absent(),
          }) =>
              DbCharacterReferencesCompanion.insert(
            characterAId: characterAId,
            characterBId: characterBId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DbCharacterReferencesTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $DbCharacterReferencesTable,
        CharacterReferenceRow,
        $$DbCharacterReferencesTableFilterComposer,
        $$DbCharacterReferencesTableOrderingComposer,
        $$DbCharacterReferencesTableAnnotationComposer,
        $$DbCharacterReferencesTableCreateCompanionBuilder,
        $$DbCharacterReferencesTableUpdateCompanionBuilder,
        (
          CharacterReferenceRow,
          BaseReferences<_$AppDatabase, $DbCharacterReferencesTable,
              CharacterReferenceRow>
        ),
        CharacterReferenceRow,
        PrefetchHooks Function()>;
typedef $$DbCharacterPhotosTableCreateCompanionBuilder
    = DbCharacterPhotosCompanion Function({
  Value<int> id,
  required int characterId,
  required String filePath,
  required DateTime createdAt,
});
typedef $$DbCharacterPhotosTableUpdateCompanionBuilder
    = DbCharacterPhotosCompanion Function({
  Value<int> id,
  Value<int> characterId,
  Value<String> filePath,
  Value<DateTime> createdAt,
});

class $$DbCharacterPhotosTableFilterComposer
    extends Composer<_$AppDatabase, $DbCharacterPhotosTable> {
  $$DbCharacterPhotosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get characterId => $composableBuilder(
      column: $table.characterId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$DbCharacterPhotosTableOrderingComposer
    extends Composer<_$AppDatabase, $DbCharacterPhotosTable> {
  $$DbCharacterPhotosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get characterId => $composableBuilder(
      column: $table.characterId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$DbCharacterPhotosTableAnnotationComposer
    extends Composer<_$AppDatabase, $DbCharacterPhotosTable> {
  $$DbCharacterPhotosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get characterId => $composableBuilder(
      column: $table.characterId, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$DbCharacterPhotosTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DbCharacterPhotosTable,
    CharacterPhotoRow,
    $$DbCharacterPhotosTableFilterComposer,
    $$DbCharacterPhotosTableOrderingComposer,
    $$DbCharacterPhotosTableAnnotationComposer,
    $$DbCharacterPhotosTableCreateCompanionBuilder,
    $$DbCharacterPhotosTableUpdateCompanionBuilder,
    (
      CharacterPhotoRow,
      BaseReferences<_$AppDatabase, $DbCharacterPhotosTable, CharacterPhotoRow>
    ),
    CharacterPhotoRow,
    PrefetchHooks Function()> {
  $$DbCharacterPhotosTableTableManager(
      _$AppDatabase db, $DbCharacterPhotosTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DbCharacterPhotosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DbCharacterPhotosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DbCharacterPhotosTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> characterId = const Value.absent(),
            Value<String> filePath = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              DbCharacterPhotosCompanion(
            id: id,
            characterId: characterId,
            filePath: filePath,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int characterId,
            required String filePath,
            required DateTime createdAt,
          }) =>
              DbCharacterPhotosCompanion.insert(
            id: id,
            characterId: characterId,
            filePath: filePath,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DbCharacterPhotosTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DbCharacterPhotosTable,
    CharacterPhotoRow,
    $$DbCharacterPhotosTableFilterComposer,
    $$DbCharacterPhotosTableOrderingComposer,
    $$DbCharacterPhotosTableAnnotationComposer,
    $$DbCharacterPhotosTableCreateCompanionBuilder,
    $$DbCharacterPhotosTableUpdateCompanionBuilder,
    (
      CharacterPhotoRow,
      BaseReferences<_$AppDatabase, $DbCharacterPhotosTable, CharacterPhotoRow>
    ),
    CharacterPhotoRow,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DbCharactersTableTableManager get dbCharacters =>
      $$DbCharactersTableTableManager(_db, _db.dbCharacters);
  $$DbTagsTableTableManager get dbTags =>
      $$DbTagsTableTableManager(_db, _db.dbTags);
  $$DbCharacterTagsTableTableManager get dbCharacterTags =>
      $$DbCharacterTagsTableTableManager(_db, _db.dbCharacterTags);
  $$DbCharacterReferencesTableTableManager get dbCharacterReferences =>
      $$DbCharacterReferencesTableTableManager(_db, _db.dbCharacterReferences);
  $$DbCharacterPhotosTableTableManager get dbCharacterPhotos =>
      $$DbCharacterPhotosTableTableManager(_db, _db.dbCharacterPhotos);
}
