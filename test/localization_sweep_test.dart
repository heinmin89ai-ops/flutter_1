import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:workshop_ops/app/app.dart';
import 'package:workshop_ops/app/router/app_shell.dart';
import 'package:workshop_ops/core/sync/sync_status.dart';
import 'package:workshop_ops/l10n/app_localizations.dart';
import 'package:workshop_ops/features/auth/domain/auth_repository.dart';
import 'package:workshop_ops/features/auth/domain/auth_user.dart';
import 'package:workshop_ops/features/shops/domain/shop_repository.dart';
import 'package:workshop_ops/features/shops/domain/staff_repository.dart';
import 'package:workshop_ops/features/shops/domain/shop.dart';
import 'package:workshop_ops/features/shops/domain/staff_member.dart';
import 'package:workshop_ops/features/customers_vehicles/domain/customer.dart';
import 'package:workshop_ops/features/customers_vehicles/domain/customer_vehicle_repository.dart';
import 'package:workshop_ops/features/customers_vehicles/domain/vehicle.dart';
import 'package:workshop_ops/features/job_cards/domain/job_card.dart';
import 'package:workshop_ops/features/job_cards/domain/job_card_repository.dart';
import 'package:workshop_ops/features/inventory/domain/inventory_item.dart';
import 'package:workshop_ops/features/inventory/domain/inventory_movement.dart';
import 'package:workshop_ops/features/inventory/domain/inventory_repository.dart';
import 'package:workshop_ops/features/warranty/domain/warranty.dart';
import 'package:workshop_ops/features/warranty/domain/warranty_repository.dart';
import 'package:workshop_ops/features/billing/domain/billing_repository.dart';
import 'package:workshop_ops/features/billing/domain/invoice.dart';
import 'package:workshop_ops/features/reports/domain/report_repository.dart';
import 'package:workshop_ops/features/reports/domain/workshop_report.dart';

class _SignedInAuthRepository implements AuthRepository {
  final _user = const AuthUser(
    uid: 'test-owner',
    email: 'owner@example.com',
    displayName: 'Test Owner',
    shopId: 'shop-test',
    role: UserRole.shopOwner,
    permissions: <String>{},
    isActive: true,
  );

  @override
  Stream<AuthUser?> get authStateChanges => Stream.value(_user);

  @override
  Future<AuthUser> signIn({required String email, required String password}) async => _user;

  @override
  Future<void> signOut() async {}
}

class _SeededShopRepository implements ShopRepository {
  @override
  Future<Shop> createShop({required String name, required String code}) => throw UnimplementedError();

  @override
  Stream<List<Shop>> watchAllShops() => Stream.value(const [
    Shop(
      shopId: 'shop-test',
      name: 'City Motors',
      code: 'CMD',
      phone: '+95 9 1234567',
      email: 'city@example.com',
      address: 'No. 45, Konnott Road, Yangon, Myanmar',
      currency: 'MMK',
      timezone: 'Asia/Yangon',
      isActive: true,
      enabledModules: {'billing', 'warranty'},
    ),
  ]);

  @override
  Stream<Shop?> watchShop(String shopId) => watchAllShops().map((shops) => shops.first);

  @override
  Future<void> updateShop({required Shop shop}) async {}
}

class _SeededStaffRepository implements StaffRepository {
  @override
  Future<void> createStaff({required String shopId, required String email, required String name, required UserRole role}) async {}

  @override
  Future<void> updateStaff({required String shopId, required String uid, required UserRole role, required bool isActive}) async {}

  @override
  Stream<List<StaffMember>> watchStaff(String shopId) => Stream.value(const [
    StaffMember(
      uid: 'mech-1',
      shopId: 'shop-test',
      email: 'kyaw@example.com',
      name: 'U Kyaw Min',
      role: UserRole.mechanic,
      isActive: true,
      permissions: {},
    ),
    StaffMember(
      uid: 'fd-1',
      shopId: 'shop-test',
      email: 'su@example.com',
      name: 'Daw Su Hlaing',
      role: UserRole.frontDesk,
      isActive: false,
      permissions: {},
    ),
  ]);
}

class _SeededCustomerVehicleRepository implements CustomerVehicleRepository {
  @override
  Future<Customer> createCustomer(Customer customer) async => customer;

  @override
  Future<Vehicle> createVehicle(Vehicle vehicle) async => vehicle;

  @override
  Future<void> initialize() async {}

  @override
  Future<List<Vehicle>> searchVehicles({required String shopId, required String licensePlate}) async => const [];

