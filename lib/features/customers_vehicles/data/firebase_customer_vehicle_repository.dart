import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/customer.dart';
import '../domain/customer_vehicle_repository.dart';
import '../domain/license_plate_normalizer.dart';
import '../domain/vehicle.dart';
import 'sqlite_customer_vehicle_store.dart';
import '../../../core/sync/sqlite_sync_queue.dart';
import '../../../core/sync/sync_queue_item.dart';

class FirebaseCustomerVehicleRepository implements CustomerVehicleRepository {
  FirebaseCustomerVehicleRepository({
    FirebaseFirestore? firestore,
    SqliteCustomerVehicleStore? localStore,
    SqliteSyncQueue? syncQueue,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
      _localStore = localStore ?? SqliteCustomerVehicleStore(),
      _syncQueue = syncQueue;

  final FirebaseFirestore _firestore;
  final SqliteCustomerVehicleStore _localStore;
  final SqliteSyncQueue? _syncQueue;

  @override
  Future<void> initialize() => _localStore.initialize();

  @override
  Stream<List<Vehicle>> watchVehicles(String shopId) async* {
    final remoteSubscription = _firestore
        .collection('vehicles')
        .where('shopId', isEqualTo: shopId)
        .orderBy('normalizedLicensePlate')
        .snapshots()
        .listen((snapshot) async {
      for (final document in snapshot.docs) {
        await _localStore.upsertVehicle(Vehicle.fromMap(document.id, document.data()));
      }
    });
    try {
      yield* _localStore.watchVehicles(shopId);
    } finally {
      await remoteSubscription.cancel();
    }
  }

  @override
  Future<List<Vehicle>> searchVehicles({required String shopId, required String licensePlate}) {
    return _localStore.searchVehicles(shopId: shopId, licensePlate: licensePlate);
  }

  @override
  Future<Customer> createCustomer(Customer customer) async {
    await _localStore.upsertCustomer(customer);
    if (_syncQueue != null) {
      await _syncQueue!.enqueue(shopId: customer.shopId, entityType: 'customers', entityId: customer.customerId, operation: SyncOperation.create, payload: customer.toMap());
    } else {
      final reference = _firestore.collection('customers').doc(customer.customerId);
      await reference.set({...customer.toMap(), 'createdAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp()});
    }
    return customer;
  }

  @override
  Future<Vehicle> createVehicle(Vehicle vehicle) async {
    final normalizedVehicle = Vehicle(
      vehicleId: vehicle.vehicleId,
      shopId: vehicle.shopId,
      customerId: vehicle.customerId,
      licensePlate: vehicle.licensePlate.trim().toUpperCase(),
      normalizedLicensePlate: LicensePlateNormalizer.normalize(vehicle.licensePlate),
      vin: vehicle.vin?.trim().toUpperCase(),
      make: vehicle.make,
      model: vehicle.model,
      year: vehicle.year,
      color: vehicle.color,
      mileage: vehicle.mileage,
      fuelType: vehicle.fuelType,
      transmission: vehicle.transmission,
      notes: vehicle.notes,
    );
    await _localStore.upsertVehicle(normalizedVehicle);
    if (_syncQueue != null) {
      await _syncQueue!.enqueue(shopId: normalizedVehicle.shopId, entityType: 'vehicles', entityId: normalizedVehicle.vehicleId, operation: SyncOperation.create, payload: normalizedVehicle.toMap());
    } else {
      await _firestore.collection('vehicles').doc(normalizedVehicle.vehicleId).set({...normalizedVehicle.toMap(), 'createdAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp()});
    }
    return normalizedVehicle;
  }
}
