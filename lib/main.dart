import 'package:flutter/material.dart';

import 'data/app_database.dart';
import 'data/dictionary_store.dart';
import 'features/dictionary_list/dictionary_list_screen.dart';
import 'theme/app_palettes.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = DictionaryStore(AppDatabase(), reopen: AppDatabase.new);
  await store.load();
  runApp(CantoneseDictionaryApp(store: store));
}

/// Root widget: builds the MaterialApp and hands the single
/// [DictionaryStore] instance down into the dictionary list screen, which
/// passes it further into every other screen (detail, add, flashcards) via
/// plain constructor parameters — no provider/inherited-widget package is
/// used anywhere in this app.
class CantoneseDictionaryApp extends StatelessWidget {
  const CantoneseDictionaryApp({super.key, required this.store});

  final DictionaryStore store;

  @override
  Widget build(BuildContext context) {
    // Rebuilds when the store changes, so a new color theme chosen in
    // Settings (or restored from a backup) applies straight away.
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => MaterialApp(
        title: 'Cantonese Dictionary',
        theme: AppTheme.light(
            AppPalette.byId(store.setting(AppPalette.settingKey))),
        home: DictionaryListScreen(store: store),
      ),
    );
  }
}
