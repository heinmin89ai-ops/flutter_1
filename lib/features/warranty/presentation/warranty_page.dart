import 'package:flutter/material.dart';

import '../../auth/domain/auth_user.dart';
import '../data/firebase_warranty_repository.dart';
import '../domain/warranty.dart';
import '../domain/warranty_repository.dart';

class WarrantyPage extends StatelessWidget {
  const WarrantyPage({super.key, required this.user, required this.repository});

  final AuthUser user;
  final WarrantyRepository repository;

  @override
  Widget build(BuildContext context) {
    final shopId = user.shopId;
    if (shopId == null) return const Center(child: Text('No workshop is assigned to this account.'));
    return StreamBuilder<List<Warranty>>(
      stream: repository.watchWarranties(shopId),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('Unable to load warranties.'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final warranties = snapshot.data!;
        final canCreate = user.role == UserRole.shopOwner || user.role == UserRole.manager;
        return ListView(padding: const EdgeInsets.all(24), children: [
          Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Warranty', style: Theme.of(context).textTheme.headlineMedium), const SizedBox(height: 4), Text('${warranties.length} warranty records')])), if (canCreate) FilledButton.icon(onPressed: () => _createWarranty(context, shopId), icon: const Icon(Icons.add), label: const Text('Create warranty'))]),
          const SizedBox(height: 24),
          if (warranties.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No warranty records found.'))))
          else ...warranties.map((warranty) => _WarrantyTile(warranty: warranty)),
        ]);
      },
    );
  }

  Future<void> _createWarranty(BuildContext context, String shopId) async {
    final job = TextEditingController();
    final vehicle = TextEditingController();
    final customer = TextEditingController();
    final terms = TextEditingController(text: 'Covers workmanship and replaced parts under workshop warranty terms.');
    var duration = 6;
    final formKey = GlobalKey<FormState>();
    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create warranty'),
          content: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: job, decoration: const InputDecoration(labelText: 'Completed job card ID'), validator: _required),
            const SizedBox(height: 12),
            TextFormField(controller: vehicle, decoration: const InputDecoration(labelText: 'Vehicle ID'), validator: _required),
            const SizedBox(height: 12),
            TextFormField(controller: customer, decoration: const InputDecoration(labelText: 'Customer ID'), validator: _required),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(value: duration, decoration: const InputDecoration(labelText: 'Duration'), items: const [1, 3, 6, 12].map((value) => DropdownMenuItem(value: value, child: Text('$value months'))).toList(), onChanged: (value) => setDialogState(() => duration = value ?? 6)),
            const SizedBox(height: 12),
            TextFormField(controller: terms, maxLines: 3, decoration: const InputDecoration(labelText: 'Terms'), validator: _required),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                await repository.createWarranty(shopId: shopId, jobCardId: job.text.trim(), vehicleId: vehicle.text.trim(), customerId: customer.text.trim(), durationMonths: duration, terms: terms.text.trim());
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              } on WarrantyFailure catch (error) { if (dialogContext.mounted) _message(dialogContext, error.message); }
            }, child: const Text('Create')),
          ],
        )),
      );
    } finally { job.dispose(); vehicle.dispose(); customer.dispose(); terms.dispose(); }
  }
}

class _WarrantyTile extends StatelessWidget {
  const _WarrantyTile({required this.warranty});
  final Warranty warranty;

  @override
  Widget build(BuildContext context) {
    final expired = warranty.expiryDate.isBefore(DateTime.now());
    return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
      leading: CircleAvatar(child: Icon(expired ? Icons.event_busy_outlined : Icons.verified_outlined)),
      title: Text('Job ${warranty.jobCardId}'),
      subtitle: Text('Vehicle ${warranty.vehicleId} · ${warranty.durationMonths} months · expires ${_date(warranty.expiryDate)}'),
      trailing: Chip(label: Text(expired ? 'Expired' : warranty.status.name)),
    ));
  }
}

String _date(DateTime value) => '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
String? _required(String? value) => value == null || value.trim().isEmpty ? 'Required' : null;
void _message(BuildContext context, String value) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
