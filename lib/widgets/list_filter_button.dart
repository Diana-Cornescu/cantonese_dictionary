import 'package:flutter/material.dart';

import 'filter_icon_button.dart';

/// Which end of the list comes first. Both the home list and the photo
/// gallery sort by the date something was added (1.6.0).
enum SortOrder { newestFirst, oldestFirst }

/// Reads a sort order saved with [sortOrderSettingValue]. Anything missing
/// or unrecognised means [SortOrder.newestFirst], the default on every
/// screen (decided 2026-09-25).
SortOrder sortOrderFromSetting(String? value) =>
    value == 'oldest' ? SortOrder.oldestFirst : SortOrder.newestFirst;

/// How a sort order is stored in the `app_settings` table.
String sortOrderSettingValue(SortOrder order) =>
    order == SortOrder.oldestFirst ? 'oldest' : 'newest';

/// One "show only" toggle in the filter sheet, e.g. favorites.
class ListFilterOption {
  const ListFilterOption({
    required this.id,
    required this.label,
    this.icon,
    this.color,
    this.section = defaultSection,
  });

  /// The heading options are listed under unless they say otherwise.
  static const defaultSection = 'Show only';

  /// Stable key used in [ListFilters.on].
  final String id;
  final String label;

  /// Null for an option whose label says it all, like the Language ones.
  final IconData? icon;

  /// The heading this option is listed under in the sheet (2026-09-26,
  /// for the Language group). Sections appear in the order their first
  /// option does. Every toggle still narrows the list the same way,
  /// whatever its section: they all combine with AND.
  final String section;

  /// The icon's meaning color (gold favorite, red hard), or null for a
  /// filter with no color of its own, like the gallery's unlinked.
  final Color? color;
}

/// What a list is currently showing: which toggles are on, and the order.
@immutable
class ListFilters {
  const ListFilters({
    this.on = const <String>{},
    this.sort = SortOrder.newestFirst,
  });

  final Set<String> on;
  final SortOrder sort;

  bool isOn(String id) => on.contains(id);

  /// True while any toggle is narrowing the list. The sort order doesn't
  /// count: it reorders, it never hides anything.
  bool get isFiltering => on.isNotEmpty;

  ListFilters copyWith({Set<String>? on, SortOrder? sort}) =>
      ListFilters(on: on ?? this.on, sort: sort ?? this.sort);
}

/// The single filter icon next to a list's search box (1.6.0). It replaced
/// the separate ⭐ / 🔥 / 🔗 buttons that sat there in 1.4.0–1.5.0.
///
/// Tapping it opens a sheet with the "show only" toggles, the sort order
/// and **Clear filters**. The icon wears the same "on" look as the old
/// buttons (black outline, pale grey fill) while any toggle is on, so a
/// filtered list still says so at a glance. A non-default sort doesn't
/// light it up: it's a remembered preference, not a filter.
///
/// [onChanged] receives what was asked for and returns what the screen
/// actually applied. That lets a screen enforce its own rules — the
/// gallery turns ⭐ and 🔥 off when 🔗 unlinked goes on — and the open
/// sheet shows the result straight away.
class ListFilterButton extends StatelessWidget {
  const ListFilterButton({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<ListFilterOption> options;
  final ListFilters value;
  final ListFilters Function(ListFilters requested) onChanged;

  @override
  Widget build(BuildContext context) {
    return FilterIconButton(
      tooltip: 'Filter and sort',
      on: value.isFiltering,
      onIcon: Icons.filter_list,
      onPressed: () => _openSheet(context),
    );
  }

  Future<void> _openSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      // Grows to fit everything, like the flashcard options panel, instead
      // of stopping at Flutter's default of about half the screen and
      // scrolling (2026-09-25). It still scrolls on a screen too short to
      // fit it.
      isScrollControlled: true,
      builder: (sheetContext) {
        // The sheet keeps its own copy so it redraws as things are tapped;
        // every change goes through onChanged first, so the copy is always
        // what the screen really applied.
        var current = value;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void apply(ListFilters requested) {
              final applied = onChanged(requested);
              setSheetState(() => current = applied);
            }

            final textTheme = Theme.of(context).textTheme;
            final sections = <String>[];
            for (final option in options) {
              if (!sections.contains(option.section)) {
                sections.add(option.section);
              }
            }
            return SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, section) in sections.indexed) ...[
                      if (i > 0) const Divider(height: 24),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                        child: Text(section, style: textTheme.titleMedium),
                      ),
                      for (final option
                          in options.where((o) => o.section == section))
                        CheckboxListTile(
                          value: current.isOn(option.id),
                          secondary: option.icon == null
                              ? null
                              : Icon(option.icon, color: option.color),
                          title: Text(option.label),
                          onChanged: (checked) {
                            final on = {...current.on};
                            if (checked ?? false) {
                              on.add(option.id);
                            } else {
                              on.remove(option.id);
                            }
                            apply(current.copyWith(on: on));
                          },
                        ),
                    ],
                    const Divider(height: 24),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                      child: Text('Sort', style: textTheme.titleMedium),
                    ),
                    for (final (order, label) in const [
                      (SortOrder.newestFirst, 'Newest first'),
                      (SortOrder.oldestFirst, 'Oldest first'),
                    ])
                      // A plain ListTile drawn as a radio button, rather
                      // than RadioListTile, whose groupValue/onChanged are
                      // deprecated in newer Flutter versions.
                      ListTile(
                        leading: Icon(current.sort == order
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked),
                        title: Text(label),
                        selected: current.sort == order,
                        onTap: () => apply(current.copyWith(sort: order)),
                      ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: OutlinedButton.icon(
                        // Clears the toggles only. The sort order is a
                        // remembered preference, and the search box has its
                        // own ✕.
                        onPressed: current.isFiltering
                            ? () {
                                apply(current.copyWith(on: const <String>{}));
                                Navigator.pop(sheetContext);
                              }
                            : null,
                        icon: const Icon(Icons.filter_list_off),
                        label: const Text('Clear filters'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
