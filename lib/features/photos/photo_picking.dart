import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/dictionary_store.dart';
import '../../widgets/character_picker_dialog.dart';

/// The whole "add a photo" flow: take or pick one with [pickPhoto], ask
/// which characters it shows, then save it. Cancelling either step saves
/// nothing. Used by the bottom bar's + on the Photos tab (1.6.0; it was the
/// gallery's own floating + button before).
Future<void> addPhotoWithCharacters(
    BuildContext context, DictionaryStore store) async {
  final file = await pickPhoto(context);
  if (file == null || !context.mounted) return;
  final ids = await pickCharacters(context, store);
  if (ids == null) return; // cancelled: nothing is saved
  await store.addPhoto(file, characterIds: ids);
}

/// Lets you take a new photo or choose an existing one, and returns the
/// image file (or null if cancelled). The file is a temporary one; the
/// store copies it into the app's own photos folder.
///
/// - Phone: asks "Take a photo" or "Choose from gallery". Camera photos are
///   NOT saved to the phone's gallery (only the app keeps its copy). Images
///   are resized to at most 1600 px to keep the app and backups small.
/// - Laptop (Windows): opens a normal file window for image files (no
///   camera; not resized).
Future<File?> pickPhoto(BuildContext context) async {
  final isPhone = Platform.isAndroid || Platform.isIOS;
  if (!isPhone) {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Choose a photo',
      type: FileType.image,
    );
    final path = result?.files.single.path;
    return path == null ? null : File(path);
  }

  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Take a photo'),
            onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
  if (source == null) return null;

  final picked = await ImagePicker().pickImage(
    source: source,
    maxWidth: 1600,
    maxHeight: 1600,
    imageQuality: 85,
  );
  return picked == null ? null : File(picked.path);
}
