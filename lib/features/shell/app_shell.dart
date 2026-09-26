import 'package:flutter/material.dart';

import '../../data/dictionary_store.dart';
import '../add_character/add_character_screen.dart';
import '../dictionary_list/dictionary_list_screen.dart';
import '../flashcards/flashcard_mode_screen.dart';
import '../photos/gallery_screen.dart';
import '../photos/photo_picking.dart';
import '../settings/settings_screen.dart';
import '../write/write_practice_screen.dart';

/// The four tabs, in bar order. The round center button sits between
/// [photos] and [write].
///
/// [write] took the slot Tags had (2026-09-25); Tags is now a row in
/// Settings until it has a permanent home (see the roadmap).
enum AppTab {
  characters('Characters', Icons.menu_book, Icons.menu_book_outlined),
  photos('Photos', Icons.photo_library, Icons.photo_library_outlined),
  write('Write', Icons.draw, Icons.draw_outlined),
  flashcards('Flashcards', Icons.style, Icons.style_outlined);

  const AppTab(this.label, this.selectedIcon, this.icon);
  final String label;
  final IconData selectedIcon;
  final IconData icon;
}

/// The app's frame since 1.6.0: an Instagram-style bar along the bottom
/// with four tabs and a slightly larger round button in the middle. It
/// replaced the ☰ side menu, the home screen's Add character bar and the
/// + buttons floating on Photos and Tags. The Write tab replaced Tags on
/// 2026-09-25.
///
/// **Each tab has its own [Navigator]**, so opening a character, photo or
/// tag happens *inside* the tab and the bar stays visible. Switching tabs
/// and back returns to where you were (a flashcard or writing round in
/// progress included). Tapping the tab you're already on goes back to its
/// top screen, which is why the inner screens no longer have Home buttons.
///
/// **The center button** does the current tab's main action:
///  - Characters: **+** opens Add character.
///  - Photos: **+** takes or picks a photo, then asks which characters.
///  - Write: **…** opens the writing options; tapping it again closes
///    them.
///  - Flashcards: **…** opens the flashcard options; tapping it again
///    closes them.
///
/// **Android back button:** goes back inside the current tab first; on a
/// tab's top screen it switches to Characters; on Characters it leaves the
/// app as usual.
///
/// Tabs are built the first time they're opened rather than all at start
/// up, so launching the app costs the same as before.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.store});

  final DictionaryStore store;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppTab _tab = AppTab.characters;

  /// Tabs opened at least once; the others aren't built yet.
  final Set<AppTab> _visited = {AppTab.characters};

  final Map<AppTab, GlobalKey<NavigatorState>> _navigators = {
    for (final tab in AppTab.values) tab: GlobalKey<NavigatorState>(),
  };

  /// One per tab, made once: rebuilds the shell after any push or pop in
  /// that tab, so the back-button rule ([_backLeavesApp]) stays current,
  /// and knows whether Settings is open in it ([_closeSettings]).
  late final Map<AppTab, _TabObserver> _observers = {
    for (final tab in AppTab.values)
      tab: _TabObserver(() {
        if (mounted) setState(() {});
      }),
  };

  /// Closes Settings in [tab], along with anything opened from it (the
  /// Archive). Settings is somewhere you step into and out of, not a place
  /// a tab should stay, so **any use of the bar leaves it** (2026-09-25):
  /// switching tabs, tapping the current tab, or the round button. Before
  /// this, switching away and back showed Settings again instead of the
  /// tab. Other screens (a character, a photo) still keep their place.
  void _closeSettings(AppTab tab) {
    if (!_observers[tab]!.hasSettings) return;
    var passedSettings = false;
    // Pops from the top down to and including Settings, then stops.
    _navigators[tab]!.currentState?.popUntil((route) {
      if (passedSettings) return true;
      if (route.settings.name == SettingsScreen.routeName) {
        passedSettings = true;
      }
      return false;
    });
  }

  /// Lets the center button open the flashcard options, and lets the tab
  /// refresh its cards when it's shown again.
  final _flashcards = GlobalKey<FlashcardModeScreenState>();

  /// The same two jobs for the Write tab.
  final _write = GlobalKey<WritePracticeScreenState>();

  DictionaryStore get store => widget.store;

  NavigatorState? get _currentNavigator => _navigators[_tab]!.currentState;

  Widget _rootScreen(AppTab tab) => switch (tab) {
        AppTab.characters => DictionaryListScreen(store: store),
        AppTab.photos => GalleryScreen(store: store),
        AppTab.write => WritePracticeScreen(key: _write, store: store),
        AppTab.flashcards =>
          FlashcardModeScreen(key: _flashcards, store: store),
      };

  void _selectTab(AppTab tab) {
    if (tab == _tab) {
      // Same tab again: back to its top screen (which closes Settings too).
      _currentNavigator?.popUntil((route) => route.isFirst);
      return;
    }
    // Leaving this tab: don't leave Settings open in it.
    _closeSettings(_tab);
    // Don't leave an options panel open behind another tab.
    if (_tab == AppTab.flashcards) _flashcards.currentState?.closeOptions();
    if (_tab == AppTab.write) _write.currentState?.closeOptions();
    setState(() {
      _tab = tab;
      _visited.add(tab);
    });
    if (tab == AppTab.flashcards) {
      // Characters may have been added, edited, flagged or deleted in
      // another tab since the round started.
      _flashcards.currentState?.refreshCards();
    }
    if (tab == AppTab.write) _write.currentState?.refreshCards();
  }

  Future<void> _centerAction() async {
    final navigator = _currentNavigator;
    if (navigator == null) return;
    // + from inside Settings should add to the tab, not stack on Settings.
    _closeSettings(_tab);
    // The tab navigator's own context, so sheets open inside the tab.
    final tabContext = navigator.context;
    switch (_tab) {
      case AppTab.characters:
        navigator.push(MaterialPageRoute(
          builder: (_) => AddCharacterScreen(store: store),
        ));
      case AppTab.photos:
        await addPhotoWithCharacters(tabContext, store);
      case AppTab.write:
        final write = _write.currentState;
        if (write != null && write.optionsOpen) {
          write.closeOptions();
          return;
        }
        navigator.popUntil((route) => route.isFirst);
        await write?.openOptions();
      case AppTab.flashcards:
        final flashcards = _flashcards.currentState;
        // A second tap on … closes the panel it opened.
        if (flashcards != null && flashcards.optionsOpen) {
          flashcards.closeOptions();
          return;
        }
        // The options belong to the round itself, so come back to it first
        // (e.g. from a character opened with "Go to character screen").
        navigator.popUntil((route) => route.isFirst);
        await flashcards?.openOptions();
    }
  }

  void _handleBack() {
    final navigator = _currentNavigator;
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
    } else if (_tab != AppTab.characters) {
      _selectTab(AppTab.characters);
    }
  }

  /// Only lets the system close the app from the Characters tab's top
  /// screen; everywhere else, back is handled by [_handleBack].
  bool get _backLeavesApp =>
      _tab == AppTab.characters && !(_currentNavigator?.canPop() ?? false);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _backLeavesApp,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        body: IndexedStack(
          index: _tab.index,
          children: [
            for (final tab in AppTab.values)
              if (_visited.contains(tab))
                // A tab's own navigator. Rebuilding here is cheap: the key
                // keeps the same navigator (and its screens) alive.
                Navigator(
                  key: _navigators[tab],
                  observers: [_observers[tab]!],
                  onGenerateRoute: (_) => MaterialPageRoute(
                    builder: (_) => _rootScreen(tab),
                  ),
                )
              else
                const SizedBox.shrink(),
          ],
        ),
        bottomNavigationBar: _BottomBar(
          current: _tab,
          onTab: _selectTab,
          centerIcon: _tab == AppTab.flashcards || _tab == AppTab.write
              ? Icons.more_horiz
              : Icons.add,
          centerTooltip: switch (_tab) {
            AppTab.characters => 'Add character',
            AppTab.photos => 'Add photo',
            AppTab.write => 'Writing options',
            AppTab.flashcards => 'Flashcard options',
          },
          onCenter: _centerAction,
        ),
      ),
    );
  }
}

