import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/features/inventory/camera_scanner_dialog.dart';

void main() {
  testWidgets('renders CameraScannerDialog modal elements', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
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