  @override
  Stream<List<Vehicle>> watchVehicles(String shopId) => Stream.value(const [
    Vehicle(
      vehicleId: 'veh-1',
      shopId: 'shop-test',
      customerId: 'cus-1',
      licensePlate: 'YTA 8Z-123456',
      normalizedLicensePlate: 'YTA8Z123456',
      vin: 'JN1SA21Y9LW123456',
      make: 'Toyota',
      model: 'Hilux Revo Double Cab',
      year: 2019,
      color: 'Silver',
      mileage: 148230,
      fuelType: 'Diesel',
      transmission: 'Automatic',
      notes: 'Regular service customer',
    ),
  ]);
}

class _SeededJobCardRepository implements JobCardRepository {
  @override
  Future<void> assignMechanic({required String shopId, required String jobCardId, required String mechanicUid}) async {}

  @override
  Future<JobCard> createJobCard(JobCard jobCard) async => jobCard;

  @override
  Future<JobCard> transitionJobCard({required String shopId, required String jobCardId, required JobCardStatus target}) => throw UnimplementedError();

  @override
  Future<void> updateWorkNotes({required String shopId, required String jobCardId, required String notes, String? diagnosis}) async {}

  @override
  Stream<List<JobCard>> watchJobCards(String shopId) => Stream.value([
    JobCard(
      jobCardId: 'job-1',
      shopId: 'shop-test',
      jobNumber: 'JC-2026-0042',
      customerId: 'cus-1',
      vehicleId: 'veh-1',
      status: JobCardStatus.inProgress,
      priority: 'URGENT',
      complaint: 'Engine overheating after long drives and white smoke from the exhaust',
      diagnosis: 'Head gasket failure',
      repairNotes: 'Awaiting parts',
      assignedMechanicIds: const ['mech-1'],
      createdBy: 'test-owner',
      approvedBy: null,
      grandTotalMinorUnits: 4500000,
      openedAt: DateTime(2026, 9, 20),
      updatedAt: DateTime(2026, 9, 26),
    ),
  ]);
}

class _SeededInventoryRepository implements InventoryRepository {
  @override
  Future<void> createItem(InventoryItem item) async {}

  @override
  Future<void> recordMovement({required String shopId, required String inventoryItemId, required InventoryMovementType type, required int quantity, required String reason}) async {}

  @override
  Stream<List<InventoryItem>> watchItems(String shopId) => Stream.value(const [
    InventoryItem(
      inventoryItemId: 'inv-1',
      shopId: 'shop-test',
      sku: 'OIL-5W30-4L',
      name: 'Engine Oil 5W-30 Semi Synthetic 4 Litre',
      category: 'Fluids',
      unit: 'bottle',
      quantityOnHand: 3,
      minimumStock: 8,
      costPriceMinorUnits: 3200000,
      sellingPriceMinorUnits: 4200000,
      isActive: true,
    ),
  ]);
}

class _SeededWarrantyRepository implements WarrantyRepository {
  @override
  Future<Warranty> createWarranty({required String shopId, required String jobCardId, required String vehicleId, required String customerId, required int durationMonths, required String terms}) async => Warranty(
    warrantyId: 'war-1',
    shopId: shopId,
    jobCardId: jobCardId,
    vehicleId: vehicleId,
    customerId: customerId,
    startDate: DateTime(2026, 9, 1),
    durationMonths: durationMonths,
    expiryDate: Warranty.calculateExpiry(DateTime(2026, 9, 1), durationMonths),
    terms: 'Parts and labour covered for engine rebuild work.',
    status: WarrantyStatus.active,
  );

  @override
  Stream<List<Warranty>> watchWarranties(String shopId) => Stream.value([
    Warranty(
      warrantyId: 'war-1',
      shopId: 'shop-test',
      jobCardId: 'job-1',
      vehicleId: 'veh-1',
      customerId: 'cus-1',
      startDate: DateTime(2026, 3, 15),
      durationMonths: 12,
      expiryDate: DateTime(2027, 3, 15),
      terms: 'Covers replacement parts and labour. Excludes damage caused by misuse, racing or unauthorised modifications.',
      status: WarrantyStatus.active,
    ),
  ]);
}

class _SeededBillingRepository implements BillingRepository {
  @override
  Future<Invoice> createInvoice({required String shopId, required String jobCardId, required String customerId, required String vehicleId, required List<InvoiceItem> items}) => throw UnimplementedError();

  @override
  Future<void> receivePayment({required String shopId, required String invoiceId, required int amountMinorUnits, required PaymentMethod method, required String reference}) async {}

