import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

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
    final shopId = user.shopId;
    if (shopId == null) return const Center(child: Text('No workshop is assigned to this account.'));
    return StreamBuilder<List<InventoryItem>>(
      stream: repository.watchItems(shopId),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('Unable to load inventory.'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        return _InventoryContent(user: user, shopId: shopId, items: snapshot.data!, repository: repository);
      },
    );
  }
}

class _InventoryContent extends StatelessWidget {
  const _InventoryContent({required this.user, required this.shopId, required this.items, required this.repository});

  final AuthUser user;
  final String shopId;
  final List<InventoryItem> items;
  final InventoryRepository repository;

  @override
  Widget build(BuildContext context) {
    final canManage = user.role == UserRole.shopOwner || user.role == UserRole.manager;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Inventory', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text('${items.length} items · quantity changes are recorded as movements'),
              ]),
            ),
            if (canManage)
              FilledButton.icon(onPressed: () => _createItem(context), icon: const Icon(Icons.add), label: const Text('Add item')),
          ],
        ),
        const SizedBox(height: 24),
        if (items.isEmpty)
          const Card(child: Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No inventory items found.'))))
        else
          ...items.map((item) => _InventoryTile(item: item, canManage: canManage, onMovement: () => _recordMovement(context, item))),
      ],
    );
  }

  Future<void> _createItem(BuildContext context) async {
    final name = TextEditingController();
    final sku = TextEditingController();
    final minimum = TextEditingController(text: '0');
    final selling = TextEditingController(text: '0');
    final formKey = GlobalKey<FormState>();
    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Add inventory item'),
          content: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Name'), validator: _required),
              const SizedBox(height: 12),
              TextFormField(controller: sku, decoration: const InputDecoration(labelText: 'SKU'), validator: _required),
              const SizedBox(height: 12),
              TextFormField(controller: minimum, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Minimum stock')),
              const SizedBox(height: 12),
              TextFormField(controller: selling, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Selling price (minor units)')),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
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
                  if (dialogContext.mounted) _message(dialogContext, 'Unable to create inventory item.');
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      );
    } finally {
      name.dispose(); sku.dispose(); minimum.dispose(); selling.dispose();
    }
  }

  Future<void> _recordMovement(BuildContext context, InventoryItem item) async {
    final quantity = TextEditingController();
    final reason = TextEditingController();
    var type = InventoryMovementType.stockIn;
    final formKey = GlobalKey<FormState>();
    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text('Stock movement · ${item.name}'),
            content: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<InventoryMovementType>(value: type, items: InventoryMovementType.values.map((value) => DropdownMenuItem(value: value, child: Text(value.value))).toList(), onChanged: (value) => setDialogState(() => type = value ?? type)),
              const SizedBox(height: 12),
              TextFormField(controller: quantity, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity'), validator: (value) => int.tryParse(value ?? '') == null || int.parse(value!) <= 0 ? 'Enter a positive quantity.' : null),
              const SizedBox(height: 12),
              TextFormField(controller: reason, decoration: const InputDecoration(labelText: 'Reason'), validator: _required),
            ])),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
              FilledButton(onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  await repository.recordMovement(shopId: shopId, inventoryItemId: item.inventoryItemId, type: type, quantity: int.parse(quantity.text), reason: reason.text.trim());
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                } on InventoryFailure catch (error) { if (dialogContext.mounted) _message(dialogContext, error.message); }
              }, child: const Text('Record')),
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
    final low = item.quantityOnHand <= item.minimumStock;
    return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
      leading: CircleAvatar(child: Icon(low ? Icons.warning_amber_outlined : Icons.inventory_2_outlined)),
      title: Text(item.name), subtitle: Text('${item.sku} · ${item.quantityOnHand} ${item.unit}'),
      trailing: canManage ? IconButton(tooltip: 'Record stock movement', onPressed: onMovement, icon: const Icon(Icons.swap_vert)) : Chip(label: Text(low ? 'Low stock' : 'In stock')),
    ));
  }
}

String? _required(String? value) => value == null || value.trim().isEmpty ? 'Required' : null;
void _message(BuildContext context, String value) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
