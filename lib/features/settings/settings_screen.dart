import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../data/app_database.dart';
import '../../data/backup_service.dart';
import '../../data/dictionary_store.dart';
import '../../widgets/confirm_dialog.dart';

/// Settings, opened from the gear icon on the home screen. For now it only
/// holds backup and restore; more settings will be added here later.
///
/// Backups are saved and opened through the system file window every
/// time (no fixed default folder), so on Android you can pick Downloads,
/// Google Drive, etc. See docs/decisions_log_backup_and_release.md.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.store});

  final DictionaryStore store;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  BackupService? _backups;
  bool _busy = false;
  bool _canUndo = false;

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

  @override
  Widget build(BuildContext context) {
    final ready = _backups != null && !_busy;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          children: [
            if (_busy) const LinearProgressIndicator(),
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
          ],
        ),
      ),
    );
  }
}
