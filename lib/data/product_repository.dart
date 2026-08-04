import 'dart:convert';

import 'package:drift/drift.dart';

import 'audit_logger.dart';
import 'database.dart';

class ProductStockSummary {
  const ProductStockSummary({required this.product, required this.stock});
  final Product product;
  final int stock;
}

class ProductRepository {
  ProductRepository(this._db, {AuditLogger? auditLogger})
      : _auditLogger = auditLogger;

  final AppDatabase _db;
  final AuditLogger? _auditLogger;

  Future<T> transaction<T>(Future<T> Function() action) =>
      _db.transaction(action);

  Future<void> recordCsvImportLog({
    required String sourceName,
    required String createdBy,
    required int totalRows,
    required int importedRows,
    required int rejectedRows,
    required String status,
    String? errorSummary,
  }) async {
    await _db.into(_db.csvImportLogs).insert(
          CsvImportLogsCompanion.insert(
            sourceName: sourceName,
            createdBy: createdBy,
            totalRows: totalRows,
            importedRows: importedRows,
            rejectedRows: rejectedRows,
            status: status,
            errorSummary: Value(errorSummary),
          ),
        );
  }

  Future<List<CsvImportLog>> listCsvImportLogs() {
    return (_db.select(_db.csvImportLogs)
          ..orderBy([
            (table) => OrderingTerm.desc(table.importedAt),
            (table) => OrderingTerm.desc(table.id),
          ]))
        .get();
  }

  Future<int> createStorageLocation({
    required String code,
    required String name,
    String? description,
  }) async {
    final id = await _db.into(_db.storageLocations).insert(
          StorageLocationsCompanion.insert(
            code: code,
            name: name,
            description: Value(description),
          ),
        );
    return id;
  }

  Future<List<StorageLocation>> listStorageLocations() {
    return _db.select(_db.storageLocations).get();
  }

  Future<int> createProduct({
    required String barcode,
    required String internalCode,
    required String name,
    required String activeIngredient,
    required double ingredientPct,
    required String baseUnit,
    required String purchaseUnit,
    required int unitsPerPurchaseUnit,
    required double costPricePerBaseUnit,
    required double marginPct,
    required int reorderThreshold,
    bool isControlled = false,
    String? nationalDrugCode,
    int? storageLocationId,
    required String category,
    required String createdBy,
    int? userIdForAudit,
  }) async {
    final id = await _db.into(_db.products).insert(
          ProductsCompanion.insert(
            barcode: barcode,
            internalCode: internalCode,
            name: name,
            activeIngredient: activeIngredient,
            ingredientPct: ingredientPct,
            baseUnit: baseUnit,
            purchaseUnit: purchaseUnit,
            unitsPerPurchaseUnit: unitsPerPurchaseUnit,
            costPricePerBaseUnit: costPricePerBaseUnit,
            marginPct: marginPct,
            reorderThreshold: reorderThreshold,
            isControlled: Value(isControlled),
            nationalDrugCode: Value(nationalDrugCode),
            storageLocationId: Value(storageLocationId),
            category: category,
            createdBy: createdBy,
          ),
        );

    if (_auditLogger != null && userIdForAudit != null) {
      await _auditLogger.log(
        tableName: 'products',
        recordId: id,
        action: 'create',
        newValue: jsonEncode(
            {'name': name, 'barcode': barcode, 'category': category}),
        userId: userIdForAudit,
      );
    }

    return id;
  }

  Future<bool> updateProduct(
    Product product, {
    required String updatedBy,
    int? userIdForAudit,
  }) async {
    final updated = product.copyWith(
      updatedBy: Value(updatedBy),
      updatedAt: Value(DateTime.now()),
    );
    final success = await _db.update(_db.products).replace(updated);

    if (success && _auditLogger != null && userIdForAudit != null) {
      await _auditLogger.log(
        tableName: 'products',
        recordId: product.id,
        action: 'update',
        newValue: jsonEncode({'name': product.name, 'updatedBy': updatedBy}),
        userId: userIdForAudit,
      );
    }

    return success;
  }

  Future<Product?> findProductByBarcode(String barcode) async {
    final rows = await (_db.select(_db.products)
          ..where((tbl) => tbl.barcode.equals(barcode)))
        .get();
    return rows.isEmpty ? null : rows.first;
  }

  Future<Product?> findProductByInternalCode(String internalCode) async {
    final rows = await (_db.select(_db.products)
          ..where((tbl) => tbl.internalCode.equals(internalCode)))
        .get();
    return rows.isEmpty ? null : rows.first;
  }

  Future<Product?> getProductById(int id) async {
    final rows = await (_db.select(_db.products)
          ..where((tbl) => tbl.id.equals(id)))
        .get();
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<Product>> listProducts({
    String? searchQuery,
    String? category,
    bool? isControlledOnly,
  }) async {
    final query = _db.select(_db.products);
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final pattern = '%${searchQuery.trim()}%';
      query.where(
        (tbl) =>
            tbl.name.like(pattern) |
            tbl.barcode.like(pattern) |
            tbl.internalCode.like(pattern) |
            tbl.activeIngredient.like(pattern),
      );
    }
    if (category != null && category.trim().isNotEmpty && category != 'All') {
      query.where((tbl) => tbl.category.equals(category));
    }
    if (isControlledOnly == true) {
      query.where((tbl) => tbl.isControlled.equals(true));
    }
    return query.get();
  }

  Future<List<ProductStockSummary>> listProductsWithStock(
      {String? searchQuery}) async {
    final products = await listProducts(searchQuery: searchQuery);
    if (products.isEmpty) return const [];
    final productIds = products.map((product) => product.id).toList();
    final batches = await (_db.select(_db.stockBatches)
          ..where((batch) => batch.productId.isIn(productIds)))
        .get();
    final stockByProduct = <int, int>{};
    for (final batch in batches) {
      stockByProduct.update(
        batch.productId,
        (stock) => stock + batch.qtyRemaining,
        ifAbsent: () => batch.qtyRemaining,
      );
    }
    return products
        .map((product) => ProductStockSummary(
              product: product,
              stock: stockByProduct[product.id] ?? 0,
            ))
        .toList();
  }
}
