import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/formatters.dart';
import '../../core/providers.dart';
import '../../data/database.dart';
import '../../l10n/app_localizations.dart';

class CsvImportHistoryDialog extends ConsumerWidget {
  const CsvImportHistoryDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.csvImportHistoryTitle),
      content: SizedBox(
        width: 620,
        child: FutureBuilder<List<CsvImportLog>>(
          future: ref.read(productRepositoryProvider).listCsvImportLogs(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final logs = snapshot.data ?? const <CsvImportLog>[];
            if (logs.isEmpty) return Text(l10n.csvImportHistoryEmpty);
            return ListView.separated(
              shrinkWrap: true,
              itemCount: logs.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final log = logs[index];
                final succeeded = log.status == 'success';
                final date = log.importedAt.toLocal();
                final dateText =
                    '${formatLocalDate(date, Localizations.localeOf(context).languageCode)} ${DateFormat.Hm().format(date)}';
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    succeeded
                        ? Icons.check_circle_outline
                        : Icons.error_outline,
                    color: succeeded ? Colors.green : Colors.red,
                  ),
                  title: Text(log.sourceName, overflow: TextOverflow.ellipsis),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        succeeded
                            ? l10n.csvImportHistorySuccess(
                                log.importedRows,
                                log.rejectedRows,
                              )
                            : l10n.csvImportHistoryFailed,
                      ),
                      Text(l10n.csvImportHistoryActor(log.createdBy, dateText)),
                      Text(l10n.csvImportHistoryCounts(log.totalRows)),
                      if (log.errorSummary case final error?
                          when error.isNotEmpty)
                        Text(
                          l10n.csvImportHistoryError(error),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.doneButton),
        ),
      ],
    );
  }
}
