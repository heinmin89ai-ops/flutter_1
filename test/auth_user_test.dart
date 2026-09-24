import 'package:flutter_test/flutter_test.dart';

import 'package:workshop_ops/features/auth/domain/auth_user.dart';

void main() {
  test('parses supported role claims and rejects unknown values', () {
    expect(UserRoleLabel.fromClaim('SHOP_OWNER'), UserRole.shopOwner);
    expect(UserRoleLabel.fromClaim('mechanic'), UserRole.mechanic);
    expect(UserRoleLabel.fromClaim('unknown'), isNull);
    expect(UserRoleLabel.fromClaim(null), isNull);
  });
}