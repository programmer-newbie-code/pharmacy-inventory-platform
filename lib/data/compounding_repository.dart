import 'package:drift/drift.dart';
import 'database.dart';

class IngredientInput {
  IngredientInput({
    required this.productId,
    required this.qtyPerYield,
    this.isActiveIngredient = true,
    this.notes,
  });

  final int productId;
  final double qtyPerYield;
  final bool isActiveIngredient;
  final String? notes;
}

class CompoundingRepository {
  CompoundingRepository(this._db);

  final AppDatabase _db;

  /// Creates a new compounding formula with its ingredients.
  Future<CompoundingFormula> createFormula({
    required String name,
    required String dosageForm,
    required int yieldQuantity,
    required String yieldUnit,
    required List<IngredientInput> ingredients,
    String? description,
    String? preparationNotes,
    int? createdBy,
  }) async {
    return _db.transaction(() async {
      final formulaId = await _db.into(_db.compoundingFormulas).insert(
            CompoundingFormulasCompanion.insert(
              name: name,
              dosageForm: dosageForm,
              yieldQuantity: yieldQuantity,
              yieldUnit: yieldUnit,
              description: Value(description),
              preparationNotes: Value(preparationNotes),
              createdBy: Value(createdBy),
              createdAt: Value(DateTime.now()),
            ),
          );

      for (final ing in ingredients) {
        await _db.into(_db.compoundingIngredients).insert(
              CompoundingIngredientsCompanion.insert(
                formulaId: formulaId,
                productId: ing.productId,
                qtyPerYield: ing.qtyPerYield,
                isActiveIngredient: Value(ing.isActiveIngredient),
                notes: Value(ing.notes),
              ),
            );
      }

      return (_db.select(_db.compoundingFormulas)
            ..where((tbl) => tbl.id.equals(formulaId)))
          .getSingle();
    });
  }

  /// Lists all compounding formulas.
  Future<List<CompoundingFormula>> listFormulas() {
    return (_db.select(_db.compoundingFormulas)
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]))
        .get();
  }

  /// Retrieves ingredients for a specific formula.
  Future<List<CompoundingIngredient>> getIngredientsForFormula(int formulaId) {
    return (_db.select(_db.compoundingIngredients)
          ..where((tbl) => tbl.formulaId.equals(formulaId)))
        .get();
  }

  /// Calculates estimated cost for a formula yield based on lowest active batch cost.
  Future<double> calculateFormulaCost(int formulaId, int yieldQty) async {
    final ingredients = await getIngredientsForFormula(formulaId);
    final formula = await (_db.select(_db.compoundingFormulas)
          ..where((tbl) => tbl.id.equals(formulaId)))
        .getSingle();

    final multiplier = yieldQty / formula.yieldQuantity;
    double totalCost = 0.0;

    for (final ing in ingredients) {
      final product = await (_db.select(_db.products)
            ..where((tbl) => tbl.id.equals(ing.productId)))
          .getSingle();
      final neededQty = ing.qtyPerYield * multiplier;
      totalCost += neededQty * product.costPricePerBaseUnit;
    }

    return totalCost;
  }
}
