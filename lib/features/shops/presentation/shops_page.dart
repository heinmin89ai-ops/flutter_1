import 'package:flutter/material.dart';

import '../../auth/domain/auth_user.dart';
import '../data/firebase_shop_repository.dart';
import '../data/firebase_staff_repository.dart';
import '../domain/shop.dart';
import '../domain/shop_repository.dart';
import '../domain/staff_member.dart';
import '../domain/staff_repository.dart';

class ShopsPage extends StatelessWidget {
  const ShopsPage({
    super.key,
    required this.user,
    required this.shopRepository,
    required this.staffRepository,
  });

  final AuthUser user;
  final ShopRepository shopRepository;
  final StaffRepository staffRepository;

  @override
  Widget build(BuildContext context) {
    if (user.role == UserRole.superAdmin && user.shopId == null) {
      return _PlatformShopsView(repository: shopRepository);
    }
    final shopId = user.shopId;
    if (shopId == null) {
      return const Center(child: Text('No workshop is assigned to this account.'));
    }
    return _ShopStaffView(
      shopId: shopId,
      canManageStaff: user.role == UserRole.shopOwner,
      shopRepository: shopRepository,
      staffRepository: staffRepository,
    );
  }
}

class _PlatformShopsView extends StatelessWidget {
  const _PlatformShopsView({required this.repository});

  final ShopRepository repository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Shop>>(
      stream: repository.watchAllShops(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _ErrorState(message: 'Unable to load workshops.');
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final shops = snapshot.data!;
        return _PageFrame(
          title: 'Workshops',
          subtitle: 'Platform-level workshop onboarding',
          action: FilledButton.icon(
            onPressed: () => _showCreateShopDialog(context),
            icon: const Icon(Icons.add_business_outlined),
            label: const Text('Create workshop'),
          ),
          child: shops.isEmpty
              ? const _EmptyState(message: 'No workshops have been onboarded.')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: shops.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => _ShopTile(shop: shops[index]),
                ),
        );
      },
    );
  }

  Future<void> _showCreateShopDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create workshop'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Workshop name'),
                validator: (value) => value == null || value.trim().isEmpty ? 'Enter a name.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: codeController,
                decoration: const InputDecoration(labelText: 'Workshop code'),
                validator: (value) => value == null || value.trim().length < 3 ? 'Use at least 3 characters.' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                await repository.createShop(name: nameController.text, code: codeController.text);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              } on ShopManagementFailure catch (error) {
                if (dialogContext.mounted) _showMessage(dialogContext, error.message);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
    nameController.dispose();
    codeController.dispose();
  }
}

class _ShopStaffView extends StatelessWidget {
  const _ShopStaffView({
    required this.shopId,
    required this.canManageStaff,
    required this.shopRepository,
    required this.staffRepository,
  });

  final String shopId;
  final bool canManageStaff;
  final ShopRepository shopRepository;
  final StaffRepository staffRepository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Shop?>(
      stream: shopRepository.watchShop(shopId),
      builder: (context, shopSnapshot) {
        if (shopSnapshot.hasError) return _ErrorState(message: 'Unable to load workshop settings.');
        if (!shopSnapshot.hasData) return const Center(child: CircularProgressIndicator());
        final shop = shopSnapshot.data;
        if (shop == null) return const _ErrorState(message: 'Workshop not found.');
        return _PageFrame(
          title: shop.name,
          subtitle: '${shop.code} · ${shop.currency} · ${shop.timezone}',
          action: canManageStaff
              ? FilledButton.icon(
                  onPressed: () => _showCreateStaffDialog(context),
                  icon: const Icon(Icons.person_add_outlined),
                  label: const Text('Add staff'),
                )
              : null,
          child: StreamBuilder<List<StaffMember>>(
            stream: staffRepository.watchStaff(shopId),
            builder: (context, staffSnapshot) {
              if (staffSnapshot.hasError) return const _ErrorState(message: 'Unable to load staff.');
              if (!staffSnapshot.hasData) return const Center(child: CircularProgressIndicator());
              final staff = staffSnapshot.data!;
              if (staff.isEmpty) return const _EmptyState(message: 'No staff accounts found.');
              return ListView.separated(
                shrinkWrap: true,
                itemCount: staff.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) => _StaffTile(
                  member: staff[index],
                  canManage: canManageStaff,
                  onChanged: (role, isActive) => staffRepository.updateStaff(
                    shopId: shopId,
                    uid: staff[index].uid,
                    role: role,
                    isActive: isActive,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showCreateStaffDialog(BuildContext context) async {
    final emailController = TextEditingController();
    final nameController = TextEditingController();
    var role = UserRole.frontDesk;
    final formKey = GlobalKey<FormState>();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add staff account'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Full name'),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Enter a name.' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) => value == null || !value.contains('@') ? 'Enter a valid email.' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<UserRole>(
                  value: role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: UserRole.values.where((item) => item != UserRole.superAdmin && item != UserRole.shopOwner).map((item) {
                    return DropdownMenuItem(value: item, child: Text(item.label));
                  }).toList(),
                  onChanged: (value) => setDialogState(() => role = value ?? UserRole.frontDesk),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  await staffRepository.createStaff(
                    shopId: shopId,
                    email: emailController.text,
                    name: nameController.text,
                    role: role,
                  );
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                } on StaffManagementFailure catch (error) {
                  if (dialogContext.mounted) _showMessage(dialogContext, error.message);
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
    emailController.dispose();
    nameController.dispose();
  }
}

class _StaffTile extends StatelessWidget {
  const _StaffTile({required this.member, required this.canManage, required this.onChanged});

  final StaffMember member;
  final bool canManage;
  final Future<void> Function(UserRole role, bool isActive) onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text(member.name.isEmpty ? '?' : member.name[0].toUpperCase())),
        title: Text(member.name.isEmpty ? member.email : member.name),
        subtitle: Text('${member.email} · ${member.role.label}'),
        trailing: canManage
            ? Switch(
                value: member.isActive,
                onChanged: (value) => onChanged(member.role, value),
              )
            : Chip(label: Text(member.isActive ? 'Active' : 'Inactive')),
      ),
    );
  }
}

class _ShopTile extends StatelessWidget {
  const _ShopTile({required this.shop});

  final Shop shop;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.storefront_outlined)),
        title: Text(shop.name),
        subtitle: Text('${shop.code} · ${shop.timezone}'),
        trailing: Chip(label: Text(shop.isActive ? 'Active' : 'Inactive')),
      ),
    );
  }
}

class _PageFrame extends StatelessWidget {
  const _PageFrame({required this.title, required this.subtitle, required this.child, this.action});

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Text(subtitle),
                ],
              ),
            ),
            if (action != null) action!,
          ],
        ),
        const SizedBox(height: 24),
        child,
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(32), child: Text(message)));
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(child: Text(message));
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
