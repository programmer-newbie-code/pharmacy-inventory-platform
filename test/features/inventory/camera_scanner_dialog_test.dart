import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pharmacy_inventory_platform/features/inventory/camera_scanner_dialog.dart';
import 'package:pharmacy_inventory_platform/l10n/app_localizations.dart';

void main() {
  test('Android manifest declares camera permission', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

    expect(manifest, contains('android.permission.CAMERA'));
  });

  testWidgets('shows a retryable localized camera permission error',
      (tester) async {
    var retryCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('id'),
        home: Scaffold(
          body: CameraScannerErrorView(
            errorCode: MobileScannerErrorCode.permissionDenied,
            onRetry: () => retryCount++,
          ),
        ),
      ),
    );

    expect(find.text('Izin kamera diperlukan untuk memindai barcode.'),
        findsOneWidget);
    await tester.tap(find.byKey(const Key('retryCameraScannerBtn')));
    expect(retryCount, 1);
  });

  testWidgets('renders CameraScannerDialog modal elements', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('id'),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => CameraScannerDialog.scanBarcode(
                context,
                scannerView: const SizedBox(key: Key('mockScannerView')),
              ),
              child: const Text('Open Scanner'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Scanner'));
    await tester.pumpAndSettle();

    expect(find.text('Pindai Barcode Produk'), findsOneWidget);
    expect(find.byKey(const Key('mockScannerView')), findsOneWidget);
    expect(find.byKey(const Key('toggleTorchBtn')), findsOneWidget);
    expect(find.byKey(const Key('closeScannerBtn')), findsOneWidget);

    await tester.tap(find.byKey(const Key('toggleTorchBtn')));
    await tester.pump();
  });
}
