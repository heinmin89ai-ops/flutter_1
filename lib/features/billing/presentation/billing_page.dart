import 'package:flutter/material.dart';

import '../../../app/localization/enum_l10n.dart';
import '../../../app/widgets/dismiss_safe_dialog.dart';
import '../../../app/widgets/load_failure.dart';
import '../../../app/widgets/page_header.dart';
import '../../../core/errors/localized_failure.dart';
import '../../../core/firestore/retryable_query.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/domain/auth_user.dart';
import '../../job_cards/domain/job_card.dart';
import '../../job_cards/domain/job_card_repository.dart';
import '../data/firebase_billing_repository.dart';
import '../domain/billing_repository.dart';
import '../domain/invoice.dart';

class BillingPage extends StatelessWidget {
  const BillingPage({super.key, required this.user, required this.repository, required this.jobCardRepository});

  final AuthUser user;
  final BillingRepository repository;
  final JobCardRepository jobCardRepository;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shopId = user.shopId;
    if (shopId == null) return Center(child: Text(l10n.noWorkshopAssigned));
    return RetryableQuery<List<Invoice>>(
      subscribe: () => repository.watchInvoices(shopId),
      builder: (context, snapshot, retry) {
        if (!snapshot.hasData && !snapshot.hasError) return const Center(child: CircularProgressIndicator());
        final invoices = snapshot.data ?? const <Invoice>[];
        final canBill = user.role != UserRole.mechanic;
        return ListView(padding: const EdgeInsets.all(24), children: [
          PageHeader(
            title: l10n.billingPageTitle,
            subtitle: l10n.billingSubtitle(invoices.length),
            action: canBill
                ? FilledButton.icon(onPressed: () => _createInvoice(context, shopId), icon: const Icon(Icons.add), label: Text(l10n.billingNewInvoice))
                : null,
          ),
          const SizedBox(height: 24),
          if (snapshot.hasError)
            LoadFailure(message: l10n.billingLoadError, onRetry: retry)
          else if (invoices.isEmpty) Card(child: Padding(padding: const EdgeInsets.all(32), child: Center(child: Text(l10n.billingEmpty))))
          else ...invoices.map((invoice) => _InvoiceTile(invoice: invoice, canPay: canBill, onPayment: () => _receivePayment(context, shopId, invoice))),
        ]);
      },
    );
  }

  Future<void> _createInvoice(BuildContext context, String shopId) async {
    final l10n = AppLocalizations.of(context);
    List<JobCard> cards;
    try {
      cards = await jobCardRepository.watchJobCards(shopId).first;
    } catch (_) {
      if (!context.mounted) return;
      _message(context, l10n.billingLoadError);
      return;
    }
    if (!context.mounted) return;
    if (cards.isEmpty) {
      _message(context, l10n.billingNoJobCards);
      return;
    }
    // The backend only accepts an invoice tied to a job card of this workshop,
    // so the card is chosen from the shop's own list rather than typed in.
    final customer = TextEditingController();
    final vehicle = TextEditingController();
    final description = TextEditingController();
    final quantity = TextEditingController(text: '1');
    final price = TextEditingController();
    final tax = TextEditingController(text: '0');
    final formKey = GlobalKey<FormState>();
    var jobCardId = cards.first.jobCardId;
    var type = InvoiceItemType.service;
    try {
      await showDialogUntilDismissed(context, builder: (dialogContext) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
        title: Text(l10n.billingCreateTitle),
        content: Form(key: formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<String>(isExpanded: true, value: jobCardId, decoration: InputDecoration(labelText: l10n.billingJobCardIdLabel), items: cards.map((card) => DropdownMenuItem(value: card.jobCardId, child: Text(card.jobNumber))).toList(), onChanged: (value) => setDialogState(() => jobCardId = value ?? jobCardId)),
          const SizedBox(height: 12), TextFormField(controller: customer, decoration: InputDecoration(labelText: l10n.customerIdLabel), validator: (value) => _required(l10n, value)),
          const SizedBox(height: 12), TextFormField(controller: vehicle, decoration: InputDecoration(labelText: l10n.vehicleIdLabel), validator: (value) => _required(l10n, value)),
          const SizedBox(height: 12), DropdownButtonFormField<InvoiceItemType>(isExpanded: true,value: type, decoration: InputDecoration(labelText: l10n.billingItemTypeLabel), items: InvoiceItemType.values.map((value) => DropdownMenuItem(value: value, child: Text(value.localizedLabel(l10n)))).toList(), onChanged: (value) => setDialogState(() => type = value ?? type)),
          const SizedBox(height: 12), TextFormField(controller: description, decoration: InputDecoration(labelText: l10n.billingDescriptionLabel), validator: (value) => _required(l10n, value)),
          const SizedBox(height: 12), TextFormField(controller: quantity, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l10n.quantityLabel), validator: (value) => _positive(l10n, value)),
          const SizedBox(height: 12), TextFormField(controller: price, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l10n.billingUnitPriceLabel), validator: (value) => _positive(l10n, value)),
          const SizedBox(height: 12), TextFormField(controller: tax, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l10n.billingTaxLabel)),
        ]))),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.cancel)), FilledButton(onPressed: () async {
          if (!formKey.currentState!.validate()) return;
          try {
            await repository.createInvoice(shopId: shopId, jobCardId: jobCardId, customerId: customer.text.trim(), vehicleId: vehicle.text.trim(), items: [InvoiceItem(type: type, description: description.text.trim(), quantity: int.parse(quantity.text), unitPriceMinorUnits: int.parse(price.text), discountMinorUnits: 0, taxMinorUnits: int.tryParse(tax.text) ?? 0)]);
            if (dialogContext.mounted) Navigator.pop(dialogContext);
          } on BillingFailure catch (error) { if (dialogContext.mounted) _message(dialogContext, localizedFailureMessage(AppLocalizations.of(dialogContext), error)); }
        }, child: Text(l10n.create))],
      )));
    } finally { customer.dispose(); vehicle.dispose(); description.dispose(); quantity.dispose(); price.dispose(); tax.dispose(); }
  }

  Future<void> _receivePayment(BuildContext context, String shopId, Invoice invoice) async {
    final l10n = AppLocalizations.of(context);
    final amount = TextEditingController(text: invoice.balanceMinorUnits.toString());
    final reference = TextEditingController();
    var method = PaymentMethod.cash;
    final formKey = GlobalKey<FormState>();
    try {
      await showDialogUntilDismissed(context, builder: (dialogContext) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
        title: Text(l10n.billingReceivePaymentTitle(invoice.invoiceNumber)),
        content: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(l10n.billingBalanceLabel(invoice.balanceMinorUnits)),
          const SizedBox(height: 12), TextFormField(controller: amount, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l10n.billingAmountLabel), validator: (value) => _positive(l10n, value)),
          const SizedBox(height: 12), DropdownButtonFormField<PaymentMethod>(isExpanded: true,value: method, decoration: InputDecoration(labelText: l10n.billingMethodLabel), items: PaymentMethod.values.map((value) => DropdownMenuItem(value: value, child: Text(value.localizedLabel(l10n)))).toList(), onChanged: (value) => setDialogState(() => method = value ?? method)),
          const SizedBox(height: 12), TextFormField(controller: reference, decoration: InputDecoration(labelText: l10n.billingReferenceLabel)),
        ])),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.cancel)), FilledButton(onPressed: () async {
          if (!formKey.currentState!.validate()) return;
          try { await repository.receivePayment(shopId: shopId, invoiceId: invoice.invoiceId, amountMinorUnits: int.parse(amount.text), method: method, reference: reference.text.trim()); if (dialogContext.mounted) Navigator.pop(dialogContext); } on BillingFailure catch (error) { if (dialogContext.mounted) _message(dialogContext, localizedFailureMessage(AppLocalizations.of(dialogContext), error)); }
        }, child: Text(l10n.billingReceive))],
      )));
    } finally { amount.dispose(); reference.dispose(); }
  }
}

class _InvoiceTile extends StatelessWidget {
  const _InvoiceTile({required this.invoice, required this.canPay, required this.onPayment});
  final Invoice invoice;
  final bool canPay;
  final VoidCallback onPayment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
      leading: const CircleAvatar(child: Icon(Icons.receipt_long_outlined)),
      title: Text(invoice.invoiceNumber),
      subtitle: Text(l10n.billingInvoiceTotals(invoice.items.length, invoice.totalMinorUnits, invoice.balanceMinorUnits)),
      trailing: canPay && invoice.balanceMinorUnits > 0 ? IconButton(tooltip: l10n.billingReceivePaymentTooltip, onPressed: onPayment, icon: const Icon(Icons.payments_outlined)) : Chip(label: Text(invoice.status.localizedLabel(l10n))),
    ));
  }
}

String? _required(AppLocalizations l10n, String? value) => value == null || value.trim().isEmpty ? l10n.validationRequired : null;
String? _positive(AppLocalizations l10n, String? value) => int.tryParse(value ?? '') == null || int.parse(value!) <= 0 ? l10n.billingValidationPositiveInteger : null;
void _message(BuildContext context, String value) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
