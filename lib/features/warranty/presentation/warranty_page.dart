import 'package:flutter/material.dart';

import '../../../app/localization/enum_l10n.dart';
import '../../../app/widgets/load_failure.dart';
import '../../../app/widgets/page_header.dart';
import '../../../core/errors/localized_failure.dart';
import '../../../core/firestore/resilient_query.dart';
import '../../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    final shopId = user.shopId;
    if (shopId == null) return Center(child: Text(l10n.noWorkshopAssigned));
    return StreamBuilder<List<Warranty>>(
      stream: resilientQuery(() => repository.watchWarranties(shopId)),
      builder: (context, snapshot) {
        if (!snapshot.hasData && !snapshot.hasError) return const Center(child: CircularProgressIndicator());
        final warranties = snapshot.data ?? const <Warranty>[];
        final canCreate = user.role == UserRole.shopOwner || user.role == UserRole.manager;
        return ListView(padding: const EdgeInsets.all(24), children: [
          PageHeader(
            title: l10n.navWarranty,
            subtitle: l10n.warrantyRecordCount(warranties.length),
            action: canCreate
                ? FilledButton.icon(onPressed: () => _createWarranty(context, shopId), icon: const Icon(Icons.add), label: Text(l10n.warrantyCreate))
                : null,
          ),
          const SizedBox(height: 24),
          if (snapshot.hasError)
            LoadFailure(message: l10n.warrantyLoadError)
          else if (warranties.isEmpty) Card(child: Padding(padding: const EdgeInsets.all(32), child: Center(child: Text(l10n.warrantyEmpty))))
          else ...warranties.map((warranty) => _WarrantyTile(warranty: warranty)),
        ]);
      },
    );
  }

  Future<void> _createWarranty(BuildContext context, String shopId) async {
    final l10n = AppLocalizations.of(context);
    final job = TextEditingController();
    final vehicle = TextEditingController();
    final customer = TextEditingController();
    final terms = TextEditingController(text: l10n.warrantyDefaultTerms);
    var duration = 6;
    final formKey = GlobalKey<FormState>();
    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.warrantyCreate),
          content: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: job, decoration: InputDecoration(labelText: l10n.warrantyCompletedJobIdLabel), validator: (value) => _required(l10n, value)),
            const SizedBox(height: 12),
            TextFormField(controller: vehicle, decoration: InputDecoration(labelText: l10n.vehicleIdLabel), validator: (value) => _required(l10n, value)),
            const SizedBox(height: 12),
            TextFormField(controller: customer, decoration: InputDecoration(labelText: l10n.customerIdLabel), validator: (value) => _required(l10n, value)),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(isExpanded: true,value: duration, decoration: InputDecoration(labelText: l10n.warrantyDurationLabel), items: const [1, 3, 6, 12].map((value) => DropdownMenuItem(value: value, child: Text(l10n.warrantyDurationMonths(value)))).toList(), onChanged: (value) => setDialogState(() => duration = value ?? 6)),
            const SizedBox(height: 12),
            TextFormField(controller: terms, maxLines: 3, decoration: InputDecoration(labelText: l10n.warrantyTermsLabel), validator: (value) => _required(l10n, value)),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.cancel)),
            FilledButton(onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                await repository.createWarranty(shopId: shopId, jobCardId: job.text.trim(), vehicleId: vehicle.text.trim(), customerId: customer.text.trim(), durationMonths: duration, terms: terms.text.trim());
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              } on WarrantyFailure catch (error) { if (dialogContext.mounted) _message(dialogContext, localizedFailureMessage(AppLocalizations.of(dialogContext), error)); }
            }, child: Text(l10n.create)),
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
    final l10n = AppLocalizations.of(context);
    final expired = warranty.expiryDate.isBefore(DateTime.now());
    return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
      leading: CircleAvatar(child: Icon(expired ? Icons.event_busy_outlined : Icons.verified_outlined)),
      title: Text(l10n.warrantyTileJobTitle(warranty.jobCardId)),
      subtitle: Text(l10n.warrantyTileSubtitle(warranty.vehicleId, warranty.durationMonths, _date(warranty.expiryDate))),
      trailing: Chip(label: Text(expired ? l10n.warrantyStatusExpired : warranty.status.localizedLabel(l10n))),
    ));
  }
}

String _date(DateTime value) => '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
String? _required(AppLocalizations l10n, String? value) => value == null || value.trim().isEmpty ? l10n.validationRequired : null;
void _message(BuildContext context, String value) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
