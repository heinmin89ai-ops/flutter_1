import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'app/app.dart';
import 'features/auth/data/firebase_auth_repository.dart';
import 'features/customers_vehicles/data/firebase_customer_vehicle_repository.dart';
import 'features/job_cards/data/firebase_job_card_repository.dart';
import 'features/inventory/data/firebase_inventory_repository.dart';
import 'features/warranty/data/firebase_warranty_repository.dart';
import 'features/billing/data/firebase_billing_repository.dart';
import 'features/shops/data/firebase_shop_repository.dart';
import 'features/shops/data/firebase_staff_repository.dart';
import 'core/sync/firestore_sync_handler.dart';
import 'core/sync/sqlite_sync_queue.dart';
import 'core/sync/sync_engine.dart';
import 'features/reports/data/firebase_report_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final syncQueue = SqliteSyncQueue();
  await syncQueue.initialize();
  final syncEngine = SyncEngine(queue: syncQueue, handler: FirestoreSyncOperationHandler());
  unawaited(syncEngine.start());
  final customerVehicleRepository = FirebaseCustomerVehicleRepository(syncQueue: syncQueue);
  await customerVehicleRepository.initialize();
  runApp(
    WorkshopOpsApp(
      authRepository: FirebaseAuthRepository(),
      customerVehicleRepository: customerVehicleRepository,
      jobCardRepository: FirebaseJobCardRepository(),
      inventoryRepository: FirebaseInventoryRepository(),
      warrantyRepository: FirebaseWarrantyRepository(),
      billingRepository: FirebaseBillingRepository(),
      shopRepository: FirebaseShopRepository(),
      staffRepository: FirebaseStaffRepository(),
      syncEngine: syncEngine,
      reportRepository: FirebaseReportRepository(),
    ),
  );
}
