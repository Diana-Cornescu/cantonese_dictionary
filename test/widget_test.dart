import 'package:cantonese_dictionary_app/data/app_database.dart';
import 'package:cantonese_dictionary_app/data/dictionary_store.dart';
import 'package:cantonese_dictionary_app/main.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Smoke test: the app starts on a fresh (in-memory) database and shows the
/// seeded example character in the list.
///
/// (Replaces Flutter's default "counter" template test, which never matched
/// this app.)
void main() {
  testWidgets('app starts and shows the seeded example row',
      (WidgetTester tester) async {
    final store = DictionaryStore(AppDatabase(NativeDatabase.memory()));
    // Real database work runs outside the test's fake clock.
    await tester.runAsync(() => store.load());

    await tester.pumpWidget(CantoneseDictionaryApp(store: store));
    await tester.pump();

    expect(find.text('愛'), findsWidgets);

    await tester.runAsync(() => store.close());
  });
}
