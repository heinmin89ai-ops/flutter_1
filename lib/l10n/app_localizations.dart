import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_my.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('my')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Workshop Ops'**
  String get appName;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navVehicles.
  ///
  /// In en, this message translates to:
  /// **'Vehicles'**
  String get navVehicles;

  /// No description provided for @navJobCards.
  ///
  /// In en, this message translates to:
  /// **'Job cards'**
  String get navJobCards;

  /// No description provided for @navInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get navInventory;

  /// No description provided for @navBilling.
  ///
  /// In en, this message translates to:
  /// **'Billing'**
  String get navBilling;

  /// No description provided for @navWarranty.
  ///
  /// In en, this message translates to:
  /// **'Warranty'**
  String get navWarranty;

  /// No description provided for @navShopsStaff.
  ///
  /// In en, this message translates to:
  /// **'Shops & staff'**
  String get navShopsStaff;

  /// No description provided for @navReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get navReports;

  /// No description provided for @accountMenu.
  ///
  /// In en, this message translates to:
  /// **'Account menu'**
  String get accountMenu;

  /// No description provided for @unknownRole.
  ///
  /// In en, this message translates to:
  /// **'Unknown role'**
  String get unknownRole;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your staff account.'**
  String get signInSubtitle;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @validationValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email.'**
  String get validationValidEmail;

  /// No description provided for @validationPasswordLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get validationPasswordLength;

  /// No description provided for @signInFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to sign in. Please try again.'**
  String get signInFailed;

  /// No description provided for @accessNotConfiguredTitle.
  ///
  /// In en, this message translates to:
  /// **'Access not configured'**
  String get accessNotConfiguredTitle;

  /// No description provided for @accessNotConfiguredBody.
  ///
  /// In en, this message translates to:
  /// **'Your account does not have an active workshop role. Contact an administrator.'**
  String get accessNotConfiguredBody;

  /// No description provided for @workshopOverview.
  ///
  /// In en, this message translates to:
  /// **'Workshop overview'**
  String get workshopOverview;

  /// No description provided for @workshopOverviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A clear view of today\'s work, even when the network is unavailable.'**
  String get workshopOverviewSubtitle;

  /// No description provided for @metricOpenJobCards.
  ///
  /// In en, this message translates to:
  /// **'Open job cards'**
  String get metricOpenJobCards;

  /// No description provided for @metricOpenJobCardsDetail.
  ///
  /// In en, this message translates to:
  /// **'No records loaded yet'**
  String get metricOpenJobCardsDetail;

  /// No description provided for @metricVehiclesToday.
  ///
  /// In en, this message translates to:
  /// **'Vehicles today'**
  String get metricVehiclesToday;

  /// No description provided for @metricVehiclesTodayDetail.
  ///
  /// In en, this message translates to:
  /// **'Ready for local search'**
  String get metricVehiclesTodayDetail;

  /// No description provided for @metricInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get metricInProgress;

  /// No description provided for @metricInProgressDetail.
  ///
  /// In en, this message translates to:
  /// **'Assigned mechanic work'**
  String get metricInProgressDetail;

  /// No description provided for @metricPendingBalance.
  ///
  /// In en, this message translates to:
  /// **'Pending balance'**
  String get metricPendingBalance;

  /// No description provided for @metricPendingBalanceDetail.
  ///
  /// In en, this message translates to:
  /// **'Currency will come from shop settings'**
  String get metricPendingBalanceDetail;

  /// No description provided for @todaySectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todaySectionTitle;

  /// No description provided for @todayPlateSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'License plate search'**
  String get todayPlateSearchTitle;

  /// No description provided for @todayPlateSearchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Local indexed search will be available in the Customers and Vehicles phase.'**
  String get todayPlateSearchSubtitle;

  /// No description provided for @todaySyncQueueTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync queue'**
  String get todaySyncQueueTitle;

  /// No description provided for @todaySyncQueueSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every offline mutation will remain visible until cloud synchronization completes.'**
  String get todaySyncQueueSubtitle;

  /// No description provided for @syncStatusOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get syncStatusOnline;

  /// No description provided for @syncStatusOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get syncStatusOffline;

  /// No description provided for @syncStatusSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing'**
  String get syncStatusSyncing;

  /// No description provided for @syncStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending changes'**
  String get syncStatusPending;

  /// No description provided for @syncStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed'**
  String get syncStatusFailed;

  /// No description provided for @syncDescOnline.
  ///
  /// In en, this message translates to:
  /// **'All local changes are synchronized.'**
  String get syncDescOnline;

  /// No description provided for @syncDescOffline.
  ///
  /// In en, this message translates to:
  /// **'Changes will be queued on this device.'**
  String get syncDescOffline;

  /// No description provided for @syncDescSyncing.
  ///
  /// In en, this message translates to:
  /// **'Uploading local changes securely.'**
  String get syncDescSyncing;

  /// No description provided for @syncDescPending.
  ///
  /// In en, this message translates to:
  /// **'Local work is saved and waiting to sync.'**
  String get syncDescPending;

  /// No description provided for @syncDescFailed.
  ///
  /// In en, this message translates to:
  /// **'Some changes need attention before retrying.'**
  String get syncDescFailed;

  /// No description provided for @languageMenuLabel.
  ///
  /// In en, this message translates to:
  /// **'Change language'**
  String get languageMenuLabel;

  /// No description provided for @roleSuperAdmin.
  ///
  /// In en, this message translates to:
  /// **'Super Admin'**
  String get roleSuperAdmin;

  /// No description provided for @roleShopOwner.
  ///
  /// In en, this message translates to:
  /// **'Shop Owner'**
  String get roleShopOwner;

  /// No description provided for @roleManager.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get roleManager;

  /// No description provided for @roleFrontDesk.
  ///
  /// In en, this message translates to:
  /// **'Front Desk'**
  String get roleFrontDesk;

  /// No description provided for @roleMechanic.
  ///
  /// In en, this message translates to:
  /// **'Mechanic'**
  String get roleMechanic;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get statusInactive;

  /// No description provided for @quantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantityLabel;

  /// No description provided for @customerIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer ID'**
  String get customerIdLabel;

  /// No description provided for @vehicleIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Vehicle ID'**
  String get vehicleIdLabel;

  /// No description provided for @noWorkshopAssigned.
  ///
  /// In en, this message translates to:
  /// **'No workshop is assigned to this account.'**
  String get noWorkshopAssigned;

  /// No description provided for @validationRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get validationRequired;

  /// No description provided for @validationEnterName.
  ///
  /// In en, this message translates to:
  /// **'Enter a name.'**
  String get validationEnterName;

  /// No description provided for @vehiclesPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Vehicles & customers'**
  String get vehiclesPageTitle;

  /// No description provided for @vehiclesPageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Search license plates locally, even when the workshop is offline.'**
  String get vehiclesPageSubtitle;

  /// No description provided for @vehiclesRegisterVehicle.
  ///
  /// In en, this message translates to:
  /// **'Register vehicle'**
  String get vehiclesRegisterVehicle;

  /// No description provided for @vehiclesSearchLabel.
  ///
  /// In en, this message translates to:
  /// **'Search license plate'**
  String get vehiclesSearchLabel;

  /// No description provided for @vehiclesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. ABC-123'**
  String get vehiclesSearchHint;

  /// No description provided for @vehiclesClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get vehiclesClearSearch;

  /// No description provided for @vehiclesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load local vehicle records.'**
  String get vehiclesLoadError;

  /// No description provided for @vehiclesSearchUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Local search is unavailable.'**
  String get vehiclesSearchUnavailable;

  /// No description provided for @vehiclesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No vehicles found.'**
  String get vehiclesEmpty;

  /// No description provided for @vehiclesDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Register customer and vehicle'**
  String get vehiclesDialogTitle;

  /// No description provided for @vehiclesCustomerTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer type'**
  String get vehiclesCustomerTypeLabel;

  /// No description provided for @vehiclesCustomerNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer name'**
  String get vehiclesCustomerNameLabel;

  /// No description provided for @vehiclesPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get vehiclesPhoneLabel;

  /// No description provided for @vehiclesPlateLabel.
  ///
  /// In en, this message translates to:
  /// **'License plate'**
  String get vehiclesPlateLabel;

  /// No description provided for @vehiclesMakeLabel.
  ///
  /// In en, this message translates to:
  /// **'Make'**
  String get vehiclesMakeLabel;

  /// No description provided for @vehiclesModelLabel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get vehiclesModelLabel;

  /// No description provided for @vehiclesValidationCustomerName.
  ///
  /// In en, this message translates to:
  /// **'Enter a customer name.'**
  String get vehiclesValidationCustomerName;

  /// No description provided for @vehiclesValidationPlate.
  ///
  /// In en, this message translates to:
  /// **'Enter a license plate.'**
  String get vehiclesValidationPlate;

  /// No description provided for @vehiclesSaveError.
  ///
  /// In en, this message translates to:
  /// **'Unable to save customer and vehicle.'**
  String get vehiclesSaveError;

  /// No description provided for @vehiclesRegisterSubmit.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get vehiclesRegisterSubmit;

  /// No description provided for @customerTypeIndividual.
  ///
  /// In en, this message translates to:
  /// **'Individual'**
  String get customerTypeIndividual;

  /// No description provided for @customerTypeCompany.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get customerTypeCompany;

  /// No description provided for @reportsPageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Operational and financial summary for the last 30 days.'**
  String get reportsPageSubtitle;

  /// No description provided for @reportsMetricCompletedJobs.
  ///
  /// In en, this message translates to:
  /// **'Completed jobs'**
  String get reportsMetricCompletedJobs;

  /// No description provided for @reportsMetricInvoices.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get reportsMetricInvoices;

  /// No description provided for @reportsMetricRevenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get reportsMetricRevenue;

  /// No description provided for @reportsMetricPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get reportsMetricPaid;

  /// No description provided for @reportsMetricOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get reportsMetricOutstanding;

  /// No description provided for @reportsMetricLowStock.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get reportsMetricLowStock;

  /// No description provided for @warrantyCreate.
  ///
  /// In en, this message translates to:
  /// **'Create warranty'**
  String get warrantyCreate;

  /// No description provided for @warrantyLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load warranties.'**
  String get warrantyLoadError;

  /// No description provided for @warrantyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No warranty records found.'**
  String get warrantyEmpty;

  /// No description provided for @warrantyRecordCount.
  ///
  /// In en, this message translates to:
  /// **'{count} warranty records'**
  String warrantyRecordCount(Object count);

  /// No description provided for @warrantyDefaultTerms.
  ///
  /// In en, this message translates to:
  /// **'Covers workmanship and replaced parts under workshop warranty terms.'**
  String get warrantyDefaultTerms;

  /// No description provided for @warrantyCompletedJobIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Completed job card ID'**
  String get warrantyCompletedJobIdLabel;

  /// No description provided for @warrantyDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get warrantyDurationLabel;

  /// No description provided for @warrantyDurationMonths.
  ///
  /// In en, this message translates to:
  /// **'{count} months'**
  String warrantyDurationMonths(Object count);

  /// No description provided for @warrantyTermsLabel.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get warrantyTermsLabel;

  /// No description provided for @warrantyTileJobTitle.
  ///
  /// In en, this message translates to:
  /// **'Job {jobId}'**
  String warrantyTileJobTitle(Object jobId);

  /// No description provided for @warrantyTileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle {vehicleId} · {months} months · expires {date}'**
  String warrantyTileSubtitle(Object vehicleId, Object months, Object date);

  /// No description provided for @warrantyStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get warrantyStatusExpired;

  /// No description provided for @warrantyStatusVoided.
  ///
  /// In en, this message translates to:
  /// **'Voided'**
  String get warrantyStatusVoided;

  /// No description provided for @inventoryLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load inventory.'**
  String get inventoryLoadError;

  /// No description provided for @inventoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No inventory items found.'**
  String get inventoryEmpty;

  /// No description provided for @inventoryAddItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get inventoryAddItem;

  /// No description provided for @inventorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} items · quantity changes are recorded as movements'**
  String inventorySubtitle(Object count);

  /// No description provided for @inventoryCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Add inventory item'**
  String get inventoryCreateTitle;

  /// No description provided for @inventoryNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get inventoryNameLabel;

  /// No description provided for @inventorySkuLabel.
  ///
  /// In en, this message translates to:
  /// **'SKU'**
  String get inventorySkuLabel;

  /// No description provided for @inventoryMinimumStockLabel.
  ///
  /// In en, this message translates to:
  /// **'Minimum stock'**
  String get inventoryMinimumStockLabel;

  /// No description provided for @inventorySellingPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Selling price (minor units)'**
  String get inventorySellingPriceLabel;

  /// No description provided for @inventoryCreateError.
  ///
  /// In en, this message translates to:
  /// **'Unable to create inventory item.'**
  String get inventoryCreateError;

  /// No description provided for @inventoryMovementTitle.
  ///
  /// In en, this message translates to:
  /// **'Stock movement · {name}'**
  String inventoryMovementTitle(Object name);

  /// No description provided for @inventoryValidationPositiveQuantity.
  ///
  /// In en, this message translates to:
  /// **'Enter a positive quantity.'**
  String get inventoryValidationPositiveQuantity;

  /// No description provided for @inventoryReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get inventoryReasonLabel;

  /// No description provided for @inventoryRecord.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get inventoryRecord;

  /// No description provided for @inventoryRecordMovementTooltip.
  ///
  /// In en, this message translates to:
  /// **'Record stock movement'**
  String get inventoryRecordMovementTooltip;

  /// No description provided for @inventoryLowStock.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get inventoryLowStock;

  /// No description provided for @inventoryInStock.
  ///
  /// In en, this message translates to:
  /// **'In stock'**
  String get inventoryInStock;

  /// No description provided for @inventoryMovementTypeStockIn.
  ///
  /// In en, this message translates to:
  /// **'Stock in'**
  String get inventoryMovementTypeStockIn;

  /// No description provided for @inventoryMovementTypeStockOut.
  ///
  /// In en, this message translates to:
  /// **'Stock out'**
  String get inventoryMovementTypeStockOut;

  /// No description provided for @inventoryMovementTypeAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Adjustment'**
  String get inventoryMovementTypeAdjustment;

  /// No description provided for @inventoryMovementTypeReturn.
  ///
  /// In en, this message translates to:
  /// **'Return'**
  String get inventoryMovementTypeReturn;

  /// No description provided for @billingPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Billing & payments'**
  String get billingPageTitle;

  /// No description provided for @billingLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load invoices.'**
  String get billingLoadError;

  /// No description provided for @billingEmpty.
  ///
  /// In en, this message translates to:
  /// **'No invoices found.'**
  String get billingEmpty;

  /// No description provided for @billingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} invoices · all amounts use minor units'**
  String billingSubtitle(Object count);

  /// No description provided for @billingNewInvoice.
  ///
  /// In en, this message translates to:
  /// **'New invoice'**
  String get billingNewInvoice;

  /// No description provided for @billingCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create invoice'**
  String get billingCreateTitle;

  /// No description provided for @billingJobCardIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Job card ID'**
  String get billingJobCardIdLabel;

  /// No description provided for @billingItemTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Item type'**
  String get billingItemTypeLabel;

  /// No description provided for @billingDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get billingDescriptionLabel;

  /// No description provided for @billingUnitPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit price (minor units)'**
  String get billingUnitPriceLabel;

  /// No description provided for @billingTaxLabel.
  ///
  /// In en, this message translates to:
  /// **'Tax (minor units)'**
  String get billingTaxLabel;

  /// No description provided for @billingReceivePaymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Receive payment · {invoiceNumber}'**
  String billingReceivePaymentTitle(Object invoiceNumber);

  /// No description provided for @billingBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Balance: {amount} minor units'**
  String billingBalanceLabel(Object amount);

  /// No description provided for @billingAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount (minor units)'**
  String get billingAmountLabel;

  /// No description provided for @billingMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get billingMethodLabel;

  /// No description provided for @billingReferenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get billingReferenceLabel;

  /// No description provided for @billingReceive.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get billingReceive;

  /// No description provided for @billingReceivePaymentTooltip.
  ///
  /// In en, this message translates to:
  /// **'Receive payment'**
  String get billingReceivePaymentTooltip;

  /// No description provided for @billingInvoiceTotals.
  ///
  /// In en, this message translates to:
  /// **'{count} items · Total {total} · Balance {balance}'**
  String billingInvoiceTotals(Object count, Object total, Object balance);

  /// No description provided for @billingValidationPositiveInteger.
  ///
  /// In en, this message translates to:
  /// **'Enter a positive integer.'**
  String get billingValidationPositiveInteger;

  /// No description provided for @billingItemTypeLabor.
  ///
  /// In en, this message translates to:
  /// **'Labor'**
  String get billingItemTypeLabor;

  /// No description provided for @billingItemTypePart.
  ///
  /// In en, this message translates to:
  /// **'Part'**
  String get billingItemTypePart;

  /// No description provided for @billingItemTypeService.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get billingItemTypeService;

  /// No description provided for @billingItemTypeDirectSale.
  ///
  /// In en, this message translates to:
  /// **'Direct sale'**
  String get billingItemTypeDirectSale;

  /// No description provided for @billingPaymentMethodCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get billingPaymentMethodCash;

  /// No description provided for @billingPaymentMethodCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get billingPaymentMethodCard;

  /// No description provided for @billingPaymentMethodBankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank transfer'**
  String get billingPaymentMethodBankTransfer;

  /// No description provided for @billingPaymentMethodMobilePayment.
  ///
  /// In en, this message translates to:
  /// **'Mobile payment'**
  String get billingPaymentMethodMobilePayment;

  /// No description provided for @billingPaymentMethodOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get billingPaymentMethodOther;

  /// No description provided for @billingInvoiceStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get billingInvoiceStatusDraft;

  /// No description provided for @billingInvoiceStatusIssued.
  ///
  /// In en, this message translates to:
  /// **'Issued'**
  String get billingInvoiceStatusIssued;

  /// No description provided for @billingInvoiceStatusPartiallyPaid.
  ///
  /// In en, this message translates to:
  /// **'Partially paid'**
  String get billingInvoiceStatusPartiallyPaid;

  /// No description provided for @billingInvoiceStatusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get billingInvoiceStatusPaid;

  /// No description provided for @billingInvoiceStatusVoided.
  ///
  /// In en, this message translates to:
  /// **'Voided'**
  String get billingInvoiceStatusVoided;

  /// No description provided for @shopsPlatformTitle.
  ///
  /// In en, this message translates to:
  /// **'Workshops'**
  String get shopsPlatformTitle;

  /// No description provided for @shopsPlatformSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Platform-level workshop onboarding'**
  String get shopsPlatformSubtitle;

  /// No description provided for @shopsLoadWorkshopsError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load workshops.'**
  String get shopsLoadWorkshopsError;

  /// No description provided for @shopsWorkshopsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No workshops have been onboarded.'**
  String get shopsWorkshopsEmpty;

  /// No description provided for @shopsCreateWorkshop.
  ///
  /// In en, this message translates to:
  /// **'Create workshop'**
  String get shopsCreateWorkshop;

  /// No description provided for @shopsWorkshopNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Workshop name'**
  String get shopsWorkshopNameLabel;

  /// No description provided for @shopsWorkshopCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Workshop code'**
  String get shopsWorkshopCodeLabel;

  /// No description provided for @shopsValidationCodeLength.
  ///
  /// In en, this message translates to:
  /// **'Use at least 3 characters.'**
  String get shopsValidationCodeLength;

  /// No description provided for @shopsLoadSettingsError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load workshop settings.'**
  String get shopsLoadSettingsError;

  /// No description provided for @shopsNotFound.
  ///
  /// In en, this message translates to:
  /// **'Workshop not found.'**
  String get shopsNotFound;

  /// No description provided for @shopsAddStaff.
  ///
  /// In en, this message translates to:
  /// **'Add staff'**
  String get shopsAddStaff;

  /// No description provided for @shopsLoadStaffError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load staff.'**
  String get shopsLoadStaffError;

  /// No description provided for @shopsStaffEmpty.
  ///
  /// In en, this message translates to:
  /// **'No staff accounts found.'**
  String get shopsStaffEmpty;

  /// No description provided for @shopsCreateStaffTitle.
  ///
  /// In en, this message translates to:
  /// **'Add staff account'**
  String get shopsCreateStaffTitle;

  /// No description provided for @shopsFullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get shopsFullNameLabel;

  /// No description provided for @shopsRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get shopsRoleLabel;

  /// No description provided for @jobCardsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load job cards.'**
  String get jobCardsLoadError;

  /// No description provided for @jobCardsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No job cards found.'**
  String get jobCardsEmpty;

  /// No description provided for @jobCardsFallbackRole.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get jobCardsFallbackRole;

  /// No description provided for @jobCardsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} visible job cards · {role}'**
  String jobCardsSubtitle(Object count, Object role);

  /// No description provided for @jobCardsNew.
  ///
  /// In en, this message translates to:
  /// **'New job card'**
  String get jobCardsNew;

  /// No description provided for @jobCardsCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create job card'**
  String get jobCardsCreateTitle;

  /// No description provided for @jobCardsComplaintLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer complaint'**
  String get jobCardsComplaintLabel;

  /// No description provided for @jobCardsPriorityLabel.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get jobCardsPriorityLabel;

  /// No description provided for @jobCardsPriorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get jobCardsPriorityLow;

  /// No description provided for @jobCardsPriorityNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get jobCardsPriorityNormal;

  /// No description provided for @jobCardsPriorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get jobCardsPriorityHigh;

  /// No description provided for @jobCardsPriorityUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get jobCardsPriorityUrgent;

  /// No description provided for @jobCardsTilePriorityVehicle.
  ///
  /// In en, this message translates to:
  /// **'Priority: {priority} · Vehicle: {vehicleId}'**
  String jobCardsTilePriorityVehicle(Object priority, Object vehicleId);

  /// No description provided for @jobCardsAssignedMechanics.
  ///
  /// In en, this message translates to:
  /// **'Assigned mechanics: {count}'**
  String jobCardsAssignedMechanics(Object count);

  /// No description provided for @jobCardsAssignMechanic.
  ///
  /// In en, this message translates to:
  /// **'Assign mechanic'**
  String get jobCardsAssignMechanic;

  /// No description provided for @jobCardsMechanicIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Mechanic user ID'**
  String get jobCardsMechanicIdLabel;

  /// No description provided for @jobCardsAssign.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get jobCardsAssign;

  /// No description provided for @jobCardStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get jobCardStatusDraft;

  /// No description provided for @jobCardStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get jobCardStatusOpen;

  /// No description provided for @jobCardStatusAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get jobCardStatusAssigned;

  /// No description provided for @jobCardStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get jobCardStatusInProgress;

  /// No description provided for @jobCardStatusWaitingForParts.
  ///
  /// In en, this message translates to:
  /// **'Waiting for parts'**
  String get jobCardStatusWaitingForParts;

  /// No description provided for @jobCardStatusWaitingForApproval.
  ///
  /// In en, this message translates to:
  /// **'Waiting for approval'**
  String get jobCardStatusWaitingForApproval;

  /// No description provided for @jobCardStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get jobCardStatusCompleted;

  /// No description provided for @jobCardStatusReadyForPickup.
  ///
  /// In en, this message translates to:
  /// **'Ready for pickup'**
  String get jobCardStatusReadyForPickup;

  /// No description provided for @jobCardStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get jobCardStatusClosed;

  /// No description provided for @jobCardStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get jobCardStatusCancelled;

  /// No description provided for @authInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Email or password is incorrect.'**
  String get authInvalidCredentials;

  /// No description provided for @authTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait and try again.'**
  String get authTooManyRequests;

  /// No description provided for @authUserDisabled.
  ///
  /// In en, this message translates to:
  /// **'This staff account is disabled.'**
  String get authUserDisabled;

  /// No description provided for @authConnectionRetry.
  ///
  /// In en, this message translates to:
  /// **'Unable to sign in. Check your connection and try again.'**
  String get authConnectionRetry;

  /// No description provided for @authNoUserReturned.
  ///
  /// In en, this message translates to:
  /// **'Authentication returned no user.'**
  String get authNoUserReturned;

  /// No description provided for @authAccountInactive.
  ///
  /// In en, this message translates to:
  /// **'This staff account is inactive.'**
  String get authAccountInactive;

  /// No description provided for @authNoValidRole.
  ///
  /// In en, this message translates to:
  /// **'Your account has no valid role.'**
  String get authNoValidRole;

  /// No description provided for @errShopPermission.
  ///
  /// In en, this message translates to:
  /// **'You are not authorized to create a workshop.'**
  String get errShopPermission;

  /// No description provided for @errShopCodeExists.
  ///
  /// In en, this message translates to:
  /// **'This workshop code is already in use.'**
  String get errShopCodeExists;

  /// No description provided for @errShopFieldsRequired.
  ///
  /// In en, this message translates to:
  /// **'Workshop name and code are required.'**
  String get errShopFieldsRequired;

  /// No description provided for @errShopUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Workshop management is temporarily unavailable.'**
  String get errShopUnavailable;

  /// No description provided for @errWarrantyPermission.
  ///
  /// In en, this message translates to:
  /// **'You are not authorized to create warranties.'**
  String get errWarrantyPermission;

  /// No description provided for @errWarrantyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Warranty operation is temporarily unavailable.'**
  String get errWarrantyUnavailable;

  /// No description provided for @errJobCardPermission.
  ///
  /// In en, this message translates to:
  /// **'You are not authorized to perform this job-card action.'**
  String get errJobCardPermission;

  /// No description provided for @errJobCardStale.
  ///
  /// In en, this message translates to:
  /// **'This job card changed. Refresh and try again.'**
  String get errJobCardStale;

  /// No description provided for @errJobCardNotFound.
  ///
  /// In en, this message translates to:
  /// **'Job card was not found in this workshop.'**
  String get errJobCardNotFound;

  /// No description provided for @errJobCardUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Job card operation is temporarily unavailable.'**
  String get errJobCardUnavailable;

  /// No description provided for @errStaffPermission.
  ///
  /// In en, this message translates to:
  /// **'You are not authorized to manage this workshop staff.'**
  String get errStaffPermission;

  /// No description provided for @errStaffEmailExists.
  ///
  /// In en, this message translates to:
  /// **'A staff account with this email already exists.'**
  String get errStaffEmailExists;

  /// No description provided for @errStaffInvalid.
  ///
  /// In en, this message translates to:
  /// **'The staff details are invalid.'**
  String get errStaffInvalid;

  /// No description provided for @errStaffUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Staff management is temporarily unavailable.'**
  String get errStaffUnavailable;

  /// No description provided for @errInventoryPermission.
  ///
  /// In en, this message translates to:
  /// **'You are not authorized to manage inventory.'**
  String get errInventoryPermission;

  /// No description provided for @errInventoryNegativeStock.
  ///
  /// In en, this message translates to:
  /// **'The stock movement would make inventory negative.'**
  String get errInventoryNegativeStock;

  /// No description provided for @errInventoryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Inventory operation is temporarily unavailable.'**
  String get errInventoryUnavailable;

  /// No description provided for @errReportPermission.
  ///
  /// In en, this message translates to:
  /// **'You are not authorized to view reports.'**
  String get errReportPermission;

  /// No description provided for @errReportUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Report generation is temporarily unavailable.'**
  String get errReportUnavailable;

  /// No description provided for @errBillingPaymentExceeds.
  ///
  /// In en, this message translates to:
  /// **'Payment exceeds the invoice balance or invoice is not payable.'**
  String get errBillingPaymentExceeds;

  /// No description provided for @errBillingPermission.
  ///
  /// In en, this message translates to:
  /// **'You are not authorized for this billing action.'**
  String get errBillingPermission;

  /// No description provided for @errBillingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Billing operation is temporarily unavailable.'**
  String get errBillingUnavailable;

  /// No description provided for @currentPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPasswordLabel;

  /// No description provided for @newPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPasswordLabel;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @updatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get updatePassword;

  /// No description provided for @passwordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Your password has been updated.'**
  String get passwordUpdated;

  /// No description provided for @validationEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter a password.'**
  String get validationEnterPassword;

  /// No description provided for @authWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters.'**
  String get authWeakPassword;

  /// No description provided for @authReauthRequired.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again and try once more.'**
  String get authReauthRequired;

  /// No description provided for @authPasswordChangeFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to change the password. Try again.'**
  String get authPasswordChangeFailed;

  /// No description provided for @haveAnInvitation.
  ///
  /// In en, this message translates to:
  /// **'Set up an account you were invited to'**
  String get haveAnInvitation;

  /// No description provided for @signInInstead.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get signInInstead;

  /// No description provided for @activateAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up your account'**
  String get activateAccountTitle;

  /// No description provided for @activateAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the email and invitation code your workshop owner gave you, then choose a password.'**
  String get activateAccountSubtitle;

  /// No description provided for @invitationCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Invitation code'**
  String get invitationCodeLabel;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPasswordLabel;

  /// No description provided for @validationEnterInvitationCode.
  ///
  /// In en, this message translates to:
  /// **'Enter your invitation code.'**
  String get validationEnterInvitationCode;

  /// No description provided for @validationPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'The two passwords do not match.'**
  String get validationPasswordMismatch;

  /// No description provided for @activateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create my account'**
  String get activateAccount;

  /// No description provided for @accountActivated.
  ///
  /// In en, this message translates to:
  /// **'Welcome! Your account is ready.'**
  String get accountActivated;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @invitationCreatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Invitation created'**
  String get invitationCreatedTitle;

  /// No description provided for @invitationShareBody.
  ///
  /// In en, this message translates to:
  /// **'Share these details with your new staff member.'**
  String get invitationShareBody;

  /// No description provided for @temporaryPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Suggested password'**
  String get temporaryPasswordLabel;

  /// No description provided for @invitationActivationHint.
  ///
  /// In en, this message translates to:
  /// **'They may choose their own password while activating; this is only a starting point.'**
  String get invitationActivationHint;

  /// No description provided for @pendingInvitationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting to be activated'**
  String get pendingInvitationsTitle;

  /// No description provided for @viewInvitationCode.
  ///
  /// In en, this message translates to:
  /// **'View code'**
  String get viewInvitationCode;

  /// No description provided for @cancelInvitation.
  ///
  /// In en, this message translates to:
  /// **'Cancel invitation'**
  String get cancelInvitation;

  /// No description provided for @invitationCancelled.
  ///
  /// In en, this message translates to:
  /// **'The invitation has been cancelled.'**
  String get invitationCancelled;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send reset email'**
  String get sendResetLink;

  /// No description provided for @sendResetLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Send a password reset email?'**
  String get sendResetLinkTitle;

  /// No description provided for @sendResetLinkBody.
  ///
  /// In en, this message translates to:
  /// **'They will receive an email from Firebase with a link to choose a new password.'**
  String get sendResetLinkBody;

  /// No description provided for @resetEmailSent.
  ///
  /// In en, this message translates to:
  /// **'A password reset email has been sent.'**
  String get resetEmailSent;

  /// No description provided for @errInvitationNotFound.
  ///
  /// In en, this message translates to:
  /// **'This invitation code was not recognised for that email address.'**
  String get errInvitationNotFound;

  /// No description provided for @errInvitationEmailMismatch.
  ///
  /// In en, this message translates to:
  /// **'This invitation was issued for a different email address.'**
  String get errInvitationEmailMismatch;

  /// No description provided for @errInvitationAlreadyClaimed.
  ///
  /// In en, this message translates to:
  /// **'This invitation has already been used. Sign in instead.'**
  String get errInvitationAlreadyClaimed;

  /// No description provided for @errEmailAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'An account already exists for this email. Sign in instead.'**
  String get errEmailAlreadyInUse;

  /// No description provided for @errAccountActivationFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to activate your account. Please try again.'**
  String get errAccountActivationFailed;

  /// No description provided for @errResetEmailNotFound.
  ///
  /// In en, this message translates to:
  /// **'No staff account uses this email address yet.'**
  String get errResetEmailNotFound;

  /// No description provided for @errResetEmailFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to send the reset email. Try again.'**
  String get errResetEmailFailed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'my'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'my':
      return AppLocalizationsMy();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
