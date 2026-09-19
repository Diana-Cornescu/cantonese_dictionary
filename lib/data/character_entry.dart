/// Plain-Dart data models for the dictionary. No Flutter imports on
/// purpose: this file should be usable from pure `dart:core` code and from
/// tests without pulling in the widget layer.
///
/// Since the move to SQLite + Drift (see
/// `docs/decisions_log_sqlite_drift.md`), these classes are what the rest of
/// the app sees; `app_database.dart` converts them to and from database
/// rows. The `toJson`/`fromJson` methods are no longer used for storage and
/// are kept only as a starting point for the future backup/restore feature.
library;

/// Splits a comma-separated tag string (as typed by the user, and as held
/// in [CharacterEntry.tags]) into trimmed, non-empty, de-duplicated tag
/// names, keeping the order they were typed in.
List<String> parseTags(String raw) {
  final seen = <String>{};
  final result = <String>[];
  for (final part in raw.split(',')) {
    final tag = part.trim();
    if (tag.isNotEmpty && seen.add(tag)) result.add(tag);
  }
  return result;
}

/// A single recorded point of a handwriting stroke, in canvas-local
/// coordinates, with a millisecond timestamp `t` (used to distinguish
/// separate strokes / support future replay — not currently displayed).
class StrokePoint {
  const StrokePoint({required this.x, required this.y, required this.t});

  final double x;
  final double y;
  final int t;

