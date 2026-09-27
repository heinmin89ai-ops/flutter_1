enum CustomerType { individual, company }

extension CustomerTypeLabel on CustomerType {
  static CustomerType fromValue(Object? value) {
    return value == 'COMPANY' ? CustomerType.company : CustomerType.individual;
  }

  String get value => this == CustomerType.company ? 'COMPANY' : 'INDIVIDUAL';
}

class Customer {
  const Customer({
    required this.customerId,
    required this.shopId,
    required this.type,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.companyName,
    required this.taxId,
    required this.notes,
    required this.isActive,
  });

  final String customerId;
  final String shopId;
  final CustomerType type;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? companyName;
  final String? taxId;
  final String? notes;
  final bool isActive;

  factory Customer.fromMap(String id, Map<String, dynamic> map) {
    return Customer(
      customerId: id,
      shopId: map['shopId'] as String? ?? '',
      type: CustomerTypeLabel.fromValue(map['type']),
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      address: map['address'] as String?,
      companyName: map['companyName'] as String?,
      taxId: map['taxId'] as String?,
      notes: map['notes'] as String?,
      isActive: map['isActive'] != false,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'customerId': customerId,
      'shopId': shopId,
      'type': type.value,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'companyName': companyName,
      'taxId': taxId,
      'notes': notes,
      'isActive': isActive,
    };
  }
}
