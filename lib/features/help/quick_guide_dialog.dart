import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../l10n/app_localizations.dart';

class QuickGuideDialog extends StatelessWidget {
  const QuickGuideDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.help_outline, color: Colors.blue),
          const SizedBox(width: 8),
          Text(l10n.quickGuideTitle),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final versionStr = (snapshot.hasData && snapshot.data!.version.isNotEmpty)
                    ? ' v${snapshot.data!.version}'
                    : '';
                return Text(
                  l10n.quickGuideWelcome(versionStr),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                );
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.point_of_sale, color: Colors.green),
              title: Text(l10n.quickGuidePosTitle),
              subtitle: Text(l10n.quickGuidePosDescription),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.inventory, color: Colors.blue),
              title: Text(l10n.quickGuideInventoryTitle),
              subtitle: Text(l10n.quickGuideInventoryDescription),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.warning_amber, color: Colors.orange),
              title: Text(l10n.privacyTitle),
              subtitle: Text(l10n.privacyDescription),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.security, color: Colors.purple),
              title: Text(l10n.backupTitle),
              subtitle: Text(l10n.privacyEraseDescription),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          key: const Key('closeGuideButton'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.guideCloseButton),
        ),
      ],
    );
  }
}
