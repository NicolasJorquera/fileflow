import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/theme.dart';
import '../../../../design_system/tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../organize/presentation/organize_controller.dart';
import '../../organize/presentation/organize_screen.dart';
import '../../organize/presentation/range_field.dart';
import '../../shared/presentation/page_thumbnail.dart';

/// «Elegir páginas»: the Organizar grid in selection mode (UX v1.0). Pops with
/// the chosen 0-based pages, or null when the user goes back.
class PagePickerScreen extends ConsumerStatefulWidget {
  const PagePickerScreen({super.key, required this.path, required this.pageCount, this.initial});

  final String path;
  final int pageCount;
  final List<int>? initial;

  @override
  ConsumerState<PagePickerScreen> createState() => _PagePickerScreenState();
}

class _PagePickerScreenState extends ConsumerState<PagePickerScreen> {
  late Set<int> _selected = {...?widget.initial};
  late final _pages = [for (var i = 0; i < widget.pageCount; i++) OrgPage(i)];

  void _toggle(int page) => setState(() => _selected.contains(page) ? _selected.remove(page) : _selected.add(page));

  Future<void> _range() async {
    final ranges = await showRangeDialog(context, pageCount: widget.pageCount);
    if (ranges != null) {
      setState(() => _selected = {for (final r in ranges) ...r.indices});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final thumbnails = ref.watch(thumbnailsProvider(widget.path)).value;
    final all = _selected.length == widget.pageCount;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pagesChoose),
        actions: [IconButton(tooltip: l10n.selectRangeMenu, icon: const Icon(Icons.pin_outlined), onPressed: _range)],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(Space.l, 0, Space.s, 0),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    _selected.isEmpty ? l10n.organizeHint : l10n.selectedCount(_selected.length),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: palette.muted),
                  ),
                ),
                Flexible(
                  flex: 2,
                  child: TextButton(
                    onPressed: () =>
                        setState(() => _selected = all ? {} : {for (var i = 0; i < widget.pageCount; i++) i}),
                    child: Text(all ? l10n.clearSelection : l10n.selectAll, textAlign: TextAlign.end),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: PageGrid(pages: _pages, selected: _selected, thumbnails: thumbnails, onTap: _toggle),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Space.l),
          child: FilledButton(
            onPressed: _selected.isEmpty ? null : () => Navigator.of(context).pop(_selected.toList()..sort()),
            child: Text(l10n.usePages(_selected.length)),
          ),
        ),
      ),
    );
  }
}
