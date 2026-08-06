import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';

class UpdateBanner extends ConsumerStatefulWidget {
  const UpdateBanner({super.key});

  @override
  ConsumerState<UpdateBanner> createState() => _UpdateBannerState();
}

class _UpdateBannerState extends ConsumerState<UpdateBanner> {
  bool _dismissed = false;

  void _openReleaseUrl(String url) {
    if (url.isEmpty) return;
    if (Platform.isWindows) {
      unawaited(Process.start('cmd', ['/c', 'start', '', url]));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final updateAsync = ref.watch(appUpdateCheckFutureProvider);
    final l10n = AppLocalizations.of(context)!;

    return updateAsync.when(
      data: (info) {
        if (info == null || !info.hasUpdate) return const SizedBox.shrink();

        return Container(
          key: const Key('updateBanner'),
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.shade400),
          ),
          child: Row(
            children: [
              Icon(Icons.system_update, color: Colors.amber.shade800),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.updateAvailableTitle(info.latestVersion),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.updateAvailableSubtitle(info.currentVersion),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                key: const Key('viewUpdateReleaseBtn'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.amber.shade900,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () => _openReleaseUrl(info.releaseUrl),
                child: Text(l10n.viewUpdateReleaseButton),
              ),
              IconButton(
                key: const Key('dismissUpdateBannerBtn'),
                icon: const Icon(Icons.close, size: 18),
                tooltip: l10n.dismissButton,
                onPressed: () => setState(() => _dismissed = true),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
