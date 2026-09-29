// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Workshop Ops';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navVehicles => 'Vehicles';

  @override
  String get navJobCards => 'Job cards';

  @override
  String get navInventory => 'Inventory';

  @override
  String get navBilling => 'Billing';

  @override
  String get navWarranty => 'Warranty';

  @override
  String get navShopsStaff => 'Shops & staff';

  @override
  String get navReports => 'Reports';

  @override
  String get accountMenu => 'Account menu';

  @override
  String get unknownRole => 'Unknown role';

  @override
  String get signOut => 'Sign out';

  @override
  String get signInSubtitle => 'Sign in with your staff account.';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get signIn => 'Sign in';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get validationValidEmail => 'Enter a valid email.';

  @override
  String get validationPasswordLength =>
      'Password must be at least 6 characters.';

  @override
  String get signInFailed => 'Unable to sign in. Please try again.';

  @override
  String get accessNotConfiguredTitle => 'Access not configured';

  @override
  String get accessNotConfiguredBody =>
      'Your account does not have an active workshop role. Contact an administrator.';

  @override
  String get workshopOverview => 'Workshop overview';

  @override
  String get workshopOverviewSubtitle =>
      'A clear view of today\'s work, even when the network is unavailable.';

  @override
  String get metricOpenJobCards => 'Open job cards';

  @override
  String get metricOpenJobCardsDetail => 'No records loaded yet';

  @override
  String get metricVehiclesToday => 'Vehicles today';

  @override
  String get metricVehiclesTodayDetail => 'Ready for local search';

  @override
  String get metricInProgress => 'In progress';

  @override
  String get metricInProgressDetail => 'Assigned mechanic work';

  @override
  String get metricPendingBalance => 'Pending balance';

  @override
  String get metricPendingBalanceDetail =>
      'Currency will come from shop settings';

  @override
  String get todaySectionTitle => 'Today';

  @override
  String get todayPlateSearchTitle => 'License plate search';

  @override
  String get todayPlateSearchSubtitle =>
      'Local indexed search will be available in the Customers and Vehicles phase.';

  @override
  String get todaySyncQueueTitle => 'Sync queue';

  @override
  String get todaySyncQueueSubtitle =>
      'Every offline mutation will remain visible until cloud synchronization completes.';

  @override
  String get syncStatusOnline => 'Online';

  @override
  String get syncStatusOffline => 'Offline';

  @override
  String get syncStatusSyncing => 'Syncing';

  @override
  String get syncStatusPending => 'Pending changes';

  @override
  String get syncStatusFailed => 'Sync failed';

  @override
  String get syncDescOnline => 'All local changes are synchronized.';

  @override
  String get syncDescOffline => 'Changes will be queued on this device.';

  @override
  String get syncDescSyncing => 'Uploading local changes securely.';

  @override
  String get syncDescPending => 'Local work is saved and waiting to sync.';

  @override
  String get syncDescFailed => 'Some changes need attention before retrying.';

  @override
  String get retry => 'Retry';

  @override
  String get languageMenuLabel => 'Change language';

  @override
  String get roleSuperAdmin => 'Super Admin';

  @override
  String get roleShopOwner => 'Shop Owner';

  @override
  String get roleManager => 'Manager';

  @override
  String get roleFrontDesk => 'Front Desk';

  @override
  String get roleMechanic => 'Mechanic';

  @override
  String get cancel => 'Cancel';

  @override
  String get create => 'Create';

  @override
  String get statusActive => 'Active';

  @override
  String get statusInactive => 'Inactive';

  @override
  String get quantityLabel => 'Quantity';

  @override
  String get customerIdLabel => 'Customer ID';

  @override
  String get vehicleIdLabel => 'Vehicle ID';

  @override
  String get noWorkshopAssigned => 'No workshop is assigned to this account.';

  @override
  String get validationRequired => 'Required';

  @override
  String get validationEnterName => 'Enter a name.';

  @override
  String get vehiclesPageTitle => 'Vehicles & customers';

  @override
  String get vehiclesPageSubtitle =>
      'Search license plates locally, even when the workshop is offline.';

  @override
  String get vehiclesRegisterVehicle => 'Register vehicle';

  @override
  String get vehiclesSearchLabel => 'Search license plate';

  @override
  String get vehiclesSearchHint => 'e.g. ABC-123';

  @override
  String get vehiclesClearSearch => 'Clear search';

  @override
  String get vehiclesLoadError => 'Unable to load local vehicle records.';

  @override
  String get vehiclesSearchUnavailable => 'Local search is unavailable.';

  @override
  String get vehiclesEmpty => 'No vehicles found.';

  @override
  String get vehiclesDialogTitle => 'Register customer and vehicle';

  @override
  String get vehiclesCustomerTypeLabel => 'Customer type';

  @override
  String get vehiclesCustomerNameLabel => 'Customer name';

  @override
  String get vehiclesPhoneLabel => 'Phone';

  @override
  String get vehiclesPlateLabel => 'License plate';

  @override
  String get vehiclesMakeLabel => 'Make';

  @override
  String get vehiclesModelLabel => 'Model';

  @override
  String get vehiclesValidationCustomerName => 'Enter a customer name.';

  @override
  String get vehiclesValidationPlate => 'Enter a license plate.';

  @override
  String get vehiclesSaveError => 'Unable to save customer and vehicle.';

  @override
  String get vehiclesRegisterSubmit => 'Register';

  @override
  String get customerTypeIndividual => 'Individual';

  @override
  String get customerTypeCompany => 'Company';

  @override
  String get reportsPageSubtitle =>
      'Operational and financial summary for the last 30 days.';

  @override
  String get reportsMetricCompletedJobs => 'Completed jobs';

  @override
  String get reportsMetricInvoices => 'Invoices';

  @override
  String get reportsMetricRevenue => 'Revenue';

  @override
  String get reportsMetricPaid => 'Paid';

  @override
  String get reportsMetricOutstanding => 'Outstanding';

  @override
  String get reportsMetricLowStock => 'Low stock';

  @override
  String get warrantyCreate => 'Create warranty';

  @override
  String get warrantyLoadError => 'Unable to load warranties.';

  @override
  String get warrantyEmpty => 'No warranty records found.';

  @override
  String warrantyRecordCount(Object count) {
    return '$count warranty records';
  }

  @override
  String get warrantyDefaultTerms =>
      'Covers workmanship and replaced parts under workshop warranty terms.';

  @override
  String get warrantyCompletedJobLabel => 'Completed job card';

  @override
  String get warrantyNoFinishedJobs =>
      'Complete a job card before creating a warranty.';

  @override
  String warrantyCustomerLabel(Object customerId) {
    return 'Customer $customerId';
  }

  @override
  String warrantyVehicleLabel(Object vehicleId) {
    return 'Vehicle $vehicleId';
  }

  @override
  String get warrantyDurationLabel => 'Duration';

  @override
  String warrantyDurationMonths(Object count) {
    return '$count months';
  }

  @override
  String get warrantyTermsLabel => 'Terms';

  @override
  String warrantyTileJobTitle(Object jobId) {
    return 'Job $jobId';
  }

  @override
  String warrantyTileSubtitle(Object vehicleId, Object months, Object date) {
    return 'Vehicle $vehicleId · $months months · expires $date';
  }

  @override
  String get warrantyStatusExpired => 'Expired';

  @override
  String get warrantyStatusVoided => 'Voided';

  @override
  String get inventoryLoadError => 'Unable to load inventory.';

  @override
  String get inventoryEmpty => 'No inventory items found.';

  @override
  String get inventoryAddItem => 'Add item';

  @override
  String inventorySubtitle(Object count) {
    return '$count items · quantity changes are recorded as movements';
  }

  @override
  String get inventoryCreateTitle => 'Add inventory item';

  @override
  String get inventoryNameLabel => 'Name';

  @override
  String get inventorySkuLabel => 'SKU';

  @override
  String get inventoryMinimumStockLabel => 'Minimum stock';

  @override
  String get inventorySellingPriceLabel => 'Selling price (minor units)';

  @override
  String get inventoryCreateError => 'Unable to create inventory item.';

  @override
  String inventoryMovementTitle(Object name) {
    return 'Stock movement · $name';
  }

  @override
  String get inventoryValidationPositiveQuantity =>
      'Enter a positive quantity.';

  @override
  String get inventoryReasonLabel => 'Reason';

  @override
  String get inventoryRecord => 'Record';

  @override
  String get inventoryRecordMovementTooltip => 'Record stock movement';

  @override
  String get inventoryLowStock => 'Low stock';

  @override
  String get inventoryInStock => 'In stock';

  @override
  String get inventoryMovementTypeStockIn => 'Stock in';

  @override
  String get inventoryMovementTypeStockOut => 'Stock out';

  @override
  String get inventoryMovementTypeAdjustment => 'Adjustment';

  @override
  String get inventoryMovementTypeReturn => 'Return';

  @override
  String get billingPageTitle => 'Billing & payments';

  @override
  String get billingLoadError => 'Unable to load invoices.';

  @override
  String get billingEmpty => 'No invoices found.';

  @override
  String billingSubtitle(Object count) {
    return '$count invoices · all amounts use minor units';
  }

  @override
  String get billingNewInvoice => 'New invoice';

  @override
  String get billingCreateTitle => 'Create invoice';

  @override
  String get billingJobCardIdLabel => 'Job card';

  @override
  String get billingNoJobCards =>
      'Create a job card before issuing an invoice.';

  @override
  String get billingItemTypeLabel => 'Item type';

  @override
  String get billingDescriptionLabel => 'Description';

  @override
  String get billingUnitPriceLabel => 'Unit price (minor units)';

  @override
  String get billingTaxLabel => 'Tax (minor units)';

  @override
  String billingReceivePaymentTitle(Object invoiceNumber) {
    return 'Receive payment · $invoiceNumber';
  }

  @override
  String billingBalanceLabel(Object amount) {
    return 'Balance: $amount minor units';
  }

  @override
  String get billingAmountLabel => 'Amount (minor units)';

  @override
  String get billingMethodLabel => 'Payment method';

  @override
  String get billingReferenceLabel => 'Reference';

  @override
  String get billingReceive => 'Receive';

  @override
  String get billingReceivePaymentTooltip => 'Receive payment';

  @override
  String billingInvoiceTotals(Object count, Object total, Object balance) {
    return '$count items · Total $total · Balance $balance';
  }

  @override
  String get billingValidationPositiveInteger => 'Enter a positive integer.';

  @override
  String get billingItemTypeLabor => 'Labor';

  @override
  String get billingItemTypePart => 'Part';

  @override
  String get billingItemTypeService => 'Service';

  @override
  String get billingItemTypeDirectSale => 'Direct sale';

  @override
  String get billingPaymentMethodCash => 'Cash';

  @override
  String get billingPaymentMethodCard => 'Card';

  @override
  String get billingPaymentMethodBankTransfer => 'Bank transfer';

  @override
  String get billingPaymentMethodMobilePayment => 'Mobile payment';

  @override
  String get billingPaymentMethodOther => 'Other';

  @override
  String get billingInvoiceStatusDraft => 'Draft';

  @override
  String get billingInvoiceStatusIssued => 'Issued';

  @override
  String get billingInvoiceStatusPartiallyPaid => 'Partially paid';

  @override
  String get billingInvoiceStatusPaid => 'Paid';

  @override
  String get billingInvoiceStatusVoided => 'Voided';

  @override
  String get shopsPlatformTitle => 'Workshops';

  @override
  String get shopsPlatformSubtitle => 'Platform-level workshop onboarding';

  @override
  String get shopsLoadWorkshopsError => 'Unable to load workshops.';

  @override
  String get shopsWorkshopsEmpty => 'No workshops have been onboarded.';

  @override
  String get shopsCreateWorkshop => 'Create workshop';

  @override
  String get shopsWorkshopNameLabel => 'Workshop name';

  @override
  String get shopsWorkshopCodeLabel => 'Workshop code';

  @override
  String get shopsValidationCodeLength => 'Use at least 3 characters.';

  @override
  String get shopsLoadSettingsError => 'Unable to load workshop settings.';

  @override
  String get shopsNotFound => 'Workshop not found.';

  @override
  String get shopsAddStaff => 'Add staff';

  @override
  String get shopsLoadStaffError => 'Unable to load staff.';

  @override
  String get shopsStaffEmpty => 'No staff accounts found.';

  @override
  String get shopsCreateStaffTitle => 'Add staff account';

  @override
  String get shopsFullNameLabel => 'Full name';

  @override
  String get shopsRoleLabel => 'Role';

  @override
  String get jobCardsLoadError => 'Unable to load job cards.';

  @override
  String get jobCardsEmpty => 'No job cards found.';

  @override
  String get jobCardsFallbackRole => 'Staff';

  @override
  String jobCardsSubtitle(Object count, Object role) {
    return '$count visible job cards · $role';
  }

  @override
  String get jobCardsNew => 'New job card';

  @override
  String get jobCardsCreateTitle => 'Create job card';

  @override
  String get jobCardsComplaintLabel => 'Customer complaint';

  @override
  String get jobCardsPriorityLabel => 'Priority';

  @override
  String get jobCardsPriorityLow => 'Low';

  @override
  String get jobCardsPriorityNormal => 'Normal';

  @override
  String get jobCardsPriorityHigh => 'High';

  @override
  String get jobCardsPriorityUrgent => 'Urgent';

  @override
  String jobCardsTilePriorityVehicle(Object priority, Object vehicleId) {
    return 'Priority: $priority · Vehicle: $vehicleId';
  }

  @override
  String jobCardsAssignedMechanics(Object count) {
    return 'Assigned mechanics: $count';
  }

  @override
  String get jobCardsAssignMechanic => 'Assign mechanic';

  @override
  String get jobCardsMechanicIdLabel => 'Mechanic user ID';

  @override
  String get jobCardsAssign => 'Assign';

  @override
  String get jobCardStatusDraft => 'Draft';

  @override
  String get jobCardStatusOpen => 'Open';

  @override
  String get jobCardStatusAssigned => 'Assigned';

  @override
  String get jobCardStatusInProgress => 'In progress';

  @override
  String get jobCardStatusWaitingForParts => 'Waiting for parts';

  @override
  String get jobCardStatusWaitingForApproval => 'Waiting for approval';

  @override
  String get jobCardStatusCompleted => 'Completed';

  @override
  String get jobCardStatusReadyForPickup => 'Ready for pickup';

  @override
  String get jobCardStatusClosed => 'Closed';

  @override
  String get jobCardStatusCancelled => 'Cancelled';

  @override
  String get authInvalidCredentials => 'Email or password is incorrect.';

  @override
  String get authTooManyRequests =>
      'Too many attempts. Please wait and try again.';

  @override
  String get authUserDisabled => 'This staff account is disabled.';

  @override
  String get authConnectionRetry =>
      'Unable to sign in. Check your connection and try again.';

  @override
  String get authNoUserReturned => 'Authentication returned no user.';

  @override
  String get authAccountInactive => 'This staff account is inactive.';

  @override
  String get authNoValidRole => 'Your account has no valid role.';

  @override
  String get errShopPermission =>
      'You are not authorized to create a workshop.';

  @override
  String get errShopCodeExists => 'This workshop code is already in use.';

  @override
  String get errShopFieldsRequired => 'Workshop name and code are required.';

  @override
  String get errShopUnavailable =>
      'Workshop management is temporarily unavailable.';

  @override
  String get errWarrantyPermission =>
      'You are not authorized to create warranties.';

  @override
  String get errWarrantyUnavailable =>
      'Warranty operation is temporarily unavailable.';

  @override
  String get errJobCardPermission =>
      'You are not authorized to perform this job-card action.';

  @override
  String get errJobCardStale => 'This job card changed. Refresh and try again.';

  @override
  String get errJobCardNotFound => 'Job card was not found in this workshop.';

  @override
  String get errJobCardUnavailable =>
      'Job card operation is temporarily unavailable.';

  @override
  String get errStaffPermission =>
      'You are not authorized to manage this workshop staff.';

  @override
  String get errStaffEmailExists =>
      'A staff account with this email already exists.';

  @override
  String get errStaffInvalid => 'The staff details are invalid.';

  @override
  String get errStaffUnavailable =>
      'Staff management is temporarily unavailable.';

  @override
  String get errInventoryPermission =>
      'You are not authorized to manage inventory.';

  @override
  String get errInventoryNegativeStock =>
      'The stock movement would make inventory negative.';

  @override
  String get errInventoryUnavailable =>
      'Inventory operation is temporarily unavailable.';

  @override
  String get errReportPermission => 'You are not authorized to view reports.';

  @override
  String get errReportUnavailable =>
      'Report generation is temporarily unavailable.';

  @override
  String get errBillingPaymentExceeds =>
      'Payment exceeds the invoice balance or invoice is not payable.';

  @override
  String get errBillingPermission =>
      'You are not authorized for this billing action.';

  @override
  String get errBillingUnavailable =>
      'Billing operation is temporarily unavailable.';

  @override
  String get currentPasswordLabel => 'Current password';

  @override
  String get newPasswordLabel => 'New password';

  @override
  String get changePassword => 'Change password';

  @override
  String get updatePassword => 'Update password';

  @override
  String get passwordUpdated => 'Your password has been updated.';

  @override
  String get validationEnterPassword => 'Enter a password.';

  @override
  String get authWeakPassword => 'Password must be at least 8 characters.';

  @override
  String get authReauthRequired => 'Please sign in again and try once more.';

  @override
  String get authPasswordChangeFailed =>
      'Unable to change the password. Try again.';

  @override
  String get haveAnInvitation => 'Set up an account you were invited to';

  @override
  String get signInInstead => 'Back to sign in';

  @override
  String get activateAccountTitle => 'Set up your account';

  @override
  String get activateAccountSubtitle =>
      'Enter the email and invitation code your workshop owner gave you, then choose a password.';

  @override
  String get invitationCodeLabel => 'Invitation code';

  @override
  String get confirmPasswordLabel => 'Confirm password';

  @override
  String get validationEnterInvitationCode => 'Enter your invitation code.';

  @override
  String get validationPasswordMismatch => 'The two passwords do not match.';

  @override
  String get activateAccount => 'Create my account';

  @override
  String get accountActivated => 'Welcome! Your account is ready.';

  @override
  String get done => 'Done';

  @override
  String get invitationCreatedTitle => 'Invitation created';

  @override
  String get invitationShareBody =>
      'Share these details with your new staff member.';

  @override
  String get temporaryPasswordLabel => 'Suggested password';

  @override
  String get invitationActivationHint =>
      'They may choose their own password while activating; this is only a starting point.';

  @override
  String get pendingInvitationsTitle => 'Waiting to be activated';

  @override
  String get viewInvitationCode => 'View code';

  @override
  String get cancelInvitation => 'Cancel invitation';

  @override
  String get invitationCancelled => 'The invitation has been cancelled.';

  @override
  String get sendResetLink => 'Send reset email';

  @override
  String get sendResetLinkTitle => 'Send a password reset email?';

  @override
  String get sendResetLinkBody =>
      'They will receive an email from Firebase with a link to choose a new password.';

  @override
  String get resetEmailSent => 'A password reset email has been sent.';

  @override
  String get errInvitationNotFound =>
      'This invitation code was not recognised for that email address.';

  @override
  String get errInvitationEmailMismatch =>
      'This invitation was issued for a different email address.';

  @override
  String get errInvitationAlreadyClaimed =>
      'This invitation has already been used. Sign in instead.';

  @override
  String get errEmailAlreadyInUse =>
      'An account already exists for this email. Sign in instead.';

  @override
  String get errAccountActivationFailed =>
      'Unable to activate your account. Please try again.';

  @override
  String get errResetEmailNotFound =>
      'No staff account uses this email address yet.';

  @override
  String get errResetEmailFailed =>
      'Unable to send the reset email. Try again.';
}
