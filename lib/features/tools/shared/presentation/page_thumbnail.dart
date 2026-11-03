import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/domain/pdf.dart';
import '../../../../design_system/theme.dart';
import '../../../../design_system/tokens.dart';

/// Thumbnails of one document while a screen shows it; closed when the last
/// screen using it goes away.
final thumbnailsProvider = FutureProvider.autoDispose.family<Thumbnails?, String>((ref, path) async {
  final opened = await ref.watch(thumbnailSourceProvider).open(path);
  final thumbnails = opened.valueOrNull;
  if (thumbnails != null) ref.onDispose(thumbnails.close);
  return thumbnails;
});

/// One page preview. Asks for its image when built and cancels the request
/// if it scrolls away first; until then shows a grey sheet with the page
/// number (UX v1.0, Organizar).
class PageThumbnail extends StatefulWidget {
  const PageThumbnail({
    super.key,
    required this.thumbnails,
    required this.index,
    required this.label,
    this.quarterTurns = 0,
  });

  final Thumbnails? thumbnails;

  /// 0-based page in the source document.
  final int index;

  /// Shown while the image loads (the page's position).
  final String label;
  final int quarterTurns;

  @override
  State<PageThumbnail> createState() => _PageThumbnailState();
}

class _PageThumbnailState extends State<PageThumbnail> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(PageThumbnail old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index || old.thumbnails != widget.thumbnails) {
      old.thumbnails?.cancel(old.index);
      _bytes = null;
      _load();
    }
  }

  Future<void> _load() async {
    final thumbnails = widget.thumbnails;
    if (thumbnails == null) return;
    final index = widget.index;
    final bytes = await thumbnails.page(index);
    if (mounted && bytes != null && index == widget.index) setState(() => _bytes = bytes);
  }

  @override
  void dispose() {
    if (_bytes == null) widget.thumbnails?.cancel(widget.index);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final bytes = _bytes;
    final child = bytes == null
        ? ColoredBox(
            color: palette.surface2,
            child: Center(
              child: Text(widget.label, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: palette.muted)),
            ),
          )
        : RotatedBox(
            quarterTurns: widget.quarterTurns % 4,
            child: Image.memory(bytes, fit: BoxFit.contain, gaplessPlayback: true, filterQuality: FilterQuality.medium),
          );
    return ClipRRect(borderRadius: BorderRadius.circular(Radii.small / 2), child: child);
  }
}
