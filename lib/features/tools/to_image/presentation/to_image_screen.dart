import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/domain/files.dart';
import '../../../../core/domain/tools.dart';
import '../../../../core/format/sizes.dart';
import '../../../../core/jobs/jobs.dart';
import '../../../../design_system/theme.dart';
import '../../../../design_system/tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../shared/failure_text.dart';
import '../../../shared/processing_screen.dart';
import '../../organize/domain/page_ranges.dart';
import '../../shared/presentation/tool_args.dart';
import 'page_picker_screen.dart';
import 'to_image_controller.dart';

/// PDF a imagen (UX v1.0): file, format, resolution with help, pages,
/// estimate and the button that says how many pages it converts.
class ToImageScreen extends ConsumerStatefulWidget {
  const ToImageScreen({super.key, this.args = const ToolArgs()});

  final ToolArgs args;

  @override
  ConsumerState<ToImageScreen> createState() => _ToImageScreenState();
}

class _ToImageScreenState extends ConsumerState<ToImageScreen> {
  ToImageController get _controller => ref.read(toImageControllerProvider.notifier);

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

  Future<void> _choosePages() async {
    final state = ref.read(toImageControllerProvider);
    final source = state.source!;
    final pages = await Navigator.of(context).push<List<int>>(
      MaterialPageRoute(
        builder: (_) => PagePickerScreen(path: source.file.path, pageCount: source.pageCount, initial: state.pages),
      ),
    );
    if (pages != null) _controller.setPages(pages);
  }

  Future<void> _convert() async {
    final l10n = AppLocalizations.of(context);
    final stem = fileStem(ref.read(toImageControllerProvider).source!.file.name);
    Job start() => _controller.convert(l10n.nameImages(stem));
    while (mounted) {
      final retry = await context.push<bool>(
        Routes.processing,
        extra: ProcessingArgs(job: start(), title: l10n.processingConvert),
      );
      if (retry != true) break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(toImageControllerProvider);
    final source = state.source;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.toolToImageTitle)),
      body: switch (state) {
        ToImageState(loading: true) => const Center(child: CircularProgressIndicator()),
        ToImageState(source: null, :final failure) => _Prompt(
          failure: failure == null ? null : l10n.failureText(failure),
          onPick: _controller.pick,
        ),
        _ => _Options(state: state, onChange: _controller.pick, onChoosePages: _choosePages),
      },
      bottomNavigationBar: source == null ? null : _ConvertBar(state: state, onConvert: _convert),
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
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              failure ?? l10n.toImageEmpty,
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
  const _Options({required this.state, required this.onChange, required this.onChoosePages});

  final ToImageState state;
  final VoidCallback onChange, onChoosePages;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final controller = ref.read(toImageControllerProvider.notifier);
    final source = state.source!;
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
        section(l10n.formatLabel),
        _Choice<ImageFormat>(
          value: state.format,
          options: {ImageFormat.jpeg: l10n.formatJpg, ImageFormat.png: l10n.formatPng},
          onChanged: controller.setFormat,
        ),
        section(l10n.resolutionLabel),
        _Choice<int>(
          value: state.dpi,
          options: {for (final d in ToImageLimits.dpiChoices) d: l10n.dpiValue(d)},
          onChanged: controller.setDpi,
        ),
        const SizedBox(height: Space.s),
        Text(l10n.resolutionHelp, style: text.bodySmall?.copyWith(color: palette.muted)),
        section(l10n.pagesLabel),
        _Choice<bool>(
          value: state.pages == null,
          options: {true: l10n.pagesAll(source.pageCount), false: l10n.pagesChoose},
          onChanged: (all) => all ? controller.setPages(null) : onChoosePages(),
        ),
        if (state.pages case final pages?) ...[
          const SizedBox(height: Space.s),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.pagesChosen(pages.length, describePages([for (final p in pages) p + 1])),
                  style: text.bodyMedium,
                ),
              ),
              TextButton(onPressed: onChoosePages, child: Text(l10n.change)),
            ],
          ),
        ],
      ],
    );
  }
}

/// Mutually exclusive chips; each is a radio for screen readers.
class _Choice<T> extends StatelessWidget {
  const _Choice({required this.value, required this.options, required this.onChanged});

  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: Space.s,
    runSpacing: Space.s,
    children: [
      for (final MapEntry(key: option, value: label) in options.entries)
        Semantics(
          inMutuallyExclusiveGroup: true,
          checked: option == value,
          child: ChoiceChip(
            label: Text(label),
            selected: option == value,
            showCheckmark: false,
            onSelected: (_) => onChanged(option),
          ),
        ),
    ],
  );
}

class _ConvertBar extends StatelessWidget {
  const _ConvertBar({required this.state, required this.onConvert});

  final ToImageState state;
  final VoidCallback onConvert;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final count = state.chosen.length;
    final format = state.format == ImageFormat.jpeg ? 'JPG' : 'PNG';
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
              Text(
                state.tooMany
                    ? l10n.toImageTooMany(ToImageLimits.maxPages)
                    : l10n.toImageEstimate(count, format, formatBytes(state.estimatedBytes, l10n.localeName)),
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(color: state.tooMany ? palette.danger : palette.muted),
              ),
              const SizedBox(height: Space.m),
              FilledButton(onPressed: state.canConvert ? onConvert : null, child: Text(l10n.convertButton(count))),
            ],
          ),
        ),
      ),
    );
  }
}
