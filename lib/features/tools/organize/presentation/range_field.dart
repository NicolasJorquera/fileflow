import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../domain/page_ranges.dart';

/// The inline message for a text that is not a valid list of ranges.
String rangeErrorText(AppLocalizations l10n, RangesInvalid invalid, int pageCount) => switch (invalid.problem) {
  RangeProblem.empty => l10n.rangeEmpty,
  RangeProblem.notANumber => l10n.rangeNotANumber(invalid.token),
  RangeProblem.outOfRange => l10n.rangeOutOfRange(invalid.token, pageCount),
  RangeProblem.reversed => l10n.rangeReversed(invalid.token),
};

/// A text field for «1-3, 5, 8-10» that explains what is wrong as you type
/// (PRD H5: invalid ranges show an inline error).
class RangeField extends StatefulWidget {
  const RangeField({super.key, required this.pageCount, required this.onChanged, this.autofocus = false});

  final int pageCount;

  /// Null while the text is not valid.
  final ValueChanged<List<PageRange>?> onChanged;
  final bool autofocus;

  @override
  State<RangeField> createState() => _RangeFieldState();
}

class _RangeFieldState extends State<RangeField> {
  String? _error;
  var _touched = false;

  void _changed(String text) {
    final l10n = AppLocalizations.of(context);
    final parsed = parseRanges(text, widget.pageCount);
    setState(() {
      _touched = true;
      _error = parsed is RangesInvalid ? rangeErrorText(l10n, parsed, widget.pageCount) : null;
    });
    widget.onChanged(parsed is RangesOk ? parsed.ranges : null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextField(
      autofocus: widget.autofocus,
      keyboardType: TextInputType.visiblePassword,
      decoration: InputDecoration(
        labelText: l10n.rangeLabel,
        hintText: l10n.rangeHint,
        helperText: l10n.rangeHelper(widget.pageCount),
        errorText: _touched ? _error : null,
        border: const OutlineInputBorder(),
      ),
      onChanged: _changed,
    );
  }
}

/// «Seleccionar rango»: returns the ranges, or null when cancelled.
Future<List<PageRange>?> showRangeDialog(BuildContext context, {required int pageCount}) {
  List<PageRange>? ranges;
  return showDialog<List<PageRange>>(
    context: context,
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.selectRangeMenu),
          content: RangeField(pageCount: pageCount, autofocus: true, onChanged: (r) => setState(() => ranges = r)),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
            TextButton(
              onPressed: ranges == null ? null : () => Navigator.of(context).pop(ranges),
              child: Text(l10n.select),
            ),
          ],
        ),
      );
    },
  );
}
