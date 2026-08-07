import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/data/compounding_repository.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';

void main() {
  late AppDatabase db;
  late CompoundingRepository compoundingRepo;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    compoundingRepo = CompoundingRepository(db);

    await db.into(db.products).insert(
          ProductsCompanion.insert(
            id: const Value(10),
            barcode: '899123456701',
            internalCode: 'P001',
            name: 'Paracetamol 500mg',
            activeIngredient: 'Paracetamol',
            ingredientPct: 100,
            baseUnit: 'tablet',
            purchaseUnit: 'box',
            unitsPerPurchaseUnit: 100,
            costPricePerBaseUnit: 200,
            marginPct: 30,
            reorderThreshold: 100,
            category: 'Analgesic',
            createdBy: 'admin',
          ),
        );

    await db.into(db.products).insert(
          ProductsCompanion.insert(
            id: const Value(11),
            barcode: '899123456702',
            internalCode: 'P002',
            name: 'CTM 4mg',
            activeIngredient: 'Chlorpheniramine',
            ingredientPct: 100,
            baseUnit: 'tablet',
            purchaseUnit: 'box',
            unitsPerPurchaseUnit: 100,
            costPricePerBaseUnit: 100,
            marginPct: 30,
            reorderThreshold: 100,
            category: 'Antihistamine',
            createdBy: 'admin',
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  test('createFormula, listFormulas, and calculateFormulaCost work correctly',
      () async {
    final formula = await compoundingRepo.createFormula(
      name: 'Puyer Batuk Anak',
      dosageForm: 'puyer',
      yieldQuantity: 10,
      yieldUnit: 'bungkus',
      description: 'Puyer batuk untuk anak 6-12 tahun',
      ingredients: [
        IngredientInput(productId: 10, qtyPerYield: 5), // 5 tablets Paracetamol
        IngredientInput(productId: 11, qtyPerYield: 2.5), // 2.5 tablets CTM
      ],
    );

    expect(formula.name, equals('Puyer Batuk Anak'));
    expect(formula.dosageForm, equals('puyer'));
    expect(formula.yieldQuantity, equals(10));

    final list = await compoundingRepo.listFormulas();
    expect(list, hasLength(1));

    final ingredients =
        await compoundingRepo.getIngredientsForFormula(formula.id);
    expect(ingredients, hasLength(2));

    // Calculate cost for 10 bungkus yield:
    // 5 * 200 (Paracetamol) = 1000
    // 2.5 * 100 (CTM) = 250
    // Total = 1250
    final cost = await compoundingRepo.calculateFormulaCost(formula.id, 10);
    expect(cost, equals(1250.0));
  });
}
