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
import '../../l10n/app_localizations.dart';
import '../localization/app_locale.dart';
import '../localization/enum_l10n.dart';

enum ShellSection {
  dashboard,
  vehicles,
  jobCards,
  inventory,
  billing,
  warranty,
  shops,
  reports,
}

extension ShellSectionLabel on ShellSection {
  String label(AppLocalizations l10n) => switch (this) {
    ShellSection.dashboard => l10n.navDashboard,
    ShellSection.vehicles => l10n.navVehicles,
    ShellSection.jobCards => l10n.navJobCards,
    ShellSection.inventory => l10n.navInventory,
    ShellSection.billing => l10n.navBilling,
    ShellSection.warranty => l10n.navWarranty,
    ShellSection.shops => l10n.navShopsStaff,
    ShellSection.reports => l10n.navReports,
  };

  IconData get icon => switch (this) {
    ShellSection.dashboard => Icons.dashboard_outlined,
    ShellSection.vehicles => Icons.directions_car_outlined,
    ShellSection.jobCards => Icons.assignment_outlined,
    ShellSection.inventory => Icons.inventory_2_outlined,
    ShellSection.billing => Icons.receipt_long_outlined,
    ShellSection.warranty => Icons.verified_outlined,
    ShellSection.shops => Icons.groups_outlined,
    ShellSection.reports => Icons.analytics_outlined,
  };
}

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
  final _scaffoldKey = GlobalKey<ScaffoldState>();
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

  List<ShellSection> get _sections {
    final sections = <ShellSection>[
      ShellSection.dashboard,
      ShellSection.vehicles,
      ShellSection.jobCards,
      ShellSection.inventory,
      ShellSection.billing,
      ShellSection.warranty,
    ];
    if (widget.user.role == UserRole.superAdmin || widget.user.role == UserRole.shopOwner) {
      sections.add(ShellSection.shops);
    }
    if (widget.user.role == UserRole.superAdmin || widget.user.role == UserRole.shopOwner || widget.user.role == UserRole.manager) {
      sections.add(ShellSection.reports);
    }
    return sections;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeController = AppLocaleScope.of(context);
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    final sections = _sections;
    if (_selectedIndex >= sections.length) _selectedIndex = 0;
    final selectedSection = sections[_selectedIndex];

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(selectedSection.label(l10n)),
        actions: [          _SyncStatusButton(
            status: _syncStatus,
            onPressed: _cycleSyncStatus,
          ),
          const SizedBox(width: 12),
          PopupMenuButton<String>(
            tooltip: l10n.accountMenu,
            onSelected: (value) {
              if (value == 'signOut') {
                widget.authRepository.signOut();
              } else if (value == 'language') {
                localeController.toggle();
              }
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
                child: Text(widget.user.role?.localizedLabel(l10n) ?? l10n.unknownRole),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'language',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.translate),
                  title: Text(l10n.languageMenuLabel),
                  subtitle: Text(localeController.isBurmese ? 'English' : 'မြန်မာ'),
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'signOut',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.logout),
                  title: Text(l10n.signOut),
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
                for (final section in sections)
                  NavigationRailDestination(
                    icon: Icon(section.icon),
                    selectedIcon: Icon(section.icon),
                    label: Text(section.label(l10n)),
                  ),
              ],
            ),
          Expanded(
            child: switch (selectedSection) {
              ShellSection.dashboard => DashboardPage(syncStatus: _syncStatus),
              ShellSection.vehicles => VehiclesPage(user: widget.user, repository: widget.customerVehicleRepository),
              ShellSection.jobCards => JobCardsPage(user: widget.user, repository: widget.jobCardRepository),
              ShellSection.inventory => InventoryPage(user: widget.user, repository: widget.inventoryRepository),
              ShellSection.warranty => WarrantyPage(user: widget.user, repository: widget.warrantyRepository),
              ShellSection.billing => BillingPage(user: widget.user, repository: widget.billingRepository),
              ShellSection.reports => ReportsPage(user: widget.user, repository: widget.reportRepository),
              ShellSection.shops => ShopsPage(
                user: widget.user,
                shopRepository: widget.shopRepository,
                staffRepository: widget.staffRepository,
              ),
            },
          ),
        ],
      ),
      // Eight sections do not fit in a bottom bar without their labels
      // wrapping, so phones get a labelled drawer instead.
      drawer: isWide
          ? null
          : _SectionDrawer(
              sections: sections,
              selected: selectedSection,
              onSelected: _selectDestination,
            ),
    );
  }

  void _selectDestination(int index) {
    setState(() => _selectedIndex = index);
    _scaffoldKey.currentState?.closeDrawer();
  }

  void _cycleSyncStatus() {
    widget.syncEngine?.syncNow();
  }

  void _syncStatusChanged() {
    if (mounted && widget.syncEngine != null) setState(() => _syncStatus = widget.syncEngine!.status.value);
  }
}

class _SectionDrawer extends StatelessWidget {
  const _SectionDrawer({
    required this.sections,
    required this.selected,
    required this.onSelected,
  });

  final List<ShellSection> sections;
  final ShellSection selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            for (var index = 0; index < sections.length; index++)
              ListTile(
                leading: Icon(sections[index].icon),
                title: Text(sections[index].label(l10n)),
                selected: sections[index] == selected,
                onTap: () => onSelected(index),
              ),
          ],
        ),
      ),
    );
  }
}

class _SyncStatusButton extends StatelessWidget {
  const _SyncStatusButton({required this.status, required this.onPressed});

  final SyncStatus status;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = switch (status) {
      SyncStatus.online => Colors.green,
      SyncStatus.syncing => Colors.orange,
      SyncStatus.pending => Colors.blue,
      SyncStatus.offline || SyncStatus.failed => Colors.red,
    };

    // The app bar has no room for a text label next to the account menu on a
    // phone, so the status shows as a colour-coded icon there.
    final isNarrow = MediaQuery.sizeOf(context).width < 720;
    final icon = Icon(Icons.cloud_outlined, color: color);

    return Tooltip(
      message: status.description(l10n),
      child: isNarrow
          ? IconButton(onPressed: onPressed, icon: icon)
          : OutlinedButton.icon(onPressed: onPressed, icon: icon, label: Text(status.label(l10n))),
    );
  }
}
