import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/domain/files.dart';
import '../../../core/domain/result.dart';
import '../../../core/format/sizes.dart';
import '../../../design_system/tokens.dart';

/// Dev-flavor only (not localized): exercises the file plumbing (H2) and the
/// engine + native JPEG pipeline (H3/S7) on a real device, printing
/// "[DIAG] ..." lines for `adb logcat -s flutter`.
class DiagnosticsScreen extends ConsumerStatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  ConsumerState<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends ConsumerState<DiagnosticsScreen> {
  final _log = <String>[];
  LocalFile? _imported;
  LocalFile? _result;
  JobDir? _job;
  bool _busy = false;
  StreamSubscription<List<PickedFile>>? _incoming;
  List<PickedFile> _shared = const [];

  String _mb(int bytes) => formatBytes(bytes, 'es');

  @override
  void initState() {
    super.initState();
    _incoming = ref.read(fileGatewayProvider).incomingShares().listen((files) {
      setState(() => _shared = files);
      _record('incoming: ${files.length} archivo(s): ${files.map((f) => f.mime).join(', ')}');
    });
    final interrupted = ref.read(interruptedJobsProvider);
    if (interrupted > 0) _record('al iniciar se limpiaron $interrupted trabajo(s) interrumpido(s)');
  }

  @override
  void dispose() {
    _incoming?.cancel();
    final job = _job;
    if (job != null) ref.read(jobWorkspaceProvider).delete(job);
    super.dispose();
  }

  void _record(String line) {
    debugPrint('[DIAG] $line');
    if (mounted) setState(() => _log.insert(0, line));
  }

  Future<void> _run(String name, Future<String> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    final sw = Stopwatch()..start();
    final rssBefore = ProcessInfo.currentRss;
    try {
      final detail = await action();
      _record(
        '$name OK ${sw.elapsedMilliseconds} ms · $detail · rss ${_mb(rssBefore)} → ${_mb(ProcessInfo.currentRss)} '
        '(máx ${_mb(ProcessInfo.maxRss)})',
      );
    } catch (e) {
      _record('$name ERROR ${e.runtimeType}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<JobDir> _freshJob() async {
    final workspace = ref.read(jobWorkspaceProvider);
    final old = _job;
    if (old != null) await workspace.delete(old);
    return _job = await workspace.create();
  }

  Future<String> _import(PickedFile picked) async {
    final result = await ref.read(fileGatewayProvider).importToJob(picked, await _freshJob());
    return switch (result) {
      Ok(:final value) => () {
        _imported = value;
        return '${value.name} ${_mb(value.sizeBytes)}';
      }(),
      Err(:final failure) => 'falló: ${failure.runtimeType}',
    };
  }

  Future<String> _pickAndImport() async {
    final picked = await ref.read(fileGatewayProvider).pickPdfs();
    final files = picked.valueOrNull ?? const <PickedFile>[];
    if (files.isEmpty) return 'cancelado';
    return _import(files.first);
  }

  /// Reduce at 110 dpi / quality 60 with two pages in flight (S7 settings).
  Future<String> _compress() async {
    final source = _imported;
    if (source == null) return 'primero importa un PDF';
    final engine = ref.read(pdfEngineProvider);
    final codec = ref.read(imageCodecProvider);
    final out = '${await ref.read(jobWorkspaceProvider).resultsDir()}/diagnostico (reducido).pdf';
    final doc = (await engine.open(source.path)).valueOrThrow;
    var next = 0, images = 0;
    try {
      Future<void> lane() async {
        while (next < doc.pageCount) {
          final page = next++;
          var changed = false;
          for (final slot in (await engine.imagesOnPage(doc, page)).valueOrThrow) {
            final resample = slot.effectiveDpi > 110 * 1.1;
            if (slot.hasTransparency || (!resample && slot.isJpeg)) continue;
            final rgba = (await engine.extractImage(
              doc,
              page,
              slot.objectIndex,
              resample ? 110 / slot.effectiveDpi : 1,
            )).valueOrThrow;
            final jpeg = await codec.encodeJpeg(
              rgba: rgba.pixels.materialize().asUint8List(),
              width: rgba.width,
              height: rgba.height,
              targetWidth: rgba.targetWidth,
              targetHeight: rgba.targetHeight,
              quality: 60,
            );
            final bytes = jpeg.valueOrNull;
            if (bytes == null) continue;
            await engine.replaceImageWithJpeg(doc, page, slot.objectIndex, TransferableTypedData.fromList([bytes]));
            changed = true;
            images++;
          }
          await engine.finishPage(doc, page, changed: changed);
        }
      }

      await Future.wait([lane(), lane()]);
      (await engine.save(doc, out)).valueOrThrow;
    } finally {
      await engine.close(doc);
    }
    final size = File(out).lengthSync();
    _result = LocalFile(path: out, name: 'diagnostico (reducido).pdf', sizeBytes: size);
    return '${doc.pageCount} págs, $images imágenes, ${_mb(source.sizeBytes)} → ${_mb(size)}';
  }

  Future<String> _save() async {
    final file = _result ?? _imported;
    if (file == null) return 'nada que guardar';
    final saved = await ref.read(fileGatewayProvider).saveAs(file, suggestedName: file.name);
    return switch (saved) {
      Ok(:final value) => value == null ? 'cancelado' : 'guardado',
      Err(:final failure) => 'falló: ${failure.runtimeType}',
    };
  }

  Future<String> _share() async {
    final file = _result;
    if (file == null) return 'primero comprime (solo se comparte desde results/)';
    final shared = await ref.read(fileGatewayProvider).share([file]);
    return shared.isOk ? 'hoja de compartir abierta' : 'falló';
  }

  @override
  Widget build(BuildContext context) {
    final actions = <(String, Future<String> Function())>[
      ('Elegir PDF e importar', _pickAndImport),
      ('Comprimir importado (110 dpi)', _compress),
      ('Guardar en…', _save),
      ('Compartir resultado', _share),
      if (_shared.isNotEmpty) ('Importar lo compartido (${_shared.length})', () => _import(_shared.first)),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Diagnóstico (dev)')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(Space.l),
            child: Wrap(
              spacing: Space.s,
              runSpacing: Space.s,
              children: [
                for (final (label, action) in actions)
                  FilledButton.tonal(onPressed: _busy ? null : () => _run(label, action), child: Text(label)),
              ],
            ),
          ),
          if (_busy) const LinearProgressIndicator(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(Space.l),
              children: [for (final l in _log) Text(l, style: const TextStyle(fontFamily: 'monospace', fontSize: 12))],
            ),
          ),
        ],
      ),
    );
  }
}
