import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/data/reorder_recommendation_service.dart';

void main() {
  test('recommendation subtracts stock and open purchase quantities', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.into(db.products).insert(ProductsCompanion.insert(
      barcode: '899001', internalCode: 'P001', name: 'Paracetamol',
      activeIngredient: '', ingredientPct: 100, baseUnit: 'tablet', purchaseUnit: 'box',
      unitsPerPurchaseUnit: 10, costPricePerBaseUnit: 100, marginPct: 20,
      reorderThreshold: 50, category: 'Obat Bebas', createdBy: 'admin',
    ));
    await db.into(db.stockBatches).insert(StockBatchesCompanion.insert(
      productId: 1, batchNo: 'B1', receivedDate: DateTime(2026), expiryDate: DateTime(2027),
      qtyReceived: 20, qtyRemaining: 20, costPricePerBaseUnit: 100, supplier: 'S', createdBy: 'admin',
    ));
    final supplierId = await db.into(db.suppliers).insert(SuppliersCompanion.insert(name: 'S'));
    final poId = await db.into(db.purchaseOrders).insert(PurchaseOrdersCompanion.insert(
      poNumber: 'PO-1', supplierId: supplierId, status: 'sent', totalAmount: 100, createdBy: 'admin',
    ));
    await db.into(db.purchaseOrderItems).insert(PurchaseOrderItemsCompanion.insert(
      purchaseOrderId: poId, productId: 1, qtyOrdered: 15, unitCost: 100,
    ));

    final recommendations = await ReorderRecommendationService(db).recommend(leadTimeDemand: 10);
    expect(recommendations.single.recommendedQuantity, 25);
  });
}
