/// One photo of characters seen "out and about" (see
/// docs/decisions_log_photo_gallery.md). Plain immutable value type, like
/// `CharacterEntry`; only `DictionaryStore` changes photos.
class PhotoEntry {
  const PhotoEntry({
    required this.id,
    required this.fileName,
    required this.note,
    required this.createdAt,
    required this.characterIds,
  });

  final int id;

  /// File name inside the app's photos folder (not a full path).
  final String fileName;

  /// Optional note, e.g. where it was taken. Empty string = no note.
  final String note;

  final DateTime createdAt;

  /// The characters this photo shows. Can be empty (a photo whose
  /// characters were all unlinked or deleted still shows in the gallery).
  final List<int> characterIds;

  PhotoEntry copyWith({String? note, List<int>? characterIds}) {
    return PhotoEntry(
      id: id,
      fileName: fileName,
      note: note ?? this.note,
      createdAt: createdAt,
      characterIds: characterIds ?? this.characterIds,
    );
  }
}
