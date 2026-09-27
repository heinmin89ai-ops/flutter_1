import '../../l10n/app_localizations.dart';

/// Repository failures are raised outside the widget tree, so they carry a
/// stable key instead of prose. Presentational code maps the key through
/// [localizedFailureMessage]; unknown keys fall back to the raw message.
abstract class LocalizedFailure implements Exception {
  const LocalizedFailure(this.message, {this.messageKey = 'errUnknown'});

  final String message;
  final String messageKey;

  @override
  String toString() => message;
}

String localizedFailureMessage(AppLocalizations l10n, LocalizedFailure failure) =>
    switch (failure.messageKey) {
      'errShopPermission' => l10n.errShopPermission,
      'errShopCodeExists' => l10n.errShopCodeExists,
      'errShopFieldsRequired' => l10n.errShopFieldsRequired,
      'errShopUnavailable' => l10n.errShopUnavailable,
      'errWarrantyPermission' => l10n.errWarrantyPermission,
      'errWarrantyUnavailable' => l10n.errWarrantyUnavailable,
      'errJobCardPermission' => l10n.errJobCardPermission,
      'errJobCardStale' => l10n.errJobCardStale,
      'errJobCardNotFound' => l10n.errJobCardNotFound,
      'errJobCardUnavailable' => l10n.errJobCardUnavailable,
      'errStaffPermission' => l10n.errStaffPermission,
      'errStaffEmailExists' => l10n.errStaffEmailExists,
      'errStaffInvalid' => l10n.errStaffInvalid,
      'errStaffUnavailable' => l10n.errStaffUnavailable,
      'errInventoryPermission' => l10n.errInventoryPermission,
      'errInventoryNegativeStock' => l10n.errInventoryNegativeStock,
      'errInventoryUnavailable' => l10n.errInventoryUnavailable,
      'errReportPermission' => l10n.errReportPermission,
      'errReportUnavailable' => l10n.errReportUnavailable,
      'errBillingPaymentExceeds' => l10n.errBillingPaymentExceeds,
      'errBillingPermission' => l10n.errBillingPermission,
      'errBillingUnavailable' => l10n.errBillingUnavailable,
      _ => failure.message,
    };
