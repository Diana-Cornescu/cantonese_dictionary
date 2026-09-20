import 'dart:io';

import 'package:flutter/material.dart';

import '../../data/dictionary_store.dart';
import '../../data/photo_entry.dart';

/// Shows a stored photo's image file. Looks the file up once per photo (the
/// photos folder is found asynchronously), then displays it.
class PhotoImage extends StatefulWidget {
  const PhotoImage({
    super.key,
    required this.store,
    required this.photo,
    this.fit = BoxFit.cover,
  });

  final DictionaryStore store;
  final PhotoEntry photo;
  final BoxFit fit;

  @override
  State<PhotoImage> createState() => _PhotoImageState();
}

class _PhotoImageState extends State<PhotoImage> {
  late Future<File> _file;

  @override
  void initState() {
    super.initState();
    _file = widget.store.photoFile(widget.photo);
  }

  @override
  void didUpdateWidget(covariant PhotoImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photo.fileName != widget.photo.fileName) {
      _file = widget.store.photoFile(widget.photo);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File>(
      future: _file,
      builder: (context, snapshot) {
        final file = snapshot.data;
        if (file == null) {
          return const ColoredBox(color: Color(0x11000000));
        }
        return Image.file(
          file,
          fit: widget.fit,
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Icon(Icons.broken_image_outlined),
          ),
        );
      },
    );
  }
}
