class Vehicle {
  const Vehicle({
    required this.vehicleId,
    required this.shopId,
    required this.customerId,
    required this.licensePlate,
    required this.normalizedLicensePlate,
    required this.vin,
    required this.make,
    required this.model,
    required this.year,
    required this.color,
    required this.mileage,
    required this.fuelType,
    required this.transmission,
    required this.notes,
  });

  final String vehicleId;
  final String shopId;
  final String customerId;
  final String licensePlate;
  final String normalizedLicensePlate;
  final String? vin;
  final String? make;
  final String? model;
  final int? year;
  final String? color;
  final int? mileage;
  final String? fuelType;
  final String? transmission;
  final String? notes;

  factory Vehicle.fromMap(String id, Map<String, dynamic> map) {
    return Vehicle(
      vehicleId: id,
      shopId: map['shopId'] as String? ?? '',
      customerId: map['customerId'] as String? ?? '',
      licensePlate: map['licensePlate'] as String? ?? '',
      normalizedLicensePlate: map['normalizedLicensePlate'] as String? ?? '',
      vin: map['vin'] as String?,
      make: map['make'] as String?,
      model: map['model'] as String?,
      year: (map['year'] as num?)?.toInt(),
      color: map['color'] as String?,
      mileage: (map['mileage'] as num?)?.toInt(),
      fuelType: map['fuelType'] as String?,
      transmission: map['transmission'] as String?,
      notes: map['notes'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'vehicleId': vehicleId,
      'shopId': shopId,
      'customerId': customerId,
      'licensePlate': licensePlate,
      'normalizedLicensePlate': normalizedLicensePlate,
      'vin': vin,
      'make': make,
      'model': model,
      'year': year,
      'color': color,
      'mileage': mileage,
      'fuelType': fuelType,
      'transmission': transmission,
      'notes': notes,
    };
  }
}
