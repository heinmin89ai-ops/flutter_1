import 'package:flutter/material.dart';

import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';
import '../../../app/router/app_shell.dart';
import 'login_page.dart';
import '../../shops/domain/shop_repository.dart';
import '../../shops/domain/staff_repository.dart';
import '../../customers_vehicles/domain/customer_vehicle_repository.dart';
import '../../job_cards/domain/job_card_repository.dart';
import '../../inventory/domain/inventory_repository.dart';
import '../../warranty/domain/warranty_repository.dart';
import '../../billing/domain/billing_repository.dart';
import '../../../core/sync/sync_engine.dart';
import '../../reports/domain/report_repository.dart';
import '../../../l10n/app_localizations.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.authRepository,
    required this.shopRepository,
    required this.staffRepository,
    required this.customerVehicleRepository,
    required this.jobCardRepository,
    required this.inventoryRepository,
    required this.warrantyRepository,
    required this.billingRepository,
    this.syncEngine,
    required this.reportRepository,
  });

  final AuthRepository authRepository;
  final ShopRepository shopRepository;
  final StaffRepository staffRepository;
  final CustomerVehicleRepository customerVehicleRepository;
  final JobCardRepository jobCardRepository;
  final InventoryRepository inventoryRepository;
  final WarrantyRepository warrantyRepository;
  final BillingRepository billingRepository;
  final SyncEngine? syncEngine;
  final ReportRepository reportRepository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthUser?>(
      stream: authRepository.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _AuthLoadingPage();
        }
        final user = snapshot.data;
        if (user == null) {
          return LoginPage(authRepository: authRepository);
        }
        if (!user.isActive || user.role == null || (user.role != UserRole.superAdmin && user.shopId == null)) {
          return _AccessDeniedPage(onSignOut: authRepository.signOut);
        }
        return AppShell(
          user: user,
          authRepository: authRepository,
          shopRepository: shopRepository,
          staffRepository: staffRepository,
          customerVehicleRepository: customerVehicleRepository,
          jobCardRepository: jobCardRepository,
          inventoryRepository: inventoryRepository,
          warrantyRepository: warrantyRepository,
          billingRepository: billingRepository,
          syncEngine: syncEngine,
          reportRepository: reportRepository,
        );
      },
    );
  }
}

class _AuthLoadingPage extends StatelessWidget {
  const _AuthLoadingPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _AccessDeniedPage extends StatelessWidget {
  const _AccessDeniedPage({required this.onSignOut});

  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.gpp_bad_outlined, size: 56),
                const SizedBox(height: 16),
                Text(l10n.accessNotConfiguredTitle, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(l10n.accessNotConfiguredBody),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onSignOut,
                  icon: const Icon(Icons.logout),
                  label: Text(l10n.signOut),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
