import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/domain/files.dart';
import '../../../../core/domain/pdf.dart';
import '../../../../core/domain/tools.dart';
import '../../../../core/format/sizes.dart';
import '../../../../design_system/theme.dart';
import '../../../../design_system/tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../shared/failure_text.dart';
import '../../../shared/processing_screen.dart';
import '../../shared/presentation/tool_args.dart';
import 'reduce_controller.dart';

/// Reducir tamaño (UX v1.0): file, diagnosis, mode (size or quality),
/// options, expected result and a button that names the goal.
class ReduceScreen extends ConsumerStatefulWidget {
  const ReduceScreen({super.key, this.args = const ToolArgs()});

  final ToolArgs args;

  @override
  ConsumerState<ReduceScreen> createState() => _ReduceScreenState();
}

class _ReduceScreenState extends ConsumerState<ReduceScreen> {
  ReduceController get _controller => ref.read(reduceControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.args.isEmpty) {
        _controller.pick();
      } else {
        _controller.start(widget.args);
      }
    });
  }

  Future<void> _reduce() async {
    final l10n = AppLocalizations.of(context);
    final state = ref.read(reduceControllerProvider);
    final name = '${l10n.nameReduced(fileStem(state.source!.file.name))}.pdf';
    final title = state.mode == ReduceMode.size
        ? l10n.processingFit(formatSizeGoal(state.targetBytes, l10n.localeName))
        : l10n.processingReduce;
    while (mounted) {
      final retry = await context.push<bool>(
        Routes.processing,
        extra: ProcessingArgs(job: _controller.reduce(name), title: title),
      );
      if (retry != true) break;
    }
  }

  Future<void> _customTarget() async {
    final mb = await showDialog<double>(context: context, builder: (_) => const _CustomTargetDialog());
    if (mb != null) _controller.setTarget(mb);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(reduceControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.toolReduceTitle)),
      body: switch (state) {
        ReduceState(loading: true) => const Center(child: CircularProgressIndicator()),
        ReduceState(source: null, :final failure) => _Prompt(
          failure: failure == null ? null : l10n.failureText(failure),
          onPick: _controller.pick,
        ),
        _ => _Options(state: state, onChange: _controller.pick, onCustomTarget: _customTarget),
      },
      bottomNavigationBar: state.source == null ? null : _ReduceBar(state: state, onReduce: _reduce),
    );
  }
}

class _Prompt extends StatelessWidget {
  const _Prompt({required this.onPick, this.failure});

  final VoidCallback onPick;
  final String? failure;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              failure ?? l10n.reduceEmpty,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: failure == null ? null : context.palette.danger),
            ),
            const SizedBox(height: Space.l),
            FilledButton.icon(onPressed: onPick, icon: const Icon(Icons.folder_open), label: Text(l10n.choosePdf)),
          ],
        ),
      ),
    );
  }
}

class _Options extends ConsumerWidget {
  const _Options({required this.state, required this.onChange, required this.onCustomTarget});

