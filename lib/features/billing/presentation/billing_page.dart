import 'package:flutter/material.dart';

import '../../auth/domain/auth_user.dart';
import '../data/firebase_billing_repository.dart';
import '../domain/billing_repository.dart';
import '../domain/invoice.dart';

class BillingPage extends StatelessWidget {
  const BillingPage({super.key, required this.user, required this.repository});

  final AuthUser user;
  final BillingRepository repository;

  @override
  Widget build(BuildContext context) {
    final shopId = user.shopId;
    if (shopId == null) return const Center(child: Text('No workshop is assigned to this account.'));
    return StreamBuilder<List<Invoice>>(
      stream: repository.watchInvoices(shopId),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('Unable to load invoices.'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final invoices = snapshot.data!;
        final canBill = user.role != UserRole.mechanic;
        return ListView(padding: const EdgeInsets.all(24), children: [
          Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Billing & payments', style: Theme.of(context).textTheme.headlineMedium), const SizedBox(height: 4), Text('${invoices.length} invoices · all amounts use minor units')])), if (canBill) FilledButton.icon(onPressed: () => _createInvoice(context, shopId), icon: const Icon(Icons.add), label: const Text('New invoice'))]),
          const SizedBox(height: 24),
          if (invoices.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No invoices found.'))))
          else ...invoices.map((invoice) => _InvoiceTile(invoice: invoice, canPay: canBill, onPayment: () => _receivePayment(context, shopId, invoice))),
        ]);
      },
    );
  }

  Future<void> _createInvoice(BuildContext context, String shopId) async {
    final job = TextEditingController();
    final customer = TextEditingController();
    final vehicle = TextEditingController();
    final description = TextEditingController();
    final quantity = TextEditingController(text: '1');
    final price = TextEditingController();
    final tax = TextEditingController(text: '0');
    final formKey = GlobalKey<FormState>();
    var type = InvoiceItemType.service;
    try {
      await showDialog<void>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
        title: const Text('Create invoice'),
        content: Form(key: formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(controller: job, decoration: const InputDecoration(labelText: 'Job card ID'), validator: _required),
          const SizedBox(height: 12), TextFormField(controller: customer, decoration: const InputDecoration(labelText: 'Customer ID'), validator: _required),
          const SizedBox(height: 12), TextFormField(controller: vehicle, decoration: const InputDecoration(labelText: 'Vehicle ID'), validator: _required),
          const SizedBox(height: 12), DropdownButtonFormField<InvoiceItemType>(value: type, decoration: const InputDecoration(labelText: 'Item type'), items: InvoiceItemType.values.map((value) => DropdownMenuItem(value: value, child: Text(value.name))).toList(), onChanged: (value) => setDialogState(() => type = value ?? type)),
          const SizedBox(height: 12), TextFormField(controller: description, decoration: const InputDecoration(labelText: 'Description'), validator: _required),
          const SizedBox(height: 12), TextFormField(controller: quantity, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity'), validator: _positive),
          const SizedBox(height: 12), TextFormField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Unit price (minor units)'), validator: _positive),
          const SizedBox(height: 12), TextFormField(controller: tax, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Tax (minor units)')),
        ]))),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')), FilledButton(onPressed: () async {
          if (!formKey.currentState!.validate()) return;
          try {
            await repository.createInvoice(shopId: shopId, jobCardId: job.text.trim(), customerId: customer.text.trim(), vehicleId: vehicle.text.trim(), items: [InvoiceItem(type: type, description: description.text.trim(), quantity: int.parse(quantity.text), unitPriceMinorUnits: int.parse(price.text), discountMinorUnits: 0, taxMinorUnits: int.tryParse(tax.text) ?? 0)]);
            if (dialogContext.mounted) Navigator.pop(dialogContext);
          } on BillingFailure catch (error) { if (dialogContext.mounted) _message(dialogContext, error.message); }
        }, child: const Text('Create'))],
      )));
    } finally { job.dispose(); customer.dispose(); vehicle.dispose(); description.dispose(); quantity.dispose(); price.dispose(); tax.dispose(); }
  }

  Future<void> _receivePayment(BuildContext context, String shopId, Invoice invoice) async {
    final amount = TextEditingController(text: invoice.balanceMinorUnits.toString());
    final reference = TextEditingController();
    var method = PaymentMethod.cash;
    final formKey = GlobalKey<FormState>();
    try {
      await showDialog<void>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
        title: Text('Receive payment · ${invoice.invoiceNumber}'),
        content: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Balance: ${invoice.balanceMinorUnits} minor units'),
          const SizedBox(height: 12), TextFormField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (minor units)'), validator: _positive),
          const SizedBox(height: 12), DropdownButtonFormField<PaymentMethod>(value: method, decoration: const InputDecoration(labelText: 'Method'), items: PaymentMethod.values.map((value) => DropdownMenuItem(value: value, child: Text(value.name))).toList(), onChanged: (value) => setDialogState(() => method = value ?? method)),
          const SizedBox(height: 12), TextFormField(controller: reference, decoration: const InputDecoration(labelText: 'Reference')),
        ])),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')), FilledButton(onPressed: () async {
          if (!formKey.currentState!.validate()) return;
          try { await repository.receivePayment(shopId: shopId, invoiceId: invoice.invoiceId, amountMinorUnits: int.parse(amount.text), method: method, reference: reference.text.trim()); if (dialogContext.mounted) Navigator.pop(dialogContext); } on BillingFailure catch (error) { if (dialogContext.mounted) _message(dialogContext, error.message); }
        }, child: const Text('Receive'))],
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
  Widget build(BuildContext context) => Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
    leading: const CircleAvatar(child: Icon(Icons.receipt_long_outlined)),
    title: Text(invoice.invoiceNumber),
    subtitle: Text('${invoice.items.length} items · Total ${invoice.totalMinorUnits} · Balance ${invoice.balanceMinorUnits}'),
    trailing: canPay && invoice.balanceMinorUnits > 0 ? IconButton(tooltip: 'Receive payment', onPressed: onPayment, icon: const Icon(Icons.payments_outlined)) : Chip(label: Text(invoice.status.name)),
  ));
}

String? _required(String? value) => value == null || value.trim().isEmpty ? 'Required' : null;
String? _positive(String? value) => int.tryParse(value ?? '') == null || int.parse(value!) <= 0 ? 'Enter a positive integer.' : null;
void _message(BuildContext context, String value) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
