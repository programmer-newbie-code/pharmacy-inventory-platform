import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../l10n/app_localizations.dart';

class CameraScannerDialog extends StatefulWidget {
  const CameraScannerDialog({super.key, this.scannerView});

  final Widget? scannerView;

  /// Helper static method to open the scanner modal and return the scanned barcode string.
  static Future<String?> scanBarcode(BuildContext context,
      {Widget? scannerView}) {
    return showDialog<String>(
      context: context,
      builder: (_) => CameraScannerDialog(scannerView: scannerView),
    );
  }

  @override
  State<CameraScannerDialog> createState() => _CameraScannerDialogState();
}

class _CameraScannerDialogState extends State<CameraScannerDialog>
    with WidgetsBindingObserver {
  MobileScannerController? _controller;
  bool _isDisposed = false;
  int _scannerGeneration = 0;

  @override
  void initState() {
    super.initState();
    if (widget.scannerView == null) {
      _controller = MobileScannerController();
      WidgetsBinding.instance.addObserver(this);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    try {
      _controller?.dispose();
    } catch (_) {}
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
      case AppLifecycleState.resumed:
        unawaited(controller.start());
      case AppLifecycleState.inactive:
        unawaited(controller.stop());
    }
  }

  Future<void> _retryScanner() async {
    final controller = _controller;
    if (controller == null) return;

    await controller.dispose();
    if (!mounted) return;

    final replacement = MobileScannerController();
    setState(() {
      _controller = replacement;
      _scannerGeneration++;
    });
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isDisposed || !mounted) return;
    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue != null && rawValue.trim().isNotEmpty) {
        try {
          _controller?.stop();
        } catch (_) {}
        if (mounted) Navigator.of(context).pop(rawValue.trim());
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 400,
        height: 480,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Theme.of(context).primaryColor,
              child: Row(
                children: [
                  const Icon(Icons.qr_code_scanner, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.cameraScannerTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    key: const Key('toggleTorchBtn'),
                    icon: const Icon(Icons.flash_on, color: Colors.white),
                    onPressed: () {
                      try {
                        _controller?.toggleTorch();
                      } catch (_) {}
                    },
                  ),
                  IconButton(
                    key: const Key('closeScannerBtn'),
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      if (context.mounted) Navigator.of(context).pop(null);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  widget.scannerView ??
                      MobileScanner(
                        key: ValueKey(_scannerGeneration),
                        controller: _controller!,
                        onDetect: _onDetect,
                        errorBuilder: (context, error, child) {
                          return CameraScannerErrorView(
                            errorCode: error.errorCode,
                            onRetry: _retryScanner,
                          );
                        },
                      ),
                  Container(
                    width: 250,
                    height: 180,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.greenAccent, width: 3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                AppLocalizations.of(context)!.cameraScannerInstruction,
                style: TextStyle(color: Colors.grey[700], fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CameraScannerErrorView extends StatelessWidget {
  const CameraScannerErrorView({
    super.key,
    required this.errorCode,
    required this.onRetry,
  });

  final MobileScannerErrorCode errorCode;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final permissionDenied =
        errorCode == MobileScannerErrorCode.permissionDenied;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              permissionDenied
                  ? Icons.camera_alt_outlined
                  : Icons.videocam_off_outlined,
              color: Theme.of(context).colorScheme.error,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              permissionDenied
                  ? l10n.cameraPermissionRequired
                  : l10n.cameraUnavailable,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              key: const Key('retryCameraScannerBtn'),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retryButton),
            ),
          ],
        ),
      ),
    );
  }
}
