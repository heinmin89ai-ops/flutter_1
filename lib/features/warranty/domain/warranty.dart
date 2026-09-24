enum WarrantyStatus { active, expired, voided }

class Warranty {
  const Warranty({
    required this.warrantyId,
    required this.shopId,
    required this.jobCardId,
    required this.vehicleId,
    required this.customerId,
    required this.startDate,
    required this.durationMonths,
    required this.expiryDate,
    required this.terms,
    required this.status,
  });

  final String warrantyId;
  final String shopId;
  final String jobCardId;
  final String vehicleId;
  final String customerId;
  final DateTime startDate;
  final int durationMonths;
  final DateTime expiryDate;
  final String terms;
  final WarrantyStatus status;

  static DateTime calculateExpiry(DateTime startDate, int durationMonths) {
    if (durationMonths < 1 || durationMonths > 120) throw ArgumentError('Warranty duration must be between 1 and 120 months.');
    final targetMonth = startDate.month + durationMonths;
    final year = startDate.year + ((targetMonth - 1) ~/ 12);
    final month = ((targetMonth - 1) % 12) + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, startDate.day > lastDay ? lastDay : startDate.day);
  }

  factory Warranty.fromMap(String id, Map<String, dynamic> map) {
    DateTime readDate(Object? value) => value is DateTime ? value : DateTime.fromMillisecondsSinceEpoch(0);
    return Warranty(
      warrantyId: id,
      shopId: map['shopId'] as String? ?? '',
      jobCardId: map['jobCardId'] as String? ?? '',
      vehicleId: map['vehicleId'] as String? ?? '',
      customerId: map['customerId'] as String? ?? '',
      startDate: readDate(map['startDate']),
      durationMonths: (map['durationMonths'] as num?)?.toInt() ?? 6,
      expiryDate: readDate(map['expiryDate']),
      terms: map['terms'] as String? ?? '',
      status: WarrantyStatus.values.firstWhere((value) => value.name.toUpperCase() == (map['status'] as String? ?? 'ACTIVE'), orElse: () => WarrantyStatus.active),
    );
  }
}
