import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';

class DriveSetupDialog extends ConsumerStatefulWidget {
  const DriveSetupDialog({super.key});

  @override
  ConsumerState<DriveSetupDialog> createState() => _DriveSetupDialogState();
}

class _DriveSetupDialogState extends ConsumerState<DriveSetupDialog> {
  final _idController = TextEditingController();
  final _secretController = TextEditingController();
  bool _isLoading = true;
  bool _hasSavedCredentials = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _loadCurrentCredentials();
  }

  Future<void> _loadCurrentCredentials() async {
    final store = ref.read(driveCredentialStoreProvider);
    final id = await store.getClientId();
    final secret = await store.getClientSecret();
    final hasBoth = await store.hasCredentials();

    if (mounted) {
      setState(() {
        if (id != null) _idController.text = id;
        if (secret != null) _secretController.text = secret;
        _hasSavedCredentials = hasBoth;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _secretController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final l10n = AppLocalizations.of(context)!;
    final id = _idController.text.trim();
    final secret = _secretController.text.trim();

    if (id.isEmpty || secret.isEmpty) {
      setState(() {
        _statusMessage = l10n.driveSetupEmptyError;
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final store = ref.read(driveCredentialStoreProvider);
      await store.saveCredentials(clientId: id, clientSecret: secret);
      if (mounted) {
        setState(() {
          _hasSavedCredentials = true;
          _statusMessage = l10n.driveSetupSavedSuccess;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _statusMessage = l10n.driveSetupSaveError;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleClear() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);
    try {
      final store = ref.read(driveCredentialStoreProvider);
      await store.clearCredentials();
      if (mounted) {
        _idController.clear();
        _secretController.clear();
        setState(() {
          _hasSavedCredentials = false;
          _statusMessage = l10n.driveSetupClearedSuccess;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.cloud_sync, color: Colors.indigo),
          const SizedBox(width: 8),
          Expanded(child: Text(l10n.driveSetupTitle)),
        ],
      ),
      content: _isLoading
          ? const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.driveSetupInstruction,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('driveClientIdInput'),
                    controller: _idController,
                    decoration: InputDecoration(
                      labelText: l10n.driveClientIdLabel,
                      hintText: 'xxxxxx.apps.googleusercontent.com',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('driveClientSecretInput'),
                    controller: _secretController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: l10n.driveClientSecretLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  if (_statusMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _statusMessage!,
                      style: TextStyle(
                        color: _statusMessage!.contains('Error') ||
                                _statusMessage!.contains('gagal') ||
                                _statusMessage!.contains('kosong')
                            ? Colors.red
                            : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
      actions: [
        if (_hasSavedCredentials)
          TextButton(
            key: const Key('clearDriveCredentialsBtn'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: _isLoading ? null : _handleClear,
            child: Text(l10n.driveSetupClearButton),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButton),
        ),
        ElevatedButton(
          key: const Key('saveDriveCredentialsBtn'),
          onPressed: _isLoading ? null : _handleSave,
          child: Text(l10n.saveButton),
        ),
      ],
    );
  }
}
