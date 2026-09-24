import 'warranty.dart';

abstract interface class WarrantyRepository {
  Stream<List<Warranty>> watchWarranties(String shopId);

  Future<Warranty> createWarranty({
    required String shopId,
    required String jobCardId,
    required String vehicleId,
    required String customerId,
    required int durationMonths,
    required String terms,
  });
}
