import 'customer.dart';
import 'vehicle.dart';

abstract interface class CustomerVehicleRepository {
  Future<void> initialize();

  Stream<List<Vehicle>> watchVehicles(String shopId);

  Future<List<Vehicle>> searchVehicles({required String shopId, required String licensePlate});

  Future<Customer> createCustomer(Customer customer);

  Future<Vehicle> createVehicle(Vehicle vehicle);
}
