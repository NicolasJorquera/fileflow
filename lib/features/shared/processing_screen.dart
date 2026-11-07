import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/domain/failures.dart';
import '../../core/domain/recents.dart';
import '../../core/jobs/jobs.dart';
import '../../design_system/theme.dart';
import '../../design_system/tokens.dart';
import '../../l10n/app_localizations.dart';
import 'failure_text.dart';

/// What [ProcessingScreen] follows.
class ProcessingArgs {
  const ProcessingArgs({required this.job, required this.title});

  final Job job;
  final String title;
}

/// Procesando (UX v1.0): big percentage, step, bar, note and Cancelar. A
/// finished job opens its result; a failed one shows the reason with
/// «Reintentar». Pops with `true` when the user asks to retry.
class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({super.key, required this.args});

  final ProcessingArgs args;

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  late final StreamSubscription<JobEvent> _events;
  final _started = Stopwatch()..start();
  JobProgress? _progress;
  AppFailure? _failure;

  /// Cancelling after this long asks first: there is work to lose.
  static const _confirmAfter = Duration(seconds: 10);

  @override
  void initState() {
    super.initState();
    _events = widget.args.job.events.listen(_onEvent);
  }

  @override
  void dispose() {
    _events.cancel();
    super.dispose();
  }

  void _onEvent(JobEvent event) {
    if (!mounted) return;
    switch (event) {
      case JobQueued():
        break;
      case JobProgress():
        setState(() => _progress = event);
      case JobCompleted(:final output) when output is RecentItem:
        _countTask();
        context.go(Routes.result(output.id));
      case JobCompleted():
        _countTask();
        Navigator.of(context).pop();
      case JobFailed(failure: Cancelled()):
        break;
      case JobFailed(:final failure):
        setState(() => _failure = failure);
    }
  }

  void _countTask() =>
      ProviderScope.containerOf(context, listen: false).read(interstitialProvider).recordCompletedTask();

  Future<void> _cancel() async {
    final l10n = AppLocalizations.of(context);
    if (_started.elapsed >= _confirmAfter) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.cancelConfirmTitle),
          content: Text(l10n.cancelConfirmBody),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.keepGoing)),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.cancel)),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    widget.args.job.cancel();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final failure = _failure;
    return PopScope(
      canPop: failure != null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: Scaffold(
        appBar: AppBar(automaticallyImplyLeading: false, title: Text(widget.args.title)),
        body: _FitOrScroll(child: failure == null ? _running(context) : _failed(context, failure)),
      ),
    );
  }

  Widget _running(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final progress = _progress;
    final fraction = progress == null || progress.total == 0 ? null : progress.done / progress.total;
    final percent = ((fraction ?? 0) * 100).floor();
    return Padding(
      padding: const EdgeInsets.all(Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          // Screen readers hear the percentage every 10 %, not on every step.
          Semantics(
            liveRegion: true,
            label: l10n.processingPercent(percent ~/ 10 * 10),
            child: ExcludeSemantics(
              child: Text(
                l10n.processingPercent(percent),
                textAlign: TextAlign.center,
                style: text.displayMedium?.copyWith(fontWeight: FontWeight.w700, color: palette.fg),
              ),
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: Space.s),
            Text(
              l10n.processingStep(progress.done, progress.total),
              textAlign: TextAlign.center,
              style: text.bodyLarge?.copyWith(color: palette.muted),
            ),
          ],
          const SizedBox(height: Space.xl),
          ClipRRect(
            borderRadius: BorderRadius.circular(Radii.small),
            child: LinearProgressIndicator(value: fraction, minHeight: 8, backgroundColor: palette.surface2),
          ),
          const SizedBox(height: Space.xl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 18, color: palette.muted),
              const SizedBox(width: Space.s),
              Expanded(
                child: Text(l10n.processingHint, style: text.bodySmall?.copyWith(color: palette.muted)),
              ),
            ],
          ),
          const Spacer(),
          OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(Touch.primaryButton)),
            onPressed: _cancel,
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  Widget _failed(BuildContext context, AppFailure failure) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    if (failure is AlreadyOptimized) return _alreadyOptimized(context);
    return Padding(
      padding: const EdgeInsets.all(Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Icon(Icons.error_outline, size: 48, color: palette.danger),
          const SizedBox(height: Space.l),
          Text(l10n.failureText(failure), textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.retry)),
          const SizedBox(height: Space.s),
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size.fromHeight(Touch.minTarget)),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.back),
          ),
        ],
      ),
    );
  }

  /// RN-03: not an error. Nothing was created; the original is the best file.
  Widget _alreadyOptimized(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Icon(Icons.verified_outlined, size: 48, color: palette.success),
          const SizedBox(height: Space.l),
          Semantics(
            liveRegion: true,
            child: Text(l10n.alreadyOptimizedTitle, textAlign: TextAlign.center, style: text.titleLarge),
          ),
          const SizedBox(height: Space.s),
          Text(
            l10n.alreadyOptimizedBody,
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(color: palette.muted),
          ),
          const Spacer(),
          FilledButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.back)),
        ],
      ),
    );
  }
}

/// Keeps the spaced-out layout on normal screens and scrolls when it does not
/// fit (large text, small phones).
class _FitOrScroll extends StatelessWidget {
  const _FitOrScroll({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: IntrinsicHeight(child: child),
      ),
    ),
  );
}
