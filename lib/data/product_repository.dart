import 'dart:convert';

import 'package:drift/drift.dart';

import 'audit_logger.dart';
import 'database.dart';

class ProductRepository {
  ProductRepository(this._db, {AuditLogger? auditLogger})
      : _auditLogger = auditLogger;

  final AppDatabase _db;
  final AuditLogger? _auditLogger;

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
        newValue: jsonEncode({'name': name, 'barcode': barcode, 'category': category}),
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
}
