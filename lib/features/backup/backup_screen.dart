import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/app_theme.dart';
import '../../core/providers.dart';
import '../../data/backup_service.dart';
import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth_session.dart';

final backupLogsFutureProvider = FutureProvider.autoDispose<List<BackupLog>>((ref) {
  final service = ref.watch(backupServiceProvider);
  return service.listBackupLogs();
});

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key, this.selectBackupFile});

  final Future<String?> Function()? selectBackupFile;

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _isLoading = false;
  String? _statusMessage;
  BackupPreview? _preview;

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

  Future<void> _selectRestoreBackup() async {
    final path = await (widget.selectBackupFile?.call() ?? _pickBackupFile());
    if (path == null) return;
    setState(() {
      _isLoading = true;
      _statusMessage = null;
      _preview = null;
    });
    try {
      final preview = await ref.read(backupServiceProvider).previewBackupJson(path);
      if (!mounted) return;
      setState(() => _preview = preview);
      await _handleRestoreBackup(path);
    } on BackupPreviewException catch (_) {
      if (mounted) setState(() => _statusMessage = AppLocalizations.of(context)!.invalidBackupFile);
    } catch (error) {
      if (mounted) setState(() => _statusMessage = 'Restore error: $error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String?> _pickBackupFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    return result?.files.singleOrNull?.path;
  }

  Future<void> _handleGoogleDriveBackup() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final driveService = ref.read(googleDriveBackupServiceProvider);
      final user = driveService.currentUser ?? await driveService.signInWithGoogle();
      if (user == null) {
        setState(() {
          _statusMessage = 'Google sign-in was cancelled.';
        });
        return;
      }

      final result = await driveService.uploadBackupToDrive(
        accessToken: user.accessToken,
      );
      setState(() {
        _statusMessage = result.success
            ? 'Backup uploaded to Google Drive (${user.email}): ${result.fileName} (${(result.fileSize / 1024).toStringAsFixed(1)} KB)'
            : 'Cloud Backup failed: ${result.errorMessage}';
      });
      ref.invalidate(backupLogsFutureProvider);
    } catch (e) {
      setState(() {
        _statusMessage = 'Google Drive error: $e';
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
    final currentUser = ref.watch(authSessionProvider);
    final permChecker = ref.watch(permissionCheckerProvider);
    final isAllowed = currentUser == null || permChecker.canManageBackup(currentUser.role);

    if (!isAllowed) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.backupTitle)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: AppTheme.dangerColor.withAlpha(150)),
              const SizedBox(height: 16),
              Text(
                l10n.backupAccessDenied,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.backupAccessDeniedDetail,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

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
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          key: const Key('createBackupBtn'),
                          icon: const Icon(Icons.backup),
                          label: Text(l10n.createBackupButton),
                          onPressed: _isLoading ? null : _handleCreateBackup,
                        ),
                        ElevatedButton.icon(
                          key: const Key('googleDriveBackupBtn'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                          icon: const Icon(Icons.cloud_upload),
                          label: Text(l10n.googleDriveBackup),
                          onPressed: _isLoading ? null : _handleGoogleDriveBackup,
                        ),
                        OutlinedButton.icon(
                          key: const Key('restoreBackupBtn'),
                          icon: const Icon(Icons.restore),
                          label: Text(l10n.restoreBackupButton),
                          onPressed: _isLoading ? null : _selectRestoreBackup,
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
                    if (_preview != null) ...[
                      const SizedBox(height: 12),
                      Text('Backup: ${_preview!.createdAt.toLocal()}'),
                      Text(
                        'Products: ${_preview!.counts['products']} • '
                        'Batches: ${_preview!.counts['stockBatches']} • '
                        'Sales: ${_preview!.counts['saleTransactions']}',
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
                    return Center(
                      child: Text(l10n.noBackupLogs),
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
                          '${l10n.backupLogDestination}: ${log.destination} (${log.status})',
                        ),
                        subtitle: Text(
                          '${log.timestamp.toIso8601String().split('.').first} • ${sizeKb.toStringAsFixed(1)} KB',
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('${l10n.backupLogError}: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
