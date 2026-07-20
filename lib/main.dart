import 'package:flutter/material.dart';

import 'data/dictionary_store.dart';
import 'data/storage_service.dart';
import 'features/dictionary_list/dictionary_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await StorageService.createDefault();
  final store = DictionaryStore(storage);
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
    return MaterialApp(
      title: 'Cantonese Dictionary',
      home: DictionaryListScreen(store: store),
    );
  }
}
