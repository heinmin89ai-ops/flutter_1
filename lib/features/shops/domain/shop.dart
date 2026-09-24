class Shop {
  const Shop({
    required this.shopId,
    required this.name,
    required this.code,
    required this.phone,
    required this.email,
    required this.address,
    required this.currency,
    required this.timezone,
    required this.isActive,
    required this.enabledModules,
  });

  final String shopId;
  final String name;
  final String code;
  final String? phone;
  final String? email;
  final String? address;
  final String currency;
  final String timezone;
  final bool isActive;
  final Set<String> enabledModules;

  factory Shop.fromMap(String id, Map<String, dynamic> map) {
    final modules = map['enabledModules'];
    return Shop(
      shopId: id,
      name: map['name'] as String? ?? 'Unnamed workshop',
      code: map['code'] as String? ?? id,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      address: map['address'] as String?,
      currency: map['currency'] as String? ?? 'USD',
      timezone: map['timezone'] as String? ?? 'UTC',
      isActive: map['isActive'] != false,
      enabledModules: modules is List ? modules.whereType<String>().toSet() : <String>{},
    );
  }
}
