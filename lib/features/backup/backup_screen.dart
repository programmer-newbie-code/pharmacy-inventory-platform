import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/app_theme.dart';
import '../../core/providers.dart';
import '../../data/backup_service.dart';
import '../../data/database.dart';
import '../../data/google_drive_backup_service.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth_session.dart';
import '../settings/drive_setup_dialog.dart';

final backupLogsFutureProvider =
    FutureProvider.autoDispose<List<BackupLog>>((ref) {
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
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final service = ref.read(backupServiceProvider);
      final docsDir = await getApplicationDocumentsDirectory();
      final backupPath = await service.createBackupJson(docsDir.path);

      setState(() {
        _statusMessage = l10n.backupCreated(File(backupPath).path);
      });
      ref.invalidate(backupLogsFutureProvider);
    } catch (e) {
      setState(() {
        _statusMessage = l10n.backupCreateFailed;
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
        _statusMessage =
            success ? l10n.restoreSuccess : l10n.restoreFileMissing;
      });
      ref.invalidate(backupLogsFutureProvider);
    } catch (e) {
      setState(() {
        _statusMessage = l10n.restoreError;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectRestoreBackup() async {
    final l10n = AppLocalizations.of(context)!;
    final path = await (widget.selectBackupFile?.call() ?? _pickBackupFile());
    if (path == null) return;
    setState(() {
      _isLoading = true;
      _statusMessage = null;
      _preview = null;
    });
    try {
      final preview =
          await ref.read(backupServiceProvider).previewBackupJson(path);
      if (!mounted) return;
      setState(() => _preview = preview);
      await _handleRestoreBackup(path);
    } on BackupPreviewException catch (_) {
      if (mounted) {
        setState(() => _statusMessage = l10n.invalidBackupFile);
      }
    } catch (error) {
      if (mounted) setState(() => _statusMessage = l10n.restoreError);
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
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final driveService = ref.read(googleDriveBackupServiceProvider);
      final user =
          driveService.currentUser ?? await driveService.signInWithGoogle();
      if (user == null) {
        setState(() {
          _statusMessage = l10n.driveSignInCancelled;
        });
        return;
      }

      final result = await driveService.uploadBackupToDrive(
        accessToken: user.accessToken,
      );
      setState(() {
        _statusMessage = result.success
            ? l10n.driveBackupUploadedWithDetails(
                user.email,
                result.fileName,
                (result.fileSize / 1024).toStringAsFixed(1),
              )
            : _mapDriveError(result.errorMessage, l10n);
      });
      ref.invalidate(backupLogsFutureProvider);
    } on GoogleDriveConfigurationException {
      setState(() {
        _statusMessage = l10n.driveDesktopConfiguration;
      });
    } catch (error) {
      setState(() => _statusMessage = _mapDriveError(error, l10n));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _mapDriveError(Object? error, AppLocalizations l10n) {
    final message = error?.toString().toLowerCase() ?? '';
    if (message.contains('missingplugin') ||
        message.contains('not configured') ||
        message.contains('client id')) {
      return l10n.driveDesktopConfiguration;
    }
    if (message.contains('permission') ||
        message.contains('forbidden') ||
        message.contains('unauthorized')) {
      return l10n.drivePermissionDenied;
    }
    return l10n.driveError;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentUser = ref.watch(authSessionProvider);
    final permChecker = ref.watch(permissionCheckerProvider);
    final isAllowed =
        currentUser == null || permChecker.canManageBackup(currentUser.role);

    if (!isAllowed) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.backupTitle)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline,
                  size: 64, color: AppTheme.dangerColor.withAlpha(150)),
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
        child: SingleChildScrollView(
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
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo,
                                foregroundColor: Colors.white),
                            icon: const Icon(Icons.cloud_upload),
                            label: Text(l10n.googleDriveBackup),
                            onPressed:
                                _isLoading ? null : _handleGoogleDriveBackup,
                          ),
                          if (Platform.isWindows)
                            OutlinedButton.icon(
                              key: const Key('configureDriveBtn'),
                              icon: const Icon(Icons.settings),
                              label: Text(l10n.driveSetupButton),
                              onPressed: _isLoading
                                  ? null
                                  : () => showDialog(
                                        context: context,
                                        builder: (_) => const DriveSetupDialog(),
                                      ),
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
                        Text(l10n.backupPreviewLabel(
                            _preview!.createdAt.toLocal().toString())),
                        Text(
                          l10n.backupPreviewCounts(
                            _preview!.counts['products'] ?? 0,
                            _preview!.counts['stockBatches'] ?? 0,
                            _preview!.counts['saleTransactions'] ?? 0,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _AutoBackupCard(isLoading: _isLoading),
              const SizedBox(height: 16),
              Text(
                l10n.backupHistoryTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              logsAsync.when(
                data: (logs) {
                  if (logs.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        child: Text(l10n.noBackupLogs),
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      final sizeKb = (log.fileSize ?? 0) / 1024;
                      return ListTile(
                        leading: Icon(
                          log.destination == 'drive'
                              ? Icons.cloud
                              : Icons.folder,
                          color: log.status == 'Success'
                              ? Colors.green
                              : Colors.red,
                        ),
                        title: Text('${log.destination.toUpperCase()} Backup'),
                        subtitle: Text(
                          '${log.timestamp.toLocal()} • ${sizeKb.toStringAsFixed(1)} KB',
                        ),
                        trailing: Text(
                          log.status,
                          style: TextStyle(
                            color: log.status == 'Success'
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text(error.toString())),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AutoBackupCard extends ConsumerStatefulWidget {
  const _AutoBackupCard({required this.isLoading});

  final bool isLoading;

  @override
  ConsumerState<_AutoBackupCard> createState() => _AutoBackupCardState();
}

class _AutoBackupCardState extends ConsumerState<_AutoBackupCard> {
  bool _enabled = true;
  bool _driveEnabled = false;
  DateTime? _lastRun;
  DateTime? _nextRun;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final scheduler = ref.read(autoBackupSchedulerProvider);
    final enabled = await scheduler.isEnabled();
    final driveEnabled = await scheduler.isDriveEnabled();
    final lastRun = await scheduler.getLastBackupTime();
    final nextRun = await scheduler.getNextBackupTime();
    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      _driveEnabled = driveEnabled;
      _lastRun = lastRun;
      _nextRun = nextRun;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!_loaded) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _enabled ? Icons.schedule : Icons.schedule_outlined,
                  color: _enabled ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.autoBackupTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              key: const Key('autoBackupToggle'),
              title: Text(l10n.autoBackupEnabled),
              subtitle: Text(l10n.autoBackupDescription),
              value: _enabled,
              onChanged: widget.isLoading
                  ? null
                  : (val) async {
                      await ref
                          .read(autoBackupSchedulerProvider)
                          .setEnabled(val);
                      await _loadState();
                    },
            ),
            if (_enabled) ...[
              SwitchListTile(
                key: const Key('autoBackupDriveToggle'),
                title: Text(l10n.autoBackupDriveUpload),
                subtitle: Text(l10n.autoBackupDriveDescription),
                value: _driveEnabled,
                onChanged: widget.isLoading
                    ? null
                    : (val) async {
                        await ref
                            .read(autoBackupSchedulerProvider)
                            .setDriveEnabled(val);
                        await _loadState();
                      },
              ),
              const SizedBox(height: 8),
              if (_lastRun != null)
                Text(
                  l10n.autoBackupLastRun(
                    _lastRun!.toLocal().toString().split('.').first,
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              if (_nextRun != null)
                Text(
                  l10n.autoBackupNextRun(
                    _nextRun!.toLocal().toString().split('.').first,
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              if (_lastRun == null)
                Text(
                  l10n.autoBackupNeverRun,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ],
        ),
      ),
    );
  }
}
