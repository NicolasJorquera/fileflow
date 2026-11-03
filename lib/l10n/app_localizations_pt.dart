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
  String recentsNote(String period) {
    return 'Fica em Recentes por $period. Use “Salvar em…” para mantê-lo no seu celular.';
  }

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

  @override
  String get toolOrganizeTitle => 'Organizar páginas';

  @override
  String get toolOrganizeSubtitle => 'Separar, extrair, girar';

  @override
  String get toolToImageTitle => 'PDF para imagem';

  @override
  String get toolToImageSubtitle => 'JPG ou PNG';

  @override
  String get nextToImage => 'Converter em imagem';

  @override
  String get choosePdf => 'Escolher um PDF';

  @override
  String get chooseToolTitle => 'O que você quer fazer?';

  @override
  String get change => 'Trocar';

  @override
  String get save => 'Salvar';

  @override
  String get select => 'Selecionar';

  @override
  String get delete => 'Excluir';

  @override
  String get more => 'Mais';

  @override
  String moreFor(String name) {
    return 'Mais opções para $name';
  }

  @override
  String get rotate => 'Girar';

  @override
  String get extract => 'Extrair';

  @override
  String get selectAll => 'Selecionar tudo';

  @override
  String get clearSelection => 'Limpar seleção';

  @override
  String selectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selecionadas',
      one: '1 selecionada',
    );
    return '$_temp0';
  }

  @override
  String get moveBefore => 'Mover para antes';

  @override
  String get moveAfter => 'Mover para depois';

  @override
  String pageLabel(int position) {
    return 'Página $position';
  }

  @override
  String pageLabelRotated(int position, int degrees) {
    return 'Página $position, girada $degrees°';
  }

  @override
  String sourceMeta(String name, int pages) {
    String _temp0 = intl.Intl.pluralLogic(pages, locale: localeName, other: '$pages págs.', one: '1 pág.');
    return '$name · $_temp0';
  }

  @override
  String get organizeEmpty => 'Escolha o PDF cujas páginas você quer reordenar, girar, extrair ou separar.';

  @override
  String get organizeHint => 'Toque nas páginas para escolhê-las. Mantenha pressionado para movê-las.';

  @override
  String get organizeLong => 'São muitas páginas: as miniaturas podem demorar a aparecer.';

  @override
  String get organizeKeepOne => 'Deve restar pelo menos uma página.';

  @override
  String organizeDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count páginas excluídas',
      one: '1 página excluída',
    );
    return '$_temp0';
  }

  @override
  String get discardTitle => 'Descartar alterações?';

  @override
  String get discardBody => 'Seu arquivo original não muda.';

  @override
  String get discard => 'Descartar';

  @override
  String get keepEditing => 'Continuar editando';

  @override
  String get splitMenu => 'Separar…';

  @override
  String get selectRangeMenu => 'Selecionar intervalo';

  @override
  String get splitTitle => 'Separar em vários PDFs';

  @override
  String get splitEvery => 'A cada certo número de páginas';

  @override
  String get splitEveryLabel => 'Páginas por arquivo';

  @override
  String get splitRanges => 'Por intervalos';

  @override
  String get splitEachPage => 'Uma página por arquivo';

  @override
  String splitButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Separar em $count arquivos',
      one: 'Separar em 1 arquivo',
    );
    return '$_temp0';
  }

  @override
  String get splitButtonIdle => 'Separar';

  @override
  String get rangeLabel => 'Páginas';

  @override
  String get rangeHint => '1-3, 5, 8-10';

  @override
  String rangeHelper(int count) {
    return 'De 1 a $count';
  }

  @override
  String get rangeEmpty => 'Digite páginas, por exemplo 1-3, 5.';

  @override
  String rangeNotANumber(String token) {
    return '“$token” não é uma página nem um intervalo.';
  }

  @override
  String rangeOutOfRange(String token, int count) {
    return '“$token” está fora do documento (1 a $count).';
  }

  @override
  String rangeReversed(String token) {
    return 'Em “$token” o primeiro número deve ser o menor.';
  }

  @override
  String nameEdited(String stem) {
    return '$stem (editado)';
  }

  @override
  String namePages(String stem, String pages) {
    return '$stem (págs. $pages)';
  }

  @override
  String namePage(String stem, String page) {
    return '$stem (pág. $page)';
  }

  @override
  String nameSplit(String stem) {
    return '$stem (separado)';
  }

  @override
  String nameImages(String stem) {
    return '$stem (imagens)';
  }

  @override
  String get processingSave => 'Salvando…';

  @override
  String get processingExtract => 'Extraindo…';

  @override
  String get processingSplit => 'Separando…';

  @override
  String get processingConvert => 'Convertendo…';

  @override
  String get toImageEmpty => 'Escolha o PDF que você quer transformar em imagens.';

  @override
  String get formatLabel => 'Formato';

  @override
  String get formatJpg => 'JPG · mais leve';

  @override
  String get formatPng => 'PNG · sem perda';

  @override
  String get resolutionLabel => 'Resolução';

  @override
  String dpiValue(int dpi) {
    return '$dpi dpi';
  }

  @override
  String get resolutionHelp => '150 dpi: fica bom na tela e no WhatsApp. 300 dpi: para imprimir.';

  @override
  String get pagesLabel => 'Páginas';

  @override
  String pagesAll(int count) {
    return 'Todas ($count)';
  }

  @override
  String get pagesChoose => 'Escolher páginas';

  @override
  String pagesChosen(int count, String list) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count páginas', one: '1 página');
    return '$_temp0: $list';
  }

  @override
  String usePages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Usar $count páginas',
      one: 'Usar 1 página',
      zero: 'Escolha páginas',
    );
    return '$_temp0';
  }

  @override
  String toImageEstimate(int count, String format, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count imagens $format',
      one: '1 imagem $format',
    );
    return '$_temp0 · cerca de $size no total';
  }

  @override
  String toImageTooMany(int max) {
    return 'Você pode converter até $max páginas de uma vez. Escolha menos páginas.';
  }

  @override
  String convertButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Converter $count páginas',
      one: 'Converter 1 página',
    );
    return '$_temp0';
  }

  @override
  String get resultEdited => 'Alterações salvas em um PDF novo';

  @override
  String resultExtracted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count páginas extraídas',
      one: 'Página extraída',
    );
    return '$_temp0';
  }

  @override
  String resultSplit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Separado em $count arquivos',
      one: 'Separado em 1 arquivo',
    );
    return '$_temp0';
  }

  @override
  String resultImages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count imagens prontas',
      one: '1 imagem pronta',
    );
    return '$_temp0';
  }

  @override
  String filesMeta(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count arquivos', one: '1 arquivo');
    return '$_temp0 · $size';
  }

  @override
  String andMore(int count) {
    return 'e mais $count';
  }

  @override
  String get shareAll => 'Compartilhar tudo';

  @override
  String get saveToFolder => 'Salvar em pasta…';

  @override
  String savedFolderSnack(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arquivos salvos',
      one: '1 arquivo salvo',
    );
    return '$_temp0';
  }

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count dias', one: '1 dia');
    return '$_temp0';
  }

  @override
  String get recentsNoteForever => 'Fica em Recentes até você excluí-lo.';

  @override
  String recentsNotice(String period) {
    return 'Os resultados são excluídos sozinhos após $period. Você pode mudar isso em Configurações.';
  }

  @override
  String get recentsNoticeForever =>
      'Os resultados ficam aqui até você excluí-los. Você pode mudar isso em Configurações.';

  @override
  String get groupToday => 'Hoje';

  @override
  String get groupWeek => 'Esta semana';

  @override
  String get groupOlder => 'Antes';

  @override
  String get tagMerged => 'Juntado';

  @override
  String get tagEdited => 'Editado';

  @override
  String get tagExtracted => 'Extraído';

  @override
  String get tagSplit => 'Separado';

  @override
  String get tagImages => 'Imagens';

  @override
  String expiresInDays(String size, int days) {
    String _temp0 = intl.Intl.pluralLogic(days, locale: localeName, other: '$days dias', one: '1 dia');
    return '$size · excluído em $_temp0';
  }

  @override
  String expiresToday(String size) {
    return '$size · excluído hoje';
  }

  @override
  String get useInTool => 'Usar em outra ferramenta';

  @override
  String get clearAll => 'Excluir tudo';

  @override
  String get clearAllTitle => 'Excluir tudo?';

  @override
  String clearAllBody(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count resultados serão excluídos',
      one: '1 resultado será excluído',
    );
    return '$_temp0 ($size). O que você salvou em outras pastas não muda.';
  }

  @override
  String get clearAllConfirm => 'Excluir';

  @override
  String get recentsEmptyTitle => 'Aqui você verá o que criar';

  @override
  String get recentsEmptyBody =>
      'Os PDFs e imagens que você criar com o FileFlow ficam aqui por um tempo para você poder compartilhá-los de novo.';

  @override
  String get settingsRecents => 'Recentes';

  @override
  String get retentionLabel => 'Excluir resultados automaticamente';

  @override
  String retentionAfter(String period) {
    return 'Depois de $period';
  }

  @override
  String get retentionNever => 'Nunca: eu excluo';

  @override
  String get retentionShortenTitle => 'Mudar o prazo?';

  @override
  String retentionShortenBody(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count resultados serão excluídos',
      one: '1 resultado será excluído',
    );
    return 'Com este prazo, $_temp0 agora ($size).';
  }

  @override
  String errTooManyPages(int pages, int max) {
    return 'São $pages páginas. O máximo é $max.';
  }
}
