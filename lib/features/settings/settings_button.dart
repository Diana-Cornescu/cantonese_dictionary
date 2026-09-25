import 'package:flutter/material.dart';

import '../../data/dictionary_store.dart';
import 'settings_screen.dart';

/// The ⚙ at the top right of each tab's top screen (1.6.0), where the Home
/// button used to be. Settings opens inside the current tab, so the bottom
/// bar stays visible. Using the bar (another tab, the same tab, or the
/// round button) closes it again — see `AppShell`.
class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key, required this.store});

  final DictionaryStore store;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Settings',
      icon: const Icon(Icons.settings_outlined),
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: SettingsScreen.routeName),
          builder: (_) => SettingsScreen(store: store),
        ),
      ),
    );
  }
}
