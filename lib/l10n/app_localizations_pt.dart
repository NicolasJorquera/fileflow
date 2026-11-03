// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appName => 'FileFlow';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get settingsAppearance => 'Aparência e idioma';

  @override
  String get themeLabel => 'Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get privacyNote => 'Tudo é processado no seu celular. Funciona sem conexão.';

  @override
  String pageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count páginas', one: '1 página');
    return '$_temp0';
  }

  @override
  String get homeSection => 'O que você precisa fazer?';

  @override
  String get recentTitle => 'Recentes';

  @override
  String get seeAll => 'Ver todos';

  @override
  String get toolMergeTitle => 'Juntar em um só';

  @override
  String get toolMergeSubtitle => 'Juntar PDF';

  @override
  String get interruptedNotice => 'A operação anterior foi interrompida. Seus arquivos originais não mudaram.';

  @override
  String get mergeHint => 'Arraste para mudar a ordem. Os arquivos são juntados de cima para baixo.';

  @override
  String get mergeAdd => 'Adicionar PDF';

  @override
  String get mergeEmpty => 'Escolha pelo menos 2 PDFs para juntá-los em um só.';

  @override
  String mergeSummary(int files, int pages) {
    String _temp0 = intl.Intl.pluralLogic(files, locale: localeName, other: '$files arquivos', one: '1 arquivo');
    String _temp1 = intl.Intl.pluralLogic(pages, locale: localeName, other: '$pages páginas', one: '1 página');
    return '$_temp0 · $_temp1';
  }

  @override
  String mergeButton(int files) {
    String _temp0 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: 'Juntar $files arquivos',
      one: 'Juntar 1 arquivo',
    );
    return '$_temp0';
  }

  @override
  String get mergeNeedTwo => 'Adicione pelo menos 2 PDFs';

  @override
  String mergeSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arquivos com problemas serão ignorados.',
      one: '1 arquivo com problemas será ignorado.',
    );
    return '$_temp0';
  }

  @override
  String mergeTooManyPages(int pages, int max) {
    return 'São $pages páginas. O máximo para juntar é $max.';
  }

  @override
  String mergeTooManyFiles(int max) {
    return 'Você pode juntar até $max arquivos de uma vez.';
  }

  @override
  String get mergeBig => 'São muitos MB: pode levar alguns minutos.';

  @override
  String mergedName(String date) {
    return 'Documento combinado $date';
  }

  @override
  String get itemPreparing => 'Preparando…';

  @override
  String itemMeta(int pages, String size) {
    String _temp0 = intl.Intl.pluralLogic(pages, locale: localeName, other: '$pages págs.', one: '1 pág.');
    return '$_temp0 · $size';
  }

  @override
  String removeItem(String name) {
    return 'Remover $name';
  }

  @override
  String moveItem(String name) {
    return 'Mover $name';
  }

  @override
  String get moveUp => 'Mover para cima';

  @override
  String get moveDown => 'Mover para baixo';

  @override
  String removedSnack(String name) {
    return '$name removido';
  }

  @override
  String get undo => 'Desfazer';

  @override
  String get processingMerge => 'Juntando…';

  @override
  String processingStep(int done, int total) {
    return 'Passo $done de $total';
  }

  @override
  String get processingHint => 'Você pode ir para outra tela: continuamos trabalhando enquanto o app estiver aberto.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get cancelConfirmTitle => 'Cancelar?';

  @override
  String get cancelConfirmBody => 'O progresso é descartado. Seus arquivos originais não mudam.';

  @override
  String get keepGoing => 'Continuar';

  @override
  String get back => 'Voltar';

  @override
  String get resultTitle => 'Pronto';

  @override
  String get resultMerged => 'Juntado em um só PDF';

  @override
  String resultMeta(int pages, String size) {
    String _temp0 = intl.Intl.pluralLogic(pages, locale: localeName, other: '$pages páginas', one: '1 página');
    return '$_temp0 · $size';
  }

  @override
  String get fileNameLabel => 'Nome do arquivo';

  @override
  String get share => 'Compartilhar';

  @override
  String get saveTo => 'Salvar em…';

  @override
  String get openWith => 'Abrir com outro app';

  @override
  String get nextStep => 'Próximo passo';

  @override
  String get nextMergeAnother => 'Juntar com outro PDF';

  @override
  String get recentsNote => 'Fica em Recentes por 7 dias. Use “Salvar em…” para mantê-lo no seu celular.';

  @override
  String get savedSnack => 'Salvo';

  @override
  String get close => 'Fechar';

  @override
  String get errDamaged => 'Não conseguimos abrir este arquivo. Ele pode estar danificado ou não ser um PDF.';

  @override
  String get errPassword => 'Este PDF tem senha. Esta versão ainda não consegue abri-lo.';

  @override
  String get errAccessLost => 'Não temos mais acesso a esse arquivo. Escolha-o novamente.';

  @override
  String errNoSpace(String size) {
    return 'Não há espaço suficiente. Você precisa de cerca de $size livres.';
  }

  @override
  String get errNoSpaceGeneric => 'Não há espaço suficiente no celular.';

  @override
  String get errNoApp => 'Não há um app para abrir este arquivo.';

  @override
  String get errGeneric => 'Algo deu errado ao processar o arquivo. Seu original não mudou.';

  @override
  String get retry => 'Tentar de novo';

  @override
  String processingPercent(int percent) {
    return '$percent%';
  }
}
