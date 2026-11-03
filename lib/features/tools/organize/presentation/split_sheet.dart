import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../design_system/tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../domain/page_ranges.dart';
import 'range_field.dart';

enum _Mode { every, ranges, eachPage }

/// «Separar»: every N pages, by ranges or one page per file. Returns the
/// parts as ranges over the current order, or null when closed.
Future<List<PageRange>?> showSplitSheet(BuildContext context, {required int pageCount}) =>
    showModalBottomSheet<List<PageRange>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _SplitSheet(pageCount: pageCount),
    );

class _SplitSheet extends StatefulWidget {
  const _SplitSheet({required this.pageCount});

  final int pageCount;

  @override
  State<_SplitSheet> createState() => _SplitSheetState();
}

class _SplitSheetState extends State<_SplitSheet> {
  var _mode = _Mode.every;
  int? _every = 10;
  List<PageRange>? _ranges;

  List<PageRange>? get _parts => switch (_mode) {
    _Mode.every when (_every ?? 0) > 0 => SplitEvery(_every!).parts(widget.pageCount),
    _Mode.every => null,
    _Mode.ranges => _ranges,
    _Mode.eachPage => const SplitEachPage().parts(widget.pageCount),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final parts = _parts;
    return Padding(
      padding: EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.l + MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(header: true, child: Text(l10n.splitTitle, style: Theme.of(context).textTheme.titleLarge)),
            const SizedBox(height: Space.s),
            RadioGroup<_Mode>(
              groupValue: _mode,
              onChanged: (m) => setState(() => _mode = m!),
              child: Column(
                children: [
                  RadioListTile(value: _Mode.every, title: Text(l10n.splitEvery), contentPadding: EdgeInsets.zero),
                  if (_mode == _Mode.every)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(start: Space.xxl + Space.l, bottom: Space.s),
                      child: TextFormField(
                        initialValue: '10',
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          labelText: l10n.splitEveryLabel,
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (v) => setState(() => _every = int.tryParse(v)),
                      ),
                    ),
                  RadioListTile(value: _Mode.ranges, title: Text(l10n.splitRanges), contentPadding: EdgeInsets.zero),
                  if (_mode == _Mode.ranges)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(start: Space.xxl + Space.l, bottom: Space.s),
                      child: RangeField(pageCount: widget.pageCount, onChanged: (r) => setState(() => _ranges = r)),
                    ),
                  RadioListTile(
                    value: _Mode.eachPage,
                    title: Text(l10n.splitEachPage),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.m),
            FilledButton(
              onPressed: parts == null || parts.length < 2 ? null : () => Navigator.of(context).pop(parts),
              child: Text(parts == null ? l10n.splitButtonIdle : l10n.splitButton(parts.length)),
            ),
          ],
        ),
      ),
    );
  }
}
