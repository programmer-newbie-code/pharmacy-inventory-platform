import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/data/receipt_pdf_service.dart';

void main() {
  late ReceiptPdfService service;

  setUp(() {
    service = ReceiptPdfService();
  });

  test('generateReceiptPdf generates non-empty PDF bytes for transaction', () async {
    final txn = SaleTransaction(
      id: 1,
      txnNo: 'TXN-20260728-001',
      cashierId: 1,
      totalAmount: 15000,
      paymentMethod: 'Cash',
      hasPrescription: true,
      patientName: 'John Doe',
      doctorName: 'Dr. Smith',
      createdAt: DateTime.now(),
    );

    final items = [
      const SaleItem(
        id: 101,
        transactionId: 1,
        productId: 10,
        batchId: 1001,
        qtySold: 2,
        unitPrice: 7500,
        subtotal: 15000,
      ),
    ];

    final productsMap = {
      10: Product(
        id: 10,
        barcode: '899123456701',
        internalCode: 'P001',
        name: 'Amoxicillin 500mg',
        activeIngredient: 'Amoxicillin',
        ingredientPct: 100,
        baseUnit: 'tablet',
        purchaseUnit: 'box',
        unitsPerPurchaseUnit: 100,
        costPricePerBaseUnit: 5000,
        marginPct: 50,
        reorderThreshold: 50,
        isControlled: true,
        category: 'Obat Keras',
        createdBy: 'admin',
        createdAt: DateTime.now(),
      ),
    };

    final pdfBytes = await service.generateReceiptPdf(
      transaction: txn,
      items: items,
      productsMap: productsMap,
    );

    expect(pdfBytes, isNotEmpty);
    expect(pdfBytes.length, greaterThan(100));
  });

  test('generateReceiptPdf accepts custom localized labels without error',
      () async {
    final txn = SaleTransaction(
      id: 2,
      txnNo: 'TXN-20260814-002',
      cashierId: 1,
      totalAmount: 5000,
      paymentMethod: 'Cash',
      hasPrescription: false,
      createdAt: DateTime.now(),
    );
    final items = [
      const SaleItem(
        id: 201,
        transactionId: 2,
        productId: 11,
        batchId: 1002,
        qtySold: 1,
        unitPrice: 5000,
        subtotal: 5000,
      ),
    ];

    // Overriding every label parameter must not throw and must still
    // produce a non-empty PDF; this is the seam receipt_dialog.dart uses to
    // pass localized (English/Indonesian) values without lib/data/
    // importing localization directly.
    final pdfBytes = await service.generateReceiptPdf(
      transaction: txn,
      items: items,
      productsMap: const {},
      txnNoLabel: 'Txn No',
      dateLabel: 'Date',
      cashierLabel: 'Cashier',
      paymentMethodLabel: 'Payment Method',
      doctorLabel: 'Doctor',
      patientLabel: 'Patient',
      itemColumnLabel: 'Item',
      qtyColumnLabel: 'Qty',
      totalRowLabel: 'TOTAL',
      footerMessage: '-- Thank You --\nGet well soon!',
    );

    expect(pdfBytes, isNotEmpty);
    expect(pdfBytes.length, greaterThan(100));
  });
}