  factory StrokePoint.fromJson(Map<String, dynamic> json) {
    return StrokePoint(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      t: (json['t'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {'x': x, 'y': y, 't': t};
}

/// Flashcard-mode review counters for one character. Zeroed by default.
class FlashcardStats {
  const FlashcardStats({
    this.timesSeen = 0,
    this.timesCorrect = 0,
    this.timesIncorrect = 0,
    this.lastReviewedAt,
  });

  /// A freshly-seeded, never-reviewed stats block.
  static const FlashcardStats zero = FlashcardStats();

  final int timesSeen;
  final int timesCorrect;
  final int timesIncorrect;
  final DateTime? lastReviewedAt;

  FlashcardStats copyWith({
    int? timesSeen,
    int? timesCorrect,
    int? timesIncorrect,
    DateTime? lastReviewedAt,
  }) {
    return FlashcardStats(
      timesSeen: timesSeen ?? this.timesSeen,
      timesCorrect: timesCorrect ?? this.timesCorrect,
      timesIncorrect: timesIncorrect ?? this.timesIncorrect,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
    );
  }

  factory FlashcardStats.fromJson(Map<String, dynamic> json) {
    return FlashcardStats(
      timesSeen: (json['timesSeen'] as num?)?.toInt() ?? 0,
      timesCorrect: (json['timesCorrect'] as num?)?.toInt() ?? 0,
      timesIncorrect: (json['timesIncorrect'] as num?)?.toInt() ?? 0,
      lastReviewedAt: json['lastReviewedAt'] == null
          ? null
          : DateTime.parse(json['lastReviewedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'timesSeen': timesSeen,
        'timesCorrect': timesCorrect,
        'timesIncorrect': timesIncorrect,
        'lastReviewedAt': lastReviewedAt?.toIso8601String(),
      };

  @override
  bool operator ==(Object other) {
    return other is FlashcardStats &&
        other.timesSeen == timesSeen &&
        other.timesCorrect == timesCorrect &&
        other.timesIncorrect == timesIncorrect &&
        other.lastReviewedAt == lastReviewedAt;
  }

  @override
  int get hashCode =>
      Object.hash(timesSeen, timesCorrect, timesIncorrect, lastReviewedAt);
}

/// One dictionary entry: a typed character plus everything the user has
/// attached to it. This class is intentionally a plain immutable value type
/// (`copyWith` instead of mutable fields) so `DictionaryStore` is the only
/// place that decides when something actually changes and gets saved.
class CharacterEntry {
  const CharacterEntry({
    required this.id,
    required this.typedCharacter,
    required this.handwrittenSample,
    required this.definition,
    required this.notes,
    required this.tags,
    required this.isStarred,
    required this.isHard,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
    required this.flashcardStats,
    required this.referencedCharacterIds,
  });

  final int id;
  final String typedCharacter;

  /// The current handwriting sample only. Redrawing overwrites this
  /// wholesale; no drawing history is ever kept. `null` means no sample has
  /// been recorded yet.
  final List<List<StrokePoint>>? handwrittenSample;

  final String definition;
  final String notes;

  /// Tags as one comma-separated string (e.g. `"food, verb"`), which is
  /// what the screens display and edit. In the database they are stored
  /// properly in the `tags` + `character_tags` tables; [DictionaryStore]
  /// splits this string with [parseTags] on save and re-joins it with
  /// `", "` on load.
  final String tags;

  final bool isStarred;
  final bool isHard;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;
  final FlashcardStats flashcardStats;

  /// Undirected/symmetric references to other characters. Only ever
  /// modified via `DictionaryStore.addReference` / `removeReference` — do
  /// not construct a [CharacterEntry] with a hand-edited version of this
  /// list outside those two code paths.
  final List<int> referencedCharacterIds;

  /// Returns a copy with the given fields replaced. Passing
  /// `handwrittenSample: null` explicitly clears the drawing; omitting it
  /// leaves the existing sample untouched (it uses a sentinel default, not
  /// plain `??`, specifically so "clear" and "leave alone" are distinct).
  CharacterEntry copyWith({
    int? id,
    String? typedCharacter,
    Object? handwrittenSample = _unset,
    String? definition,
    String? notes,
    String? tags,
    bool? isStarred,
    bool? isHard,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
    FlashcardStats? flashcardStats,
    List<int>? referencedCharacterIds,
  }) {
    return CharacterEntry(
      id: id ?? this.id,
      typedCharacter: typedCharacter ?? this.typedCharacter,
      handwrittenSample: identical(handwrittenSample, _unset)
          ? this.handwrittenSample
          : handwrittenSample as List<List<StrokePoint>>?,
      definition: definition ?? this.definition,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      isStarred: isStarred ?? this.isStarred,
      isHard: isHard ?? this.isHard,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      flashcardStats: flashcardStats ?? this.flashcardStats,
      referencedCharacterIds:
          referencedCharacterIds ?? this.referencedCharacterIds,
    );
  }

  factory CharacterEntry.fromJson(Map<String, dynamic> json) {
    return CharacterEntry(
      id: (json['id'] as num).toInt(),
      typedCharacter: json['typedCharacter'] as String,
      handwrittenSample: _strokesFromJson(json['handwrittenSample']),
      definition: json['definition'] as String,
      notes: json['notes'] as String,
      tags: json['tags'] as String,
      isStarred: json['isStarred'] as bool,
      isHard: json['isHard'] as bool,
      isArchived: json['isArchived'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      flashcardStats: FlashcardStats.fromJson(
        json['flashcardStats'] as Map<String, dynamic>,
      ),
      referencedCharacterIds: (json['referencedCharacterIds'] as List<dynamic>? ??
              const [])
          .map((e) => (e as num).toInt())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'typedCharacter': typedCharacter,
        'handwrittenSample': _strokesToJson(handwrittenSample),
        'definition': definition,
        'notes': notes,
        'tags': tags,
        'isStarred': isStarred,
        'isHard': isHard,
        'isArchived': isArchived,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'flashcardStats': flashcardStats.toJson(),
        'referencedCharacterIds': referencedCharacterIds,
      };
}

/// Sentinel used only by [CharacterEntry.copyWith] to distinguish "argument
/// not passed" from "argument explicitly passed as null".
class _Unset {
  const _Unset();
}

const _unset = _Unset();

List<List<StrokePoint>>? _strokesFromJson(dynamic raw) {
  if (raw == null) return null;
  final strokes = raw as List<dynamic>;
  return strokes
      .map((stroke) => (stroke as List<dynamic>)
          .map((point) => StrokePoint.fromJson(point as Map<String, dynamic>))
          .toList())
      .toList();
}

dynamic _strokesToJson(List<List<StrokePoint>>? strokes) {
  if (strokes == null) return null;
  return strokes
      .map((stroke) => stroke.map((point) => point.toJson()).toList())
      .toList();
}
