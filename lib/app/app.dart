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
import 'localization/app_locale.dart';
import '../l10n/app_localizations.dart';

class WorkshopOpsApp extends StatefulWidget {
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
  State<WorkshopOpsApp> createState() => _WorkshopOpsAppState();
}

class _WorkshopOpsAppState extends State<WorkshopOpsApp> {
  late final AppLocaleController _localeController = AppLocaleController(
    WidgetsBinding.instance.platformDispatcher.locales.any((locale) => locale.languageCode == 'my')
        ? const Locale('my')
        : const Locale('en'),
  );

  @override
  void dispose() {
    _localeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppLocaleScope(
      controller: _localeController,
      child: ListenableBuilder(
        listenable: _localeController,
        builder: (context, _) => MaterialApp(
          title: 'Workshop Ops',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          locale: _localeController.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: AuthGate(
            authRepository: widget.authRepository,
            customerVehicleRepository: widget.customerVehicleRepository,
            jobCardRepository: widget.jobCardRepository,
            inventoryRepository: widget.inventoryRepository,
            warrantyRepository: widget.warrantyRepository,
            billingRepository: widget.billingRepository,
            syncEngine: widget.syncEngine,
            reportRepository: widget.reportRepository,
            shopRepository: widget.shopRepository,
            staffRepository: widget.staffRepository,
          ),
        ),
      ),
    );
  }
}
