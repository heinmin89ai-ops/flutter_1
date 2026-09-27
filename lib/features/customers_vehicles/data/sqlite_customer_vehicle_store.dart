import 'dart:async';

import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../domain/customer.dart';
import '../domain/license_plate_normalizer.dart';
import '../domain/vehicle.dart';

class SqliteCustomerVehicleStore {
  Database? _database;
  final _vehicleChanges = StreamController<String>.broadcast();

  Future<void> initialize() async {
    if (_database != null) return;
    final databasePath = path.join(await getDatabasesPath(), 'workshop_ops.db');
    // SqliteSyncQueue opens this same file first and sqflite hands back the
    // existing connection, so neither onCreate nor onOpen runs a second time.
    final database = await openDatabase(databasePath, version: 1);
    await database.transaction((txn) async {
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS customers (
          customerId TEXT PRIMARY KEY,
          shopId TEXT NOT NULL,
          type TEXT NOT NULL,
          name TEXT NOT NULL,
          phone TEXT,
          email TEXT,
          address TEXT,
          companyName TEXT,
          taxId TEXT,
          notes TEXT,
          isActive INTEGER NOT NULL
        )
      ''');
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS vehicles (
          vehicleId TEXT PRIMARY KEY,
          shopId TEXT NOT NULL,
          customerId TEXT NOT NULL,
          licensePlate TEXT NOT NULL,
          normalizedLicensePlate TEXT NOT NULL,
          vin TEXT,
          make TEXT,
          model TEXT,
          year INTEGER,
          color TEXT,
          mileage INTEGER,
          fuelType TEXT,
          transmission TEXT,
          notes TEXT
        )
      ''');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_vehicles_plate ON vehicles(normalizedLicensePlate)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_vehicles_shop_updated ON vehicles(shopId)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_customers_shop ON customers(shopId)');
    });
    _database = database;
  }

  Stream<List<Vehicle>> watchVehicles(String shopId) async* {
    _requireDatabase();
    yield await _queryVehicles(shopId: shopId);
    yield* _vehicleChanges.stream.where((changedShopId) => changedShopId == shopId).asyncMap(
          (_) => _queryVehicles(shopId: shopId),
        );
  }

  Future<List<Vehicle>> searchVehicles({required String shopId, required String licensePlate}) async {
    _requireDatabase();
    final normalized = LicensePlateNormalizer.normalize(licensePlate);
    if (normalized.isEmpty) return const [];
    final rows = await _database!.query(
      'vehicles',
      where: 'shopId = ? AND normalizedLicensePlate LIKE ?',
      whereArgs: [shopId, '$normalized%'],
      orderBy: 'normalizedLicensePlate ASC',
      limit: 50,
    );
    return rows.map((row) => Vehicle.fromMap(row['vehicleId']! as String, row)).toList();
  }

  Future<void> upsertCustomer(Customer customer) async {
    _requireDatabase();
    await _database!.insert('customers', customer.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> upsertVehicle(Vehicle vehicle) async {
    _requireDatabase();
    await _database!.insert('vehicles', vehicle.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    _vehicleChanges.add(vehicle.shopId);
  }

  Future<List<Vehicle>> _queryVehicles({required String shopId}) async {
    final rows = await _database!.query('vehicles', where: 'shopId = ?', whereArgs: [shopId], orderBy: 'normalizedLicensePlate ASC');
    return rows.map((row) => Vehicle.fromMap(row['vehicleId']! as String, row)).toList();
  }

  void _requireDatabase() {
    if (_database == null) throw StateError('Customer vehicle store has not been initialized.');
  }

  Future<void> dispose() async {
    await _vehicleChanges.close();
    await _database?.close();
  }
}
