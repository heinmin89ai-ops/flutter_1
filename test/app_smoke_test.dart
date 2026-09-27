import 'package:flutter_test/flutter_test.dart';

import 'package:workshop_ops/app/app.dart';
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
    uid: 'test-user',
    email: 'staff@example.com',
    displayName: 'Test Staff',
    shopId: 'shop-test',
    role: UserRole.frontDesk,
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

class _EmptyShopRepository implements ShopRepository {
  @override
  Future<Shop> createShop({required String name, required String code}) => throw UnimplementedError();

  @override
  Stream<List<Shop>> watchAllShops() => Stream.value(const <Shop>[]);

  @override
  Stream<Shop?> watchShop(String shopId) => Stream.value(null);

  @override
  Future<void> updateShop({required Shop shop}) => throw UnimplementedError();
}

class _EmptyStaffRepository implements StaffRepository {
  @override
  Future<void> createStaff({required String shopId, required String email, required String name, required UserRole role}) => throw UnimplementedError();

  @override
  Future<void> updateStaff({required String shopId, required String uid, required UserRole role, required bool isActive}) => throw UnimplementedError();

  @override
  Stream<List<StaffMember>> watchStaff(String shopId) => Stream.value(const <StaffMember>[]);
}

class _EmptyCustomerVehicleRepository implements CustomerVehicleRepository {
  @override
  Future<Customer> createCustomer(Customer customer) => throw UnimplementedError();

  @override
  Future<Vehicle> createVehicle(Vehicle vehicle) => throw UnimplementedError();

  @override
  Future<void> initialize() async {}

  @override
  Future<List<Vehicle>> searchVehicles({required String shopId, required String licensePlate}) async => const [];

  @override
  Stream<List<Vehicle>> watchVehicles(String shopId) => Stream.value(const <Vehicle>[]);
}

class _EmptyJobCardRepository implements JobCardRepository {
  @override
  Future<void> assignMechanic({required String shopId, required String jobCardId, required String mechanicUid}) => throw UnimplementedError();

  @override
  Future<JobCard> createJobCard(JobCard jobCard) => throw UnimplementedError();

  @override
  Future<JobCard> transitionJobCard({required String shopId, required String jobCardId, required JobCardStatus target}) => throw UnimplementedError();

  @override
  Future<void> updateWorkNotes({required String shopId, required String jobCardId, required String notes, String? diagnosis}) => throw UnimplementedError();

  @override
  Stream<List<JobCard>> watchJobCards(String shopId) => Stream.value(const <JobCard>[]);
}

class _EmptyInventoryRepository implements InventoryRepository {
  @override
  Future<void> createItem(InventoryItem item) async {}

  @override
  Future<void> recordMovement({required String shopId, required String inventoryItemId, required InventoryMovementType type, required int quantity, required String reason}) async {}

  @override
  Stream<List<InventoryItem>> watchItems(String shopId) => Stream.value(const <InventoryItem>[]);
}

class _EmptyWarrantyRepository implements WarrantyRepository {
  @override
  Future<Warranty> createWarranty({required String shopId, required String jobCardId, required String vehicleId, required String customerId, required int durationMonths, required String terms}) => throw UnimplementedError();

  @override
  Stream<List<Warranty>> watchWarranties(String shopId) => Stream.value(const <Warranty>[]);
}

class _EmptyBillingRepository implements BillingRepository {
  @override
  Future<Invoice> createInvoice({required String shopId, required String jobCardId, required String customerId, required String vehicleId, required List<InvoiceItem> items}) => throw UnimplementedError();

  @override
  Future<void> receivePayment({required String shopId, required String invoiceId, required int amountMinorUnits, required PaymentMethod method, required String reference}) async {}

  @override
  Stream<List<Invoice>> watchInvoices(String shopId) => Stream.value(const <Invoice>[]);
}

class _EmptyReportRepository implements ReportRepository {
  @override
  Future<WorkshopReport> loadReport({required String shopId, required DateTime from, required DateTime to}) => throw UnimplementedError();
}

void main() {
  testWidgets('renders the workshop dashboard shell', (tester) async {
    await tester.pumpWidget(
      WorkshopOpsApp(
        authRepository: _SignedInAuthRepository(),
        shopRepository: _EmptyShopRepository(),
        staffRepository: _EmptyStaffRepository(),
        customerVehicleRepository: _EmptyCustomerVehicleRepository(),
        jobCardRepository: _EmptyJobCardRepository(),
        inventoryRepository: _EmptyInventoryRepository(),
        warrantyRepository: _EmptyWarrantyRepository(),
        billingRepository: _EmptyBillingRepository(),
        reportRepository: _EmptyReportRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Workshop overview'), findsOneWidget);
    expect(find.text('Open job cards'), findsOneWidget);
    // The app bar status button and the dashboard banner both show the label.
    expect(find.text('Pending changes'), findsNWidgets(2));
    expect(find.text('Local work is saved and waiting to sync.'), findsOneWidget);
  });
}
