/// Converts a quantity expressed in a product's purchase unit (e.g. "strip")
/// into its base unit (e.g. "tablet") using the product's conversion factor.
int convertToBaseUnit({
  required int quantityInPurchaseUnit,
  required int unitsPerPurchaseUnit,
}) {
  if (unitsPerPurchaseUnit <= 0) {
    throw ArgumentError.value(
      unitsPerPurchaseUnit,
      'unitsPerPurchaseUnit',
      'must be greater than zero',
    );
  }
  return quantityInPurchaseUnit * unitsPerPurchaseUnit;
}
