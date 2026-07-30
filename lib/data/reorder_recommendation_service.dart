import 'database.dart';

class ReorderRecommendation {
  const ReorderRecommendation({
    required this.product,
    required this.currentStock,
    required this.openPurchaseQuantity,
    required this.recommendedQuantity,
  });

  final Product product;
  final int currentStock;
  final int openPurchaseQuantity;
  final int recommendedQuantity;
}

class ReorderRecommendationService {
  ReorderRecommendationService(this._database);

  final AppDatabase _database;

  /// Calculates max(0, threshold + lead-time demand - stock - open PO qty).
  Future<List<ReorderRecommendation>> recommend({
    required int leadTimeDemand,
  }) async {
    if (leadTimeDemand < 0) {
      throw ArgumentError.value(leadTimeDemand, 'leadTimeDemand');
    }
    final products = await _database.select(_database.products).get();
    final batches = await _database.select(_database.stockBatches).get();
    final orders = await (_database.select(_database.purchaseOrders)
          ..where((order) => order.status.equals('sent')))
        .get();
    final openOrderIds = orders.map((order) => order.id).toSet();
    final orderItems = await _database.select(_database.purchaseOrderItems).get();

    return products.map((product) {
      final stock = batches
          .where((batch) => batch.productId == product.id)
          .fold(0, (total, batch) => total + batch.qtyRemaining);
      final openQuantity = orderItems
          .where((item) => openOrderIds.contains(item.purchaseOrderId) && item.productId == product.id)
          .fold(0, (total, item) => total + item.qtyOrdered - item.qtyReceived);
      final recommendation = product.reorderThreshold + leadTimeDemand - stock - openQuantity;
      return ReorderRecommendation(
        product: product,
        currentStock: stock,
        openPurchaseQuantity: openQuantity,
        recommendedQuantity: recommendation > 0 ? recommendation : 0,
      );
    }).where((recommendation) => recommendation.recommendedQuantity > 0).toList();
  }
}
