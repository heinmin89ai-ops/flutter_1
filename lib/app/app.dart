import 'package:flutter/material.dart';

import 'router/app_shell.dart';
import 'theme/app_theme.dart';
import '../features/auth/domain/auth_repository.dart';
import '../features/auth/presentation/auth_gate.dart';
import '../features/customers_vehicles/domain/customer_vehicle_repository.dart';
import '../features/job_cards/domain/job_card_repository.dart';
import '../features/inventory/domain/inventory_repository.dart';
import '../features/warranty/domain/warranty_repository.dart';
import '../features/billing/domain/billing_repository.dart';
import '../features/shops/domain/shop_repository.dart';
import '../features/shops/domain/staff_repository.dart';
import '../core/sync/sync_engine.dart';
import '../features/reports/domain/report_repository.dart';

class WorkshopOpsApp extends StatelessWidget {
  const WorkshopOpsApp({
    super.key,
    required this.authRepository,
    required this.customerVehicleRepository,
    required this.jobCardRepository,
    required this.inventoryRepository,
    required this.warrantyRepository,
    required this.billingRepository,
    this.syncEngine,
    required this.reportRepository,
    required this.shopRepository,
    required this.staffRepository,
  });

  final AuthRepository authRepository;
  final CustomerVehicleRepository customerVehicleRepository;
  final JobCardRepository jobCardRepository;
  final InventoryRepository inventoryRepository;
  final WarrantyRepository warrantyRepository;
  final BillingRepository billingRepository;
  final SyncEngine? syncEngine;
  final ReportRepository reportRepository;
  final ShopRepository shopRepository;
  final StaffRepository staffRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Workshop Ops',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: AuthGate(
        authRepository: authRepository,
        customerVehicleRepository: customerVehicleRepository,
        jobCardRepository: jobCardRepository,
        inventoryRepository: inventoryRepository,
        warrantyRepository: warrantyRepository,
        billingRepository: billingRepository,
        syncEngine: syncEngine,
        reportRepository: reportRepository,
        shopRepository: shopRepository,
        staffRepository: staffRepository,
      ),
    );
  }
}