  @override
  Stream<List<Invoice>> watchInvoices(String shopId) => Stream.value(const [
    Invoice(
      invoiceId: 'inv-1',
      shopId: 'shop-test',
      invoiceNumber: 'INV-2026-0088',
      jobCardId: 'job-1',
      customerId: 'cus-1',
      vehicleId: 'veh-1',
      items: [
        InvoiceItem(type: InvoiceItemType.labor, description: 'Head gasket replacement labour', quantity: 1, unitPriceMinorUnits: 1500000, discountMinorUnits: 0, taxMinorUnits: 0),
        InvoiceItem(type: InvoiceItemType.part, description: 'Cylinder head gasket set', quantity: 1, unitPriceMinorUnits: 2800000, discountMinorUnits: 200000, taxMinorUnits: 0),
      ],
      subtotalMinorUnits: 4300000,
      discountMinorUnits: 200000,
      taxMinorUnits: 0,
      totalMinorUnits: 4100000,
      amountPaidMinorUnits: 1500000,
      balanceMinorUnits: 2600000,
      status: InvoiceStatus.partiallyPaid,
    ),
  ]);
}

class _SeededReportRepository implements ReportRepository {
  @override
  Future<WorkshopReport> loadReport({required String shopId, required DateTime from, required DateTime to}) async => WorkshopReport(
    from: DateTime(2026, 9, 1),
    to: DateTime(2026, 9, 27),
    completedJobs: 14,
    invoiceCount: 22,
    revenueMinorUnits: 18500000,
    paidMinorUnits: 12400000,
    outstandingMinorUnits: 6100000,
    lowStockItems: 3,
  );
}

Future<void> _launchOnPhone(WidgetTester tester, Locale locale) async {
  tester.view.physicalSize = const Size(360, 800) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);

  await tester.pumpWidget(
    WorkshopOpsApp(
      authRepository: _SignedInAuthRepository(),
      shopRepository: _SeededShopRepository(),
      staffRepository: _SeededStaffRepository(),
      customerVehicleRepository: _SeededCustomerVehicleRepository(),
      jobCardRepository: _SeededJobCardRepository(),
      inventoryRepository: _SeededInventoryRepository(),
      warrantyRepository: _SeededWarrantyRepository(),
      billingRepository: _SeededBillingRepository(),
      reportRepository: _SeededReportRepository(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openSection(WidgetTester tester, ShellSection section) async {
  tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(of: find.byType(Drawer), matching: find.byIcon(section.icon)),
  );
  await tester.pumpAndSettle();
}

void main() {
  const languages = <String, ({Locale locale, String name})>{
    'en': (locale: Locale('en'), name: 'English'),
    'my': (locale: Locale('my'), name: 'Burmese'),
  };

  for (final entry in languages.values) {
    testWidgets('every shell section lays out cleanly in ${entry.name}', (tester) async {
      final l10n = await AppLocalizations.delegate.load(entry.locale);
      await _launchOnPhone(tester, entry.locale);

      for (final section in ShellSection.values) {
        await _openSection(tester, section);

        expect(
          find.ancestor(of: find.text(section.label(l10n)), matching: find.byType(AppBar)),
          findsOneWidget,
          reason: '${section.name} should title the app bar in ${entry.name}',
        );
        expect(tester.takeException(), isNull, reason: '${section.name} body in ${entry.name}');
      }
    });

    testWidgets('create dialogs lay out cleanly in ${entry.name}', (tester) async {
      await _launchOnPhone(tester, entry.locale);

      for (final section in ShellSection.values) {
        await _openSection(tester, section);

        final addButton = find.byIcon(Icons.add);
        if (addButton.evaluate().isEmpty) continue;
        await tester.tap(addButton.first, warnIfMissed: false);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: '${section.name} create dialog in ${entry.name}');
        expect(find.byType(AlertDialog), findsOneWidget, reason: '${section.name} dialog in ${entry.name}');

        tester.state<NavigatorState>(find.byType(Navigator)).pop();
        await tester.pumpAndSettle();
      }
    });
  }

  testWidgets('no English strings survive on the Burmese dashboard', (tester) async {
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    final my = await AppLocalizations.delegate.load(const Locale('my'));
    await _launchOnPhone(tester, const Locale('my'));

    expect(find.text(my.workshopOverview), findsOneWidget);
    expect(find.text(en.workshopOverview), findsNothing);
    // On a phone the app bar keeps the status as an icon, so only the
    // dashboard banner spells the label out.
    expect(find.text(my.syncStatusPending), findsOneWidget);
    expect(find.text(en.syncStatusPending), findsNothing);
    expect(my.syncStatusPending, isNot(en.syncStatusPending));
  });

  testWidgets('account menu switches the app to Burmese', (tester) async {
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    final my = await AppLocalizations.delegate.load(const Locale('my'));
    await _launchOnPhone(tester, const Locale('en'));

    expect(find.text(en.workshopOverview), findsOneWidget);

    await tester.tap(find.byType(PopupMenuButton<String>), warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.text(en.languageMenuLabel), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text(my.workshopOverview), findsOneWidget);
    expect(find.text(en.workshopOverview), findsNothing);
    expect(SyncStatus.pending.label(my), isNot(equals(SyncStatus.pending.label(en))));
  });
}
