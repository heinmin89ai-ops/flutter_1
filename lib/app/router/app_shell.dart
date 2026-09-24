import 'package:flutter/material.dart';

import '../../core/sync/sync_status.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/customers_vehicles/domain/customer_vehicle_repository.dart';
import '../../features/customers_vehicles/presentation/vehicles_page.dart';
import '../../features/auth/domain/auth_repository.dart';
import '../../features/auth/domain/auth_user.dart';
import '../../features/shops/domain/shop_repository.dart';
import '../../features/shops/domain/staff_repository.dart';
import '../../features/shops/presentation/shops_page.dart';
import '../../features/job_cards/domain/job_card_repository.dart';
import '../../features/job_cards/presentation/job_cards_page.dart';
import '../../features/inventory/domain/inventory_repository.dart';
import '../../features/inventory/presentation/inventory_page.dart';
import '../../features/warranty/domain/warranty_repository.dart';
import '../../features/warranty/presentation/warranty_page.dart';
import '../../features/billing/domain/billing_repository.dart';
import '../../features/billing/presentation/billing_page.dart';
import '../../core/sync/sync_engine.dart';
import '../../features/reports/domain/report_repository.dart';
import '../../features/reports/presentation/reports_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.user,
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

  final AuthUser user;
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
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  SyncStatus _syncStatus = SyncStatus.pending;

  @override
  void initState() {
    super.initState();
    widget.syncEngine?.status.addListener(_syncStatusChanged);
    if (widget.syncEngine != null) _syncStatus = widget.syncEngine!.status.value;
  }

  @override
  void dispose() {
    widget.syncEngine?.status.removeListener(_syncStatusChanged);
    super.dispose();
  }

  List<_NavigationDestinationData> get _destinations {
    final destinations = <_NavigationDestinationData>[
      const _NavigationDestinationData(Icons.dashboard_outlined, 'Dashboard'),
      const _NavigationDestinationData(Icons.directions_car_outlined, 'Vehicles'),
      const _NavigationDestinationData(Icons.assignment_outlined, 'Job cards'),
      const _NavigationDestinationData(Icons.inventory_2_outlined, 'Inventory'),
      const _NavigationDestinationData(Icons.receipt_long_outlined, 'Billing'),
      const _NavigationDestinationData(Icons.verified_outlined, 'Warranty'),
    ];
    if (widget.user.role == UserRole.superAdmin || widget.user.role == UserRole.shopOwner) {
      destinations.add(const _NavigationDestinationData(Icons.groups_outlined, 'Shops & staff'));
    }
    if (widget.user.role == UserRole.superAdmin || widget.user.role == UserRole.shopOwner || widget.user.role == UserRole.manager) {
      destinations.add(const _NavigationDestinationData(Icons.analytics_outlined, 'Reports'));
    }
    return destinations;
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    final destinations = _destinations;
    if (_selectedIndex >= destinations.length) _selectedIndex = 0;
    final selectedLabel = destinations[_selectedIndex].label;

    return Scaffold(
      appBar: AppBar(
        title: Text(selectedLabel),
        actions: [
          _SyncStatusButton(
            status: _syncStatus,
            onPressed: _cycleSyncStatus,
          ),
          const SizedBox(width: 12),
          PopupMenuButton<String>(
            tooltip: 'Account menu',
            onSelected: (value) {
              if (value == 'signOut') widget.authRepository.signOut();
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'profile',
                enabled: false,
                child: Text(widget.user.displayName ?? widget.user.email ?? widget.user.uid),
              ),
              PopupMenuItem<String>(
                value: 'role',
                enabled: false,
                child: Text(widget.user.role?.label ?? 'Unknown role'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'signOut',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.logout),
                  title: Text('Sign out'),
                ),
              ),
            ],
            child: const CircleAvatar(child: Icon(Icons.person_outline)),
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: Row(
        children: [
          if (isWide)
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _selectDestination,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final destination in destinations)
                  NavigationRailDestination(
                    icon: Icon(destination.icon),
                    selectedIcon: Icon(destination.icon),
                    label: Text(destination.label),
                  ),
              ],
            ),
          Expanded(
            child: _selectedIndex == 0
                ? DashboardPage(syncStatus: _syncStatus)
                : selectedLabel == 'Vehicles'
                    ? VehiclesPage(user: widget.user, repository: widget.customerVehicleRepository)
                    : selectedLabel == 'Job cards'
                      ? JobCardsPage(user: widget.user, repository: widget.jobCardRepository)
                      : selectedLabel == 'Inventory'
                        ? InventoryPage(user: widget.user, repository: widget.inventoryRepository)
                        : selectedLabel == 'Warranty'
                          ? WarrantyPage(user: widget.user, repository: widget.warrantyRepository)
                          : selectedLabel == 'Billing'
                            ? BillingPage(user: widget.user, repository: widget.billingRepository)
                          : selectedLabel == 'Reports'
                            ? ReportsPage(user: widget.user, repository: widget.reportRepository)
                      : selectedLabel == 'Shops & staff'
                        ? ShopsPage(
                        user: widget.user,
                        shopRepository: widget.shopRepository,
                        staffRepository: widget.staffRepository,
                          )
                        : _ComingSoonPage(title: selectedLabel),
          ),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _selectDestination,
              destinations: [
                for (final destination in destinations)
                  NavigationDestination(
                    icon: Icon(destination.icon),
                    label: destination.label,
                  ),
              ],
            ),
    );
  }

  void _selectDestination(int index) {
    setState(() => _selectedIndex = index);
  }

  void _cycleSyncStatus() {
    widget.syncEngine?.syncNow();
  }

  void _syncStatusChanged() {
    if (mounted && widget.syncEngine != null) setState(() => _syncStatus = widget.syncEngine!.status.value);
  }
}

class _NavigationDestinationData {
  const _NavigationDestinationData(this.icon, this.label);

  final IconData icon;
  final String label;
}

class _SyncStatusButton extends StatelessWidget {
  const _SyncStatusButton({required this.status, required this.onPressed});

  final SyncStatus status;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      SyncStatus.online => Colors.green,
      SyncStatus.syncing => Colors.orange,
      SyncStatus.pending => Colors.blue,
      SyncStatus.offline || SyncStatus.failed => Colors.red,
    };

    return Tooltip(
      message: status.description,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(Icons.cloud_outlined, color: color),
        label: Text(status.label),
      ),
    );
  }
}

class _ComingSoonPage extends StatelessWidget {
  const _ComingSoonPage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$title module will be added with its local repository and sync contract.',
        textAlign: TextAlign.center,
      ),
    );
  }
}
