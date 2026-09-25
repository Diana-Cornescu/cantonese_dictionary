import 'package:flutter/material.dart';

import 'data/app_database.dart';
import 'data/dictionary_store.dart';
import 'features/shell/app_shell.dart';
import 'theme/app_palettes.dart';
import 'theme/app_theme.dart';
import 'theme/app_theme_mode.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = DictionaryStore(AppDatabase(), reopen: AppDatabase.new);
  await store.load();
  runApp(CantoneseDictionaryApp(store: store));
}

/// Root widget: builds the MaterialApp and hands the single
/// [DictionaryStore] instance down into [AppShell] (the bottom bar and its
/// four tabs, since 1.6.0), which passes it further into every other screen
/// via plain constructor parameters — no provider/inherited-widget package
/// is used anywhere in this app.
class CantoneseDictionaryApp extends StatelessWidget {
  const CantoneseDictionaryApp({super.key, required this.store});

  final DictionaryStore store;

  @override
  Widget build(BuildContext context) {
    // Rebuilds when the store changes, so a new color theme or
    // Light/Dark choice made in Settings (or restored from a backup)
    // applies straight away.
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final palette = AppPalette.byId(store.setting(AppPalette.settingKey));
        final mode =
            AppThemeMode.byId(store.setting(AppThemeMode.settingKey));
        return MaterialApp(
          title: 'Cantonese Dictionary',
          theme: AppTheme.light(palette),
          // Falls back to Cerulean for a color theme without a dark
          // version yet (see AppPalette.darkReady).
          darkTheme: AppTheme.dark(palette),
          themeMode: mode.themeMode,
          home: AppShell(store: store),
        );
      },
    );
  }
}