  final ReduceState state;
  final VoidCallback onChange, onCustomTarget;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final controller = ref.read(reduceControllerProvider.notifier);
    final source = state.source!;
    final custom = !ReduceLimits.targetsMb.contains(state.targetMb);
    Widget section(String title) => Padding(
      padding: const EdgeInsets.only(top: Space.xl, bottom: Space.s),
      child: Semantics(
        header: true,
        child: Text(title, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
      ),
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.l),
      children: [
        Material(
          color: palette.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.card),
            side: BorderSide(color: palette.line),
          ),
          child: ListTile(
            leading: Icon(Icons.picture_as_pdf_outlined, color: palette.muted),
            title: Text(source.file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              l10n.itemMeta(source.pageCount, formatBytes(source.file.sizeBytes, l10n.localeName)),
              style: text.bodySmall?.copyWith(color: palette.muted),
            ),
            trailing: TextButton(onPressed: onChange, child: Text(l10n.change)),
          ),
        ),
        const SizedBox(height: Space.m),
        _Diagnosis(textOnly: source.looksTextOnly),
        if (state.isTooBig)
          _Warning(text: l10n.reduceTooBig(ReduceLimits.maxPages, formatBytes(ReduceLimits.maxBytes, l10n.localeName)))
        else if (state.isBig)
          _Warning(text: l10n.reduceBig),
        section(l10n.reduceHow),
        SegmentedButton<ReduceMode>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: ReduceMode.size, label: Text(l10n.reduceModeSize)),
            ButtonSegment(value: ReduceMode.quality, label: Text(l10n.reduceModeQuality)),
          ],
          selected: {state.mode},
          onSelectionChanged: (s) => controller.setMode(s.single),
        ),
        const SizedBox(height: Space.m),
        if (state.mode == ReduceMode.size) ...[
          Text(l10n.reduceSizeHelp, style: text.bodySmall?.copyWith(color: palette.muted)),
          const SizedBox(height: Space.s),
          Wrap(
            spacing: Space.s,
            runSpacing: Space.s,
            children: [
              for (final mb in ReduceLimits.targetsMb)
                _Chip(
                  label: '$mb MB',
                  selected: state.targetMb == mb,
                  onTap: () => controller.setTarget(mb.toDouble()),
                ),
              _Chip(
                label: custom ? formatSizeGoal(state.targetBytes, l10n.localeName) : l10n.reduceOther,
                selected: custom,
                onTap: onCustomTarget,
              ),
            ],
          ),
          const SizedBox(height: Space.m),
          Text(
            l10n.reduceSizeExplain(formatSizeGoal(state.targetBytes, l10n.localeName)),
            style: text.bodySmall?.copyWith(color: palette.muted),
          ),
        ] else
          RadioGroup<ReduceLevel>(
            groupValue: state.level,
            onChanged: (level) => controller.setLevel(level!),
            child: Column(
              children: [
                for (final level in ReduceLevel.choices)
                  RadioListTile<ReduceLevel>(
                    value: level,
                    contentPadding: EdgeInsets.zero,
                    title: Text(switch (level) {
                      ReduceLevel.high => l10n.levelHigh,
                      ReduceLevel.balanced => l10n.levelBalanced,
                      _ => l10n.levelMinimal,
                    }),
                    subtitle: Text(switch (level) {
                      ReduceLevel.high => l10n.levelHighHelp,
                      ReduceLevel.balanced => l10n.levelBalancedHelp,
                      _ => l10n.levelMinimalHelp,
                    }),
                  ),
              ],
            ),
          ),
        section(l10n.reduceExpected),
        if (state.mode == ReduceMode.size)
          _Fact(
            label: l10n.reduceExpectedSize,
            value: l10n.reduceExpectedUnder(
              formatBytes(source.file.sizeBytes, l10n.localeName),
              formatSizeGoal(state.targetBytes, l10n.localeName),
            ),
          ),
        _Fact(label: l10n.reduceSelectableText, value: l10n.reduceKept),
      ],
    );
  }
}

class _Diagnosis extends StatelessWidget {
  const _Diagnosis({required this.textOnly});

  final bool textOnly;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    return Row(
      children: [
        Icon(
          textOnly ? Icons.info_outline : Icons.check_circle_outline,
          size: 18,
          color: textOnly ? palette.warn : palette.success,
        ),
        const SizedBox(width: Space.s),
        Expanded(
          child: Text(
            textOnly ? l10n.reduceTextOnly : l10n.reduceHasImages,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: palette.fg),
          ),
        ),
      ],
    );
  }
}

class _Warning extends StatelessWidget {
  const _Warning({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: Space.s),
    child: Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.palette.warn)),
  );
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    inMutuallyExclusiveGroup: true,
    checked: selected,
    child: ChoiceChip(label: Text(label), selected: selected, showCheckmark: false, onSelected: (_) => onTap()),
  );
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label, value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.s),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: text.bodyMedium?.copyWith(color: context.palette.muted)),
          ),
          Text(value, style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _CustomTargetDialog extends StatefulWidget {
  const _CustomTargetDialog();

  @override
  State<_CustomTargetDialog> createState() => _CustomTargetDialogState();
}

class _CustomTargetDialogState extends State<_CustomTargetDialog> {
  double? _mb;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.reduceOtherTitle),
      content: TextField(
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
        decoration: InputDecoration(
          labelText: l10n.reduceOtherLabel,
          suffixText: 'MB',
          border: const OutlineInputBorder(),
        ),
        onChanged: (v) => setState(() {
          final mb = double.tryParse(v.replaceAll(',', '.'));
          _mb = mb != null && mb >= 0.1 && mb <= 1000 ? mb : null;
        }),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
        TextButton(onPressed: _mb == null ? null : () => Navigator.of(context).pop(_mb), child: Text(l10n.select)),
      ],
    );
  }
}

class _ReduceBar extends StatelessWidget {
  const _ReduceBar({required this.state, required this.onReduce});

  final ReduceState state;
  final VoidCallback onReduce;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(top: BorderSide(color: palette.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(Space.l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.isTooBig)
                OutlinedButton(
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(Touch.primaryButton)),
                  onPressed: () =>
                      context.pushReplacement(Routes.organize, extra: ToolArgs(local: [state.source!.file])),
                  child: Text(l10n.reduceSplitInstead),
                )
              else
                FilledButton(
                  onPressed: onReduce,
                  child: Text(
                    state.mode == ReduceMode.size
                        ? l10n.reduceToButton(formatSizeGoal(state.targetBytes, l10n.localeName))
                        : l10n.reduceButton,
                  ),
                ),
              const SizedBox(height: Space.s),
              Text(
                l10n.originalUnchanged,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: palette.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
