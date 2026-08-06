import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/drug_catalog_updater.dart';
import '../../l10n/app_localizations.dart';

class DrugCatalogUpdateDialog extends ConsumerStatefulWidget {
  const DrugCatalogUpdateDialog({super.key});

  @override
  ConsumerState<DrugCatalogUpdateDialog> createState() =>
      _DrugCatalogUpdateDialogState();
}

class _DrugCatalogUpdateDialogState
    extends ConsumerState<DrugCatalogUpdateDialog> {
  bool _isLoading = true;
  CatalogManifestInfo? _activeInfo;
  CatalogManifestInfo? _onlineInfo;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _loadActiveInfo();
  }

  Future<void> _loadActiveInfo() async {
    final updater = ref.read(drugCatalogUpdaterProvider);
    final active = await updater.getActiveCatalogInfo();
    if (mounted) {
      setState(() {
        _activeInfo = active;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleCheckUpdate() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    final updater = ref.read(drugCatalogUpdaterProvider);
    final online = await updater.checkCatalogUpdate();

    if (mounted) {
      setState(() {
        _onlineInfo = online;
        _isLoading = false;
        if (online == null) {
          _statusMessage = l10n.catalogCheckFailed;
        } else if (!online.isUpdateAvailable) {
          _statusMessage = l10n.catalogUpToDate;
        } else {
          _statusMessage = l10n.catalogUpdateAvailable(online.version);
        }
      });
    }
  }

  Future<void> _handleDownloadUpdate() async {
    if (_onlineInfo == null) return;
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    final updater = ref.read(drugCatalogUpdaterProvider);
    final success = await updater.downloadAndUpdateCatalog(_onlineInfo!);

    if (success) {
      ref.read(drugLookupServiceProvider).clearCache();
      await _loadActiveInfo();
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _statusMessage = success
            ? l10n.catalogUpdateSuccess
            : l10n.catalogUpdateFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.medical_information, color: Colors.teal),
          const SizedBox(width: 8),
          Expanded(child: Text(l10n.catalogUpdateTitle)),
        ],
      ),
      content: _isLoading
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_activeInfo != null) ...[
                    Text(
                      l10n.catalogActiveVersion(_activeInfo!.version),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.catalogDrugCount(_activeInfo!.drugCount),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _activeInfo!.isDownloaded
                          ? l10n.catalogSourceDownloaded
                          : l10n.catalogSourceBundled,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                  if (_statusMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _statusMessage!,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _statusMessage!.contains('gagal') ||
                                _statusMessage!.contains('failed')
                            ? Colors.red
                            : Colors.teal.shade800,
                      ),
                    ),
                  ],
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.guideCloseButton),
        ),
        if (_onlineInfo != null && _onlineInfo!.isUpdateAvailable)
          ElevatedButton.icon(
            key: const Key('downloadCatalogBtn'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            icon: const Icon(Icons.download),
            label: Text(l10n.catalogDownloadButton),
            onPressed: _isLoading ? null : _handleDownloadUpdate,
          )
        else
          OutlinedButton.icon(
            key: const Key('checkCatalogBtn'),
            icon: const Icon(Icons.refresh),
            label: Text(l10n.catalogCheckButton),
            onPressed: _isLoading ? null : _handleCheckUpdate,
          ),
      ],
    );
  }
}
