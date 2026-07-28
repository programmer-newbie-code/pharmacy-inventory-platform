import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class CameraScannerDialog extends StatefulWidget {
  const CameraScannerDialog({super.key, this.scannerView});

  final Widget? scannerView;

  /// Helper static method to open the scanner modal and return the scanned barcode string.
  static Future<String?> scanBarcode(BuildContext context, {Widget? scannerView}) {
    return showDialog<String>(
      context: context,
      builder: (_) => CameraScannerDialog(scannerView: scannerView),
    );
  }

  @override
  State<CameraScannerDialog> createState() => _CameraScannerDialogState();
}

class _CameraScannerDialogState extends State<CameraScannerDialog> {
  MobileScannerController? _controller;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    if (widget.scannerView == null) {
      _controller = MobileScannerController();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    try {
      _controller?.dispose();
    } catch (_) {}
    super.dispose();
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
                  const Expanded(
                    child: Text(
                      'Pindai Barcode Produk',
                      style: TextStyle(
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
                        controller: _controller!,
                        onDetect: _onDetect,
                        errorBuilder: (context, error, child) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                'Kamera tidak tersedia: ${error.errorCode}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
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
                'Arahkan kamera ke barcode produk',
                style: TextStyle(color: Colors.grey[700], fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
