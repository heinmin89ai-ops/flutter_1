import 'package:flutter_test/flutter_test.dart';

import 'package:workshop_ops/features/billing/domain/invoice.dart';

void main() {
  test('calculates invoice totals using integer minor units', () {
    const items = [
      InvoiceItem(type: InvoiceItemType.labor, description: 'Labor', quantity: 2, unitPriceMinorUnits: 1500, discountMinorUnits: 100, taxMinorUnits: 290),
    ];
    expect(MoneyCalculator.subtotal(items), 3000);
    expect(MoneyCalculator.discount(items), 100);
    expect(MoneyCalculator.tax(items), 290);
    expect(MoneyCalculator.total(items), 3190);
  });
}