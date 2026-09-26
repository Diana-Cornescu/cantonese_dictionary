import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../data/app_database.dart';
import '../../data/backup_service.dart';
import '../../data/character_entry.dart';
import '../../data/dictionary_store.dart';
import '../../theme/app_color_roles.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_palettes.dart';
import '../../theme/app_theme_mode.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/handwriting_canvas.dart';
import '../../widgets/ink_settings.dart';
import '../dictionary_list/dictionary_list_screen.dart';
import '../tags/tags_screen.dart';

/// Settings, opened from the ⚙ at the top right of any tab (1.6.0; it was
/// in the ☰ side menu before): Light / Dark / Match phone, the color theme,
/// the archive, tags, backup & restore, and licences. More settings can be
/// added here later.
///
/// The archive moved here from the side menu in 1.6.0. It's somewhere you
/// go rarely, so it doesn't earn a place in the bottom bar.
///
/// **Tags** moved here from the bottom bar on 2026-09-25, when the Write
/// tab took its slot. It's a stopgap until Tags gets a permanent home (see
/// the roadmap).
///
/// Backups are saved and opened through the system file window every
/// time (no fixed default folder), so on Android you can pick Downloads,
/// Google Drive, etc. See docs/decisions_log_backup_and_release.md.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.store});

  final DictionaryStore store;

  /// The route name Settings is opened under, so the bottom bar can find
  /// and close it (see `AppShell`).
  static const routeName = 'settings';

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  BackupService? _backups;
  bool _busy = false;
  bool _canUndo = false;

  /// The pen size while the slider is being dragged; saved (and cleared)
  /// when it's let go, so dragging doesn't write to the database on every
  /// step.
  double? _penDraft;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final service = await BackupService.forApp(widget.store);
    final undo = await service.latestSafetyCopy() != null;
    if (!mounted) return;
    setState(() {
      _backups = service;
      _canUndo = undo;
    });
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  /// Runs [action] with the busy indicator on, and shows any error.
  Future<void> _run(Future<void> Function(BackupService backups) action) async {
    final backups = _backups;
    if (backups == null || _busy) return;
    setState(() => _busy = true);
    try {
      await action(backups);
    } on BackupException catch (e) {
      if (mounted) _showMessage(e.message);
    } catch (e) {
      if (mounted) _showMessage('Something went wrong: $e');
    } finally {
      final undo = await backups.latestSafetyCopy() != null;
      if (mounted) {
        setState(() {
          _busy = false;
          _canUndo = undo;
        });
      }
    }
  }

  bool get _isDesktop =>
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  Future<void> _backUp() => _run((backups) async {
        final backup = await backups.createBackup();

        String? initialDirectory;
        if (_isDesktop) {
          // On the laptop, start the Save window in local_data\backups.
          final dir = Directory('${(await AppDatabase.databaseDirectory()).path}'
              '${Platform.pathSeparator}backups');
          await dir.create(recursive: true);
          initialDirectory = dir.path;
        }

        final savedPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save backup',
          fileName: backup.suggestedName,
          initialDirectory: initialDirectory,
          type: FileType.any,
          bytes: backup.bytes,
        );
        if (savedPath == null) return; // cancelled

        // On Android the picker writes the bytes itself. On desktop it only
        // returns the chosen path, so write the file here.
        if (_isDesktop) {
          await File(savedPath).writeAsBytes(backup.bytes, flush: true);
        }
        if (mounted) _showMessage('Backup saved.');
      });

  Future<void> _restore() => _run((backups) async {
        final picked = await FilePicker.platform.pickFiles(
          dialogTitle: 'Choose a backup file',
          type: FileType.any,
          withData: true,
        );
        if (picked == null || picked.files.isEmpty) return; // cancelled

        final file = picked.files.single;
        Uint8List? bytes = file.bytes;
        if (bytes == null && file.path != null) {
          bytes = await File(file.path!).readAsBytes();
        }
        if (bytes == null) {
          throw const BackupException("Couldn't read that file.");
        }

        // Check the file before asking, so a wrong file fails right away.
        final count = backups.inspect(bytes);
        if (!mounted) return;
        final confirmed = await confirmAction(
          context,
          title: 'Restore this backup?',
          message: 'All current data will be replaced with the backup '
              '($count characters). A safety copy of your current data is '
              'saved first, so you can undo this.',
          confirmLabel: 'Restore',
        );
        if (!confirmed) return;

        final restored = await backups.restore(bytes);
        if (mounted) _showMessage('Restored $restored characters.');
      });

  Future<void> _undo() => _run((backups) async {
        final confirmed = await confirmAction(
          context,
          title: 'Undo last restore?',
          message: 'Your data goes back to how it was right before the last '
              'restore.',
          confirmLabel: 'Undo',
        );
        if (!confirmed) return;
        await backups.undoLastRestore();
        if (mounted) _showMessage('Last restore undone.');
      });

  /// Light / Dark / Match phone (2026-09-25). Applies straight away: the
  /// store notifies and `main.dart` rebuilds the app with the new mode.
  Widget _buildAppearanceSection() {
    final current =
        AppThemeMode.byId(widget.store.setting(AppThemeMode.settingKey));
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Appearance', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          SegmentedButton<AppThemeMode>(
            showSelectedIcon: false,
            segments: [
              for (final mode in AppThemeMode.values)
                ButtonSegment(
                  value: mode,
                  icon: Icon(mode.icon),
                  label: Text(mode.label),
                ),
            ],
            selected: {current},
            onSelectionChanged: (picked) async {
              await widget.store
                  .setSetting(AppThemeMode.settingKey, picked.single.name);
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
    );
  }

  /// A wavy sample line with deliberately few, far-apart points, so the
  /// preview shows both the pen size and what smoothing does to corners.
  static final List<List<StrokePoint>> _penSample = [
    [
      for (var i = 0; i <= 10; i++)
        StrokePoint(
          x: i * 24.0,
          y: 30 + 22 * math.sin(i * 1.25),
          t: 0,
        ),
    ],
  ];

  /// Pen size and smoothing for every drawing in the app (2026-09-26).
  /// Display only: what's saved for a drawing doesn't change. See
  /// `widgets/ink_settings.dart`.
  Widget _buildHandwritingSection() {
    final ink = InkSettings.fromStored(
      widget.store.setting(InkSettings.widthKey),
      widget.store.setting(InkSettings.smoothKey),
    );
    final width = _penDraft ?? ink.width;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Handwriting', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Pen size'),
              Expanded(
                child: Slider(
                  value: width,
                  min: InkSettings.minWidth,
                  max: InkSettings.maxWidth,
                  divisions:
                      (InkSettings.maxWidth - InkSettings.minWidth).round(),
                  label: width.round().toString(),
                  onChanged: (value) => setState(() => _penDraft = value),
                  onChangeEnd: (value) async {
                    await widget.store
                        .setSetting(InkSettings.widthKey, '${value.round()}');
                    if (mounted) setState(() => _penDraft = null);
                  },
                ),
              ),
              SizedBox(
                width: 24,
                child: Text('${width.round()}', textAlign: TextAlign.end),
              ),
            ],
          ),
          // Live preview, on the same paper as every drawing box.
          Container(
            height: 72,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: context.appColors.frame),
            ),
            child: HandwritingCanvas(
              readOnly: true,
              fitToBox: true,
              initialStrokes: _penSample,
              strokeWidth: width,
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Smooth strokes'),
            subtitle: const Text(
                'Rounds off corners and wobbles in the ink. Your saved '
                "drawings aren't changed, so you can turn it off again."),
            value: ink.smooth,
            onChanged: (on) async {
              await widget.store.setSetting(InkSettings.smoothKey, '$on');
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
    );
  }

  /// A row of round color swatches; tap one to switch the app's colors.
  /// See `lib/theme/app_palettes.dart` for why these colors were chosen.
  ///
  /// A small 🌙 on a swatch means that theme has a dark version (see
  /// `AppPalette.darkReady`). While the app is dark, the themes without one
  /// are faded; they can still be picked, for light mode, and a line under
  /// the swatches says what dark mode is showing instead.
  Widget _buildColorThemeSection() {
    final current =
        AppPalette.byId(widget.store.setting(AppPalette.settingKey));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final small = theme.textTheme.labelSmall;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Color theme', style: theme.textTheme.titleSmall),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              for (final palette in AppPalette.all)
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    await widget.store
                        .setSetting(AppPalette.settingKey, palette.id);
                    if (!mounted) return;
                    setState(() {});
                    if (isDark && !palette.darkReady) {
                      _showMessage('${palette.name} is saved for light mode. '
                          "It doesn't have a dark version yet, so dark mode "
                          'shows ${palette.forDarkMode.name}.');
                    }
                  },
                  child: Opacity(
                    opacity: isDark && !palette.darkReady ? 0.35 : 1,
                    child: SizedBox(
                      width: 64,
                      child: Column(
                        children: [
                          _swatch(palette, selected: palette.id == current.id),
                          const SizedBox(height: 4),
                          Text(
                            palette.name,
                            style: small,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.dark_mode, size: 14, color: theme.iconTheme.color),
              const SizedBox(width: 6),
              Expanded(
                child: Text('Also has a dark version', style: small),
              ),
            ],
          ),
          if (isDark && !current.darkReady) ...[
            const SizedBox(height: 6),
            Text(
              "${current.name} doesn't have a dark version yet, so dark "
              'mode is showing ${current.forDarkMode.name}.',
              style: small,
            ),
          ],
        ],
      ),
    );
  }

  /// One round swatch in [palette]'s main color, with a ✓ and a ring when
  /// it's the chosen theme and a small 🌙 badge when it has a dark version.
  Widget _swatch(AppPalette palette, {required bool selected}) {
    final theme = Theme.of(context);
    final circle = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: palette.primary,
        shape: BoxShape.circle,
        border: Border.all(
          // The ring is the palette's deep shade on light, which vanishes
          // on the dark background, so dark mode rings in the text color.
          color: !selected
              ? AppColors.none
              : theme.brightness == Brightness.dark
                  ? theme.colorScheme.onSurface
                  : palette.secondary,
          width: 3,
        ),
      ),
      child: selected
          ? const Icon(Icons.check, color: AppColors.onAccent)
          : null,
    );
    if (!palette.darkReady) return circle;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        circle,
        Positioned(
          right: -4,
          bottom: -4,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.dark_mode,
                size: 14, color: theme.iconTheme.color),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ready = _backups != null && !_busy;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          children: [
            if (_busy) const LinearProgressIndicator(),
            _buildAppearanceSection(),
            _buildColorThemeSection(),
            _buildHandwritingSection(),
            const Divider(height: 32),
            ListenableBuilder(
              listenable: widget.store,
              builder: (context, _) {
                final count = widget.store.archivedCharacters.length;
                return ListTile(
                  leading: const Icon(Icons.archive_outlined),
                  title: const Text('Archive'),
                  subtitle: Text(count == 1
                      ? '1 archived character'
                      : '$count archived characters'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DictionaryListScreen(
                        store: widget.store,
                        isArchiveView: true,
                      ),
                    ),
                  ),
                );
              },
            ),
            ListenableBuilder(
              listenable: widget.store,
              builder: (context, _) {
                final count = widget.store.allTags.length;
                return ListTile(
                  leading: const Icon(Icons.sell_outlined),
                  title: const Text('Tags'),
                  subtitle: Text(count == 1 ? '1 tag' : '$count tags'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TagsScreen(store: widget.store),
                    ),
                  ),
                );
              },
            ),
            const Divider(height: 32),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                'Backup & restore',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.backup_outlined),
              title: const Text('Back up'),
              subtitle: const Text('Save all your data to one file'),
              enabled: ready,
              onTap: _backUp,
            ),
            ListTile(
              leading: const Icon(Icons.settings_backup_restore),
              title: const Text('Restore'),
              subtitle: const Text('Replace all data with a backup file'),
              enabled: ready,
              onTap: _restore,
            ),
            if (_canUndo)
              ListTile(
                leading: const Icon(Icons.undo),
                title: const Text('Undo last restore'),
                subtitle: const Text('Go back to the data from before it'),
                enabled: ready,
                onTap: _undo,
              ),
            const Divider(height: 32),
            // Credits for bundled data, e.g. the Write tab's stroke data
            // (registered in main.dart), plus every package's licence.
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Licences'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showLicensePage(
                context: context,
                applicationName: 'Cantonese Dictionary',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
