import '../data/character_entry.dart';
import 'list_filter_button.dart';

/// The **Language** group in the list screens' filter sheet (2026-09-26):
/// Cantonese, Mandarin and Not set. Shared by the home list, the archive
/// and the photo gallery, so all three offer the same choices and read
/// them the same way.
///
/// - **Cantonese** shows words marked Cantonese, including ones marked
///   both; **Mandarin** likewise.
/// - **Cantonese + Mandarin** together (like every toggle in the sheet,
///   they combine with AND) shows only the words marked both.
/// - **Not set** shows characters with no language yet. It can't be
///   combined with the other two — that could only ever show nothing — so
///   [enforceLanguageRule] turns them off when it goes on, and it off when
///   either of them goes on.
class LanguageFilterOptions {
  LanguageFilterOptions._();

  static const cantonese = 'lang_cantonese';
  static const mandarin = 'lang_mandarin';
  static const notSet = 'lang_not_set';

  static const section = 'Language';

  static const options = [
    ListFilterOption(id: cantonese, label: 'Cantonese', section: section),
    ListFilterOption(id: mandarin, label: 'Mandarin', section: section),
    ListFilterOption(id: notSet, label: 'Not set', section: section),
  ];

  /// Whether [c] passes the language toggles that are on in [filters].
  static bool matches(ListFilters filters, CharacterEntry c) {
    if (filters.isOn(cantonese) && !c.isCantonese) return false;
    if (filters.isOn(mandarin) && !c.isMandarin) return false;
    if (filters.isOn(notSet) && c.hasLanguage) return false;
    return true;
  }

  /// Whether any language toggle is on in [filters].
  static bool anyOn(ListFilters filters) =>
      filters.isOn(cantonese) || filters.isOn(mandarin) || filters.isOn(notSet);

  /// [requested] with Not set made exclusive of Cantonese / Mandarin:
  /// whichever was just turned on wins. [previous] is what was applied
  /// before, to tell which one that was.
  static ListFilters enforceLanguageRule(
    ListFilters requested,
    ListFilters previous,
  ) {
    final on = {...requested.on};
    bool turnedOn(String id) => on.contains(id) && !previous.isOn(id);
    if (turnedOn(notSet)) {
      on
        ..remove(cantonese)
        ..remove(mandarin);
    } else if (turnedOn(cantonese) || turnedOn(mandarin)) {
      on.remove(notSet);
    }
    return requested.copyWith(on: on);
  }
}
