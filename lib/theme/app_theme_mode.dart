import 'package:flutter/material.dart';

/// Light, dark, or whatever the phone (or Windows) is set to — chosen in
/// Settings under Appearance (2026-09-25).
///
/// Saved in the settings table like the color theme, so it rides along in
/// backups. **Light is the default**, so nothing changes for anyone until
/// they pick something else.
enum AppThemeMode {
  light('Light', Icons.light_mode_outlined, ThemeMode.light),
  dark('Dark', Icons.dark_mode_outlined, ThemeMode.dark),
  system('Match phone', Icons.brightness_auto_outlined, ThemeMode.system);

  const AppThemeMode(this.label, this.icon, this.themeMode);

  final String label;
  final IconData icon;

  /// What `MaterialApp.themeMode` gets.
  final ThemeMode themeMode;

  /// The key this choice is saved under in the settings table.
  static const settingKey = 'theme_mode';

  /// The choice stored under [settingKey], falling back to [light] for
  /// anything missing or unrecognised.
  ///
  /// The stored string is the enum's `name`, so **renaming a value here
  /// silently resets everyone's setting** — `test/app_palettes_test.dart`
  /// pins the three strings for that reason.
  static AppThemeMode byId(String? id) {
    for (final mode in values) {
      if (mode.name == id) return mode;
    }
    return light;
  }
}
