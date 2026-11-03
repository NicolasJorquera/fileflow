import '../../core/domain/settings.dart';
import '../../l10n/app_localizations.dart';

/// «1 día», «7 días», «30 días»; [RecentsRetention.untilDeleted] has its own
/// sentences instead.
String retentionLabel(AppLocalizations l10n, RecentsRetention retention) =>
    l10n.daysCount(retention.period?.inDays ?? 0);
