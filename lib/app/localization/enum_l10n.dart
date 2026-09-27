import '../../features/auth/domain/auth_user.dart';
import '../../features/billing/domain/invoice.dart';
import '../../features/customers_vehicles/domain/customer.dart';
import '../../features/inventory/domain/inventory_movement.dart';
import '../../features/job_cards/domain/job_card.dart';
import '../../features/warranty/domain/warranty.dart';
import '../../l10n/app_localizations.dart';

extension UserRoleL10n on UserRole {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    UserRole.superAdmin => l10n.roleSuperAdmin,
    UserRole.shopOwner => l10n.roleShopOwner,
    UserRole.manager => l10n.roleManager,
    UserRole.frontDesk => l10n.roleFrontDesk,
    UserRole.mechanic => l10n.roleMechanic,
  };
}

extension CustomerTypeL10n on CustomerType {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    CustomerType.individual => l10n.customerTypeIndividual,
    CustomerType.company => l10n.customerTypeCompany,
  };
}

extension WarrantyStatusL10n on WarrantyStatus {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    WarrantyStatus.active => l10n.statusActive,
    WarrantyStatus.expired => l10n.warrantyStatusExpired,
    WarrantyStatus.voided => l10n.warrantyStatusVoided,
  };
}

extension InventoryMovementTypeL10n on InventoryMovementType {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    InventoryMovementType.stockIn => l10n.inventoryMovementTypeStockIn,
    InventoryMovementType.stockOut => l10n.inventoryMovementTypeStockOut,
    InventoryMovementType.adjustment => l10n.inventoryMovementTypeAdjustment,
    InventoryMovementType.returnStock => l10n.inventoryMovementTypeReturn,
  };
}

extension InvoiceItemTypeL10n on InvoiceItemType {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    InvoiceItemType.labor => l10n.billingItemTypeLabor,
    InvoiceItemType.part => l10n.billingItemTypePart,
    InvoiceItemType.service => l10n.billingItemTypeService,
    InvoiceItemType.directSale => l10n.billingItemTypeDirectSale,
  };
}

extension PaymentMethodL10n on PaymentMethod {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    PaymentMethod.cash => l10n.billingPaymentMethodCash,
    PaymentMethod.card => l10n.billingPaymentMethodCard,
    PaymentMethod.bankTransfer => l10n.billingPaymentMethodBankTransfer,
    PaymentMethod.mobilePayment => l10n.billingPaymentMethodMobilePayment,
    PaymentMethod.other => l10n.billingPaymentMethodOther,
  };
}

extension InvoiceStatusL10n on InvoiceStatus {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    InvoiceStatus.draft => l10n.billingInvoiceStatusDraft,
    InvoiceStatus.issued => l10n.billingInvoiceStatusIssued,
    InvoiceStatus.partiallyPaid => l10n.billingInvoiceStatusPartiallyPaid,
    InvoiceStatus.paid => l10n.billingInvoiceStatusPaid,
    InvoiceStatus.voided => l10n.billingInvoiceStatusVoided,
  };
}

extension JobCardStatusL10n on JobCardStatus {
  /// Every [JobCardStatus] instance comes from the class's static constants, so
  /// matching the persisted [JobCardStatus.value] covers all displayable states.
  String localizedLabel(AppLocalizations l10n) => switch (value) {
    'DRAFT' => l10n.jobCardStatusDraft,
    'OPEN' => l10n.jobCardStatusOpen,
    'ASSIGNED' => l10n.jobCardStatusAssigned,
    'IN_PROGRESS' => l10n.jobCardStatusInProgress,
    'WAITING_FOR_PARTS' => l10n.jobCardStatusWaitingForParts,
    'WAITING_FOR_APPROVAL' => l10n.jobCardStatusWaitingForApproval,
    'COMPLETED' => l10n.jobCardStatusCompleted,
    'READY_FOR_PICKUP' => l10n.jobCardStatusReadyForPickup,
    'CLOSED' => l10n.jobCardStatusClosed,
    'CANCELLED' => l10n.jobCardStatusCancelled,
    _ => l10n.jobCardStatusDraft,
  };
}
