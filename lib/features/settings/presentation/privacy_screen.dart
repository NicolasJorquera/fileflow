import 'package:flutter/material.dart';

import '../../../design_system/theme.dart';
import '../../../design_system/tokens.dart';
import '../../../l10n/app_localizations.dart';

/// «Cómo procesamos tus archivos» (H7): the privacy promises of the PRD in
/// plain words. The wording is checked by Legal before publishing.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final points = [
      (Icons.phone_android, l10n.privacyLocal),
      (Icons.no_accounts_outlined, l10n.privacyNoAccount),
      (Icons.history, l10n.privacyRecents),
      (Icons.document_scanner_outlined, l10n.privacyScanner),
      (Icons.campaign_outlined, l10n.privacyAds),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacyTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.xl),
        children: [
          for (final (icon, body) in points)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.l),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: palette.primary),
                  const SizedBox(width: Space.m),
                  Expanded(child: Text(body, style: text.bodyLarge)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
