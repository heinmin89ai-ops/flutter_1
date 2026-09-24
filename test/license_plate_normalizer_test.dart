import 'package:flutter_test/flutter_test.dart';

import 'package:workshop_ops/features/customers_vehicles/domain/license_plate_normalizer.dart';

void main() {
  test('normalizes case, spaces, and hyphens for local lookup', () {
    expect(LicensePlateNormalizer.normalize(' ab-123 xy '), 'AB123XY');
    expect(LicensePlateNormalizer.normalize('***'), isEmpty);
  });
}