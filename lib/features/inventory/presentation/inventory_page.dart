import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../app/localization/enum_l10n.dart';
import '../../../app/widgets/load_failure.dart';
import '../../../app/widgets/page_header.dart';
import '../../../core/errors/localized_failure.dart';
import '../../../core/firestore/resilient_query.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/domain/auth_user.dart';
import '../data/firebase_inventory_repository.dart';
import '../domain/inventory_item.dart';
import '../domain/inventory_movement.dart';
import '../domain/inventory_repository.dart';

class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key, required this.user, required this.repository});

  final AuthUser user;
  final InventoryRepository repository;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shopId = user.shopId;
    if (shopId == null) return Center(child: Text(l10n.noWorkshopAssigned));
    return StreamBuilder<List<InventoryItem>>(
      stream: resilientQuery(() => repository.watchItems(shopId)),
      builder: (context, snapshot) {
        if (!snapshot.hasData && !snapshot.hasError) return const Center(child: CircularProgressIndicator());
        return _InventoryContent(
          user: user,
          shopId: shopId,
          items: snapshot.data ?? const <InventoryItem>[],
          loadFailed: snapshot.hasError,
          repository: repository,
        );
      },
    );
  }
}

class _InventoryContent extends StatelessWidget {
  const _InventoryContent({
    required this.user,
    required this.shopId,
    required this.items,
    required this.repository,
    this.loadFailed = false,
  });

  final AuthUser user;
  final String shopId;
  final List<InventoryItem> items;
  final InventoryRepository repository;
  final bool loadFailed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canManage = user.role == UserRole.shopOwner || user.role == UserRole.manager;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        PageHeader(
          title: l10n.navInventory,
          subtitle: l10n.inventorySubtitle(items.length),
          action: canManage
              ? FilledButton.icon(onPressed: () => _createItem(context), icon: const Icon(Icons.add), label: Text(l10n.inventoryAddItem))
              : null,
        ),
        const SizedBox(height: 24),
        if (loadFailed)
          LoadFailure(message: l10n.inventoryLoadError)
        else if (items.isEmpty)
          Card(child: Padding(padding: const EdgeInsets.all(32), child: Center(child: Text(l10n.inventoryEmpty))))
        else
          ...items.map((item) => _InventoryTile(item: item, canManage: canManage, onMovement: () => _recordMovement(context, item))),
      ],
    );
  }

  Future<void> _createItem(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final name = TextEditingController();
    final sku = TextEditingController();
    final minimum = TextEditingController(text: '0');
    final selling = TextEditingController(text: '0');
    final formKey = GlobalKey<FormState>();
    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.inventoryCreateTitle),
          content: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(controller: name, decoration: InputDecoration(labelText: l10n.inventoryNameLabel), validator: (value) => _required(l10n, value)),
              const SizedBox(height: 12),
              TextFormField(controller: sku, decoration: InputDecoration(labelText: l10n.inventorySkuLabel), validator: (value) => _required(l10n, value)),
              const SizedBox(height: 12),
              TextFormField(controller: minimum, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l10n.inventoryMinimumStockLabel)),
              const SizedBox(height: 12),
              TextFormField(controller: selling, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l10n.inventorySellingPriceLabel)),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.cancel)),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  await repository.createItem(InventoryItem(
                    inventoryItemId: const Uuid().v4(), shopId: shopId, sku: sku.text.trim(), name: name.text.trim(), category: 'General', unit: 'piece',
                    quantityOnHand: 0, minimumStock: int.tryParse(minimum.text) ?? 0, costPriceMinorUnits: 0,
                    sellingPriceMinorUnits: int.tryParse(selling.text) ?? 0, isActive: true,
                  ));
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                } catch (_) {
                  if (dialogContext.mounted) _message(dialogContext, l10n.inventoryCreateError);
                }
              },
              child: Text(l10n.create),
            ),
          ],
        ),
      );
    } finally {
      name.dispose(); sku.dispose(); minimum.dispose(); selling.dispose();
    }
  }

  Future<void> _recordMovement(BuildContext context, InventoryItem item) async {
    final l10n = AppLocalizations.of(context);
    final quantity = TextEditingController();
    final reason = TextEditingController();
    var type = InventoryMovementType.stockIn;
    final formKey = GlobalKey<FormState>();
    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(l10n.inventoryMovementTitle(item.name)),
            content: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<InventoryMovementType>(isExpanded: true,value: type, items: InventoryMovementType.values.map((value) => DropdownMenuItem(value: value, child: Text(value.localizedLabel(l10n)))).toList(), onChanged: (value) => setDialogState(() => type = value ?? type)),
              const SizedBox(height: 12),
              TextFormField(controller: quantity, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l10n.quantityLabel), validator: (value) => int.tryParse(value ?? '') == null || int.parse(value!) <= 0 ? l10n.inventoryValidationPositiveQuantity : null),
              const SizedBox(height: 12),
              TextFormField(controller: reason, decoration: InputDecoration(labelText: l10n.inventoryReasonLabel), validator: (value) => _required(l10n, value)),
            ])),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.cancel)),
              FilledButton(onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  await repository.recordMovement(shopId: shopId, inventoryItemId: item.inventoryItemId, type: type, quantity: int.parse(quantity.text), reason: reason.text.trim());
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                } on InventoryFailure catch (error) { if (dialogContext.mounted) _message(dialogContext, localizedFailureMessage(AppLocalizations.of(dialogContext), error)); }
              }, child: Text(l10n.inventoryRecord)),
            ],
          ),
        ),
      );
    } finally { quantity.dispose(); reason.dispose(); }
  }
}

class _InventoryTile extends StatelessWidget {
  const _InventoryTile({required this.item, required this.canManage, required this.onMovement});
  final InventoryItem item;
  final bool canManage;
  final VoidCallback onMovement;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final low = item.quantityOnHand <= item.minimumStock;
    return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
      leading: CircleAvatar(child: Icon(low ? Icons.warning_amber_outlined : Icons.inventory_2_outlined)),
      title: Text(item.name), subtitle: Text('${item.sku} · ${item.quantityOnHand} ${item.unit}'),
      trailing: canManage ? IconButton(tooltip: l10n.inventoryRecordMovementTooltip, onPressed: onMovement, icon: const Icon(Icons.swap_vert)) : Chip(label: Text(low ? l10n.inventoryLowStock : l10n.inventoryInStock)),
    ));
  }
}

String? _required(AppLocalizations l10n, String? value) => value == null || value.trim().isEmpty ? l10n.validationRequired : null;
void _message(BuildContext context, String value) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