/// Watches one tab's navigator: keeps a list of its open screens (so the
/// shell can tell whether Settings is among them) and calls [onChange]
/// after any push or pop.
class _TabObserver extends NavigatorObserver {
  _TabObserver(this.onChange);

  final VoidCallback onChange;

  /// The tab's screens, bottom first.
  final List<Route<dynamic>> _stack = [];

  bool get hasSettings =>
      _stack.any((r) => r.settings.name == SettingsScreen.routeName);

  // Run after the frame: the navigator is mid-update when these fire, and
  // rebuilding the shell right then is asking for trouble.
  void _later() =>
      WidgetsBinding.instance.addPostFrameCallback((_) => onChange());

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.add(route);
    _later();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    _later();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    _later();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final index = oldRoute == null ? -1 : _stack.indexOf(oldRoute);
    if (index != -1 && newRoute != null) {
      _stack[index] = newRoute;
    } else if (newRoute != null) {
      _stack.add(newRoute);
    }
    _later();
  }
}

/// The bar itself: two tabs, the round center button, two tabs.
class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.current,
    required this.onTab,
    required this.centerIcon,
    required this.centerTooltip,
    required this.onCenter,
  });

  final AppTab current;
  final ValueChanged<AppTab> onTab;
  final IconData centerIcon;
  final String centerTooltip;
  final VoidCallback onCenter;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      elevation: 8,
      color: colors.surface,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _tabItem(context, AppTab.characters),
              _tabItem(context, AppTab.photos),
              Expanded(
                child: Center(
                  // Slightly larger than the tab icons, round, and filled
                  // with the color theme: the one splash of color in the bar.
                  child: Tooltip(
                    message: centerTooltip,
                    child: Material(
                      color: colors.primary,
                      shape: const CircleBorder(),
                      elevation: 2,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onCenter,
                        child: SizedBox(
                          width: 52,
                          height: 52,
                          child: Icon(centerIcon,
                              size: 30, color: colors.onPrimary),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _tabItem(context, AppTab.write),
              _tabItem(context, AppTab.flashcards),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabItem(BuildContext context, AppTab tab) {
    final selected = tab == current;
    final colors = Theme.of(context).colorScheme;
    final color = selected ? colors.primary : colors.onSurfaceVariant;
    Widget icon = Icon(selected ? tab.selectedIcon : tab.icon, color: color);
    if (tab == AppTab.flashcards) {
      // Rotated 90°, as it was in the old side menu, so it reads as a card.
      icon = RotatedBox(quarterTurns: 1, child: icon);
    }
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        child: InkWell(
          onTap: () => onTab(tab),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(height: 2),
              Text(
                tab.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
