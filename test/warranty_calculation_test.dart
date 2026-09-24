import 'package:flutter_test/flutter_test.dart';

import 'package:workshop_ops/features/warranty/domain/warranty.dart';

void main() {
  test('calculates warranty expiry by calendar months', () {
    final expiry = Warranty.calculateExpiry(DateTime(2026, 1, 31), 1);
    expect(expiry, DateTime(2026, 2, 28));
  });

  test('rejects invalid warranty durations', () {
    expect(() => Warranty.calculateExpiry(DateTime(2026, 1, 1), 0), throwsArgumentError);
    expect(() => Warranty.calculateExpiry(DateTime(2026, 1, 1), 121), throwsArgumentError);
  });
}
