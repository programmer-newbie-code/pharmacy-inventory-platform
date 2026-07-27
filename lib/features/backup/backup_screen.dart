import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/providers.dart';
import '../../data/database.dart';
import '../../l10n/app_localizations.dart';

final backupLogsFutureProvider = FutureProvider.autoDispose<List<BackupLog>>((ref) {
  final service = ref.watch(backupServiceProvider);
  return service.listBackupLogs();
});

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _isLoading = false;
  String? _statusMessage;

  Future<void> _handleCreateBackup() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final service = ref.read(backupServiceProvider);
      final docsDir = await getApplicationDocumentsDirectory();
      final backupPath = await service.createBackupJson(docsDir.path);
      
      setState(() {
        _statusMessage = 'Backup created: ${File(backupPath).path}';
      });
      ref.invalidate(backupLogsFutureProvider);
    } catch (e) {
      setState(() {
        _statusMessage = 'Backup failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRestoreBackup(String filePath) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.restoreConfirmTitle),
        content: Text(l10n.restoreConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancelButton),
          ),
          ElevatedButton(
            key: const Key('confirmRestoreBtn'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.confirmButton),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final service = ref.read(backupServiceProvider);
      final success = await service.restoreFromBackupJson(filePath);
      setState(() {
        _statusMessage = success
            ? 'Database successfully restored.'
            : 'Failed to restore: File not found.';
      });
      ref.invalidate(backupLogsFutureProvider);
    } catch (e) {
      setState(() {
        _statusMessage = 'Restore error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final logsAsync = ref.watch(backupLogsFutureProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.backupTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          key: const Key('createBackupBtn'),
                          icon: const Icon(Icons.backup),
                          label: Text(l10n.createBackupButton),
                          onPressed: _isLoading ? null : _handleCreateBackup,
                        ),
                        OutlinedButton.icon(
                          key: const Key('restoreBackupBtn'),
                          icon: const Icon(Icons.restore),
                          label: Text(l10n.restoreBackupButton),
                          onPressed: _isLoading ? null : () async {
                            final pathController = TextEditingController();
                            final path = await showDialog<String>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(l10n.restoreBackupButton),
                                content: TextField(
                                  controller: pathController,
                                  decoration: const InputDecoration(
                                    labelText: 'Backup JSON File Path',
                                    hintText: '/path/to/backup.json',
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    child: Text(l10n.cancelButton),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.of(ctx).pop(pathController.text),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                            if (path != null && path.isNotEmpty) {
                              await _handleRestoreBackup(path);
                            }
                          },
                        ),
                      ],
                    ),
                    if (_statusMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _statusMessage!,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.backupHistoryTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: logsAsync.when(
                data: (logs) {
                  if (logs.isEmpty) {
                    return const Center(
                      child: Text('No backup logs recorded yet.'),
                    );
                  }
                  return ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      final sizeKb = (log.fileSize ?? 0) / 1024;
                      return ListTile(
                        leading: Icon(
                          log.destination == 'restore'
                              ? Icons.restore
                              : Icons.storage,
                          color: log.status == 'Success'
                              ? Colors.green
                              : Colors.red,
                        ),
                        title: Text(
                          'Destination: ${log.destination} (${log.status})',
                        ),
                        subtitle: Text(
                          '${log.timestamp.toIso8601String().split('.').first} • ${sizeKb.toStringAsFixed(1)} KB',
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
