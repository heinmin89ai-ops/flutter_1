import 'package:flutter/material.dart';

import '../../../app/localization/enum_l10n.dart';
import '../../../app/widgets/page_header.dart';
import '../../../core/errors/localized_failure.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/domain/auth_user.dart';
import '../data/firebase_shop_repository.dart';
import '../data/firebase_staff_repository.dart';
import '../domain/shop.dart';
import '../domain/shop_repository.dart';
import '../domain/staff_invitation.dart';
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
    final l10n = AppLocalizations.of(context);
    if (user.role == UserRole.superAdmin && user.shopId == null) {
      return _PlatformShopsView(repository: shopRepository);
    }
    final shopId = user.shopId;
    if (shopId == null) {
      return Center(child: Text(l10n.noWorkshopAssigned));
    }
    return _ShopStaffView(
      shopId: shopId,
      currentUid: user.uid,
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
    final l10n = AppLocalizations.of(context);
    return StreamBuilder<List<Shop>>(
      stream: repository.watchAllShops(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _ErrorState(message: l10n.shopsLoadWorkshopsError);
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final shops = snapshot.data!;
        return _PageFrame(
          title: l10n.shopsPlatformTitle,
          subtitle: l10n.shopsPlatformSubtitle,
          action: FilledButton.icon(
            onPressed: () => _showCreateShopDialog(context),
            icon: const Icon(Icons.add_business_outlined),
            label: Text(l10n.shopsCreateWorkshop),
          ),
          child: shops.isEmpty
              ? _EmptyState(message: l10n.shopsWorkshopsEmpty)
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
    final l10n = AppLocalizations.of(context);
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.shopsCreateWorkshop),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(labelText: l10n.shopsWorkshopNameLabel),
                validator: (value) => value == null || value.trim().isEmpty ? l10n.validationEnterName : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: codeController,
                decoration: InputDecoration(labelText: l10n.shopsWorkshopCodeLabel),
                validator: (value) => value == null || value.trim().length < 3 ? l10n.shopsValidationCodeLength : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                await repository.createShop(name: nameController.text, code: codeController.text);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              } on ShopManagementFailure catch (error) {
                if (dialogContext.mounted) _showMessage(dialogContext, localizedFailureMessage(AppLocalizations.of(dialogContext), error));
              }
            },
            child: Text(l10n.create),
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
    required this.currentUid,
    required this.canManageStaff,
    required this.shopRepository,
    required this.staffRepository,
  });

  final String shopId;
  final String currentUid;
  final bool canManageStaff;
  final ShopRepository shopRepository;
  final StaffRepository staffRepository;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StreamBuilder<Shop?>(
      stream: shopRepository.watchShop(shopId),
      builder: (context, shopSnapshot) {
        if (shopSnapshot.hasError) return _ErrorState(message: l10n.shopsLoadSettingsError);
        if (!shopSnapshot.hasData) return const Center(child: CircularProgressIndicator());
        final shop = shopSnapshot.data;
        if (shop == null) return _ErrorState(message: l10n.shopsNotFound);
        return _PageFrame(
          title: shop.name,
          subtitle: '${shop.code} · ${shop.currency} · ${shop.timezone}',
          action: canManageStaff
              ? FilledButton.icon(
                  onPressed: () => _showCreateStaffDialog(context),
                  icon: const Icon(Icons.person_add_outlined),
                  label: Text(l10n.shopsAddStaff),
                )
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StreamBuilder<List<StaffMember>>(
                stream: staffRepository.watchStaff(shopId),
                builder: (context, staffSnapshot) {
                  if (staffSnapshot.hasError) return _ErrorState(message: l10n.shopsLoadStaffError);
                  if (!staffSnapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final staff = staffSnapshot.data!;
                  if (staff.isEmpty) return _EmptyState(message: l10n.shopsStaffEmpty);
                  return Column(
                    children: [
                      for (final member in staff)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _StaffTile(
                            member: member,
                            canManage: canManageStaff && member.uid != currentUid,
                            onChanged: (role, isActive) => staffRepository.updateStaff(
                              shopId: shopId,
                              uid: member.uid,
                              role: role,
                              isActive: isActive,
                            ),
                            onResetPassword: () => _showSendResetDialog(context, member),
                          ),
                        ),
                    ],
                  );
                },
              ),
              if (canManageStaff)
                StreamBuilder<List<StaffInvitation>>(
                  stream: staffRepository.watchInvitations(shopId),
                  builder: (context, inviteSnapshot) {
                    final invitations = inviteSnapshot.data ?? const <StaffInvitation>[];
                    if (invitations.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 24),
                        Text(l10n.pendingInvitationsTitle, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        for (final invitation in invitations)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _InvitationTile(
                              invitation: invitation,
                              onView: () => _showInvitationDetails(context, invitation),
                              onCancel: () => _cancelInvitation(context, invitation.code),
                            ),
                          ),
                      ],
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showCreateStaffDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final emailController = TextEditingController();
    final nameController = TextEditingController();
    var role = UserRole.frontDesk;
    final formKey = GlobalKey<FormState>();
    StaffInvitation? created;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.shopsCreateStaffTitle),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: l10n.shopsFullNameLabel),
                  validator: (value) => value == null || value.trim().isEmpty ? l10n.validationEnterName : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: l10n.emailLabel),
                  validator: (value) => value == null || !value.contains('@') ? l10n.validationValidEmail : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<UserRole>(isExpanded: true,
                  initialValue: role,
                  decoration: InputDecoration(labelText: l10n.shopsRoleLabel),
                  items: UserRole.values.where((item) => item != UserRole.superAdmin && item != UserRole.shopOwner).map((item) {
                    return DropdownMenuItem(value: item, child: Text(item.localizedLabel(l10n)));
                  }).toList(),
                  onChanged: (value) => setDialogState(() => role = value ?? UserRole.frontDesk),
                ),
                const SizedBox(height: 12),
                Text(l10n.invitationShareBody, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.cancel)),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  final invitation = await staffRepository.createStaff(
                    shopId: shopId,
                    email: emailController.text,
                    name: nameController.text,
                    role: role,
                  );
                  created = invitation;
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                } on StaffManagementFailure catch (error) {
                  if (dialogContext.mounted) _showMessage(dialogContext, localizedFailureMessage(AppLocalizations.of(dialogContext), error));
                }
              },
              child: Text(l10n.create),
            ),
          ],
        ),
      ),
    );
    final invitation = created;
    if (invitation != null && context.mounted) {
      await _showInvitationDetails(context, invitation);
    }
    emailController.dispose();
    nameController.dispose();
  }

  Future<void> _showInvitationDetails(BuildContext context, StaffInvitation invitation) async {
    final l10n = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.mark_email_unread_outlined),
        title: Text(l10n.invitationCreatedTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.invitationShareBody),
            const SizedBox(height: 16),
            _SecretRow(label: l10n.emailLabel, value: invitation.email),
            if (invitation.temporaryPassword.isNotEmpty)
              _SecretRow(label: l10n.temporaryPasswordLabel, value: invitation.temporaryPassword),
            _SecretRow(label: l10n.invitationCodeLabel, value: invitation.code),
            const SizedBox(height: 16),
            Text(l10n.invitationActivationHint, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.done)),
        ],
      ),
    );
  }

  Future<void> _cancelInvitation(BuildContext context, String code) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await staffRepository.cancelInvitation(code: code);
      messenger.showSnackBar(SnackBar(content: Text(l10n.invitationCancelled)));
    } on StaffManagementFailure catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(localizedFailureMessage(l10n, error))));
    }
  }

  Future<void> _showSendResetDialog(BuildContext context, StaffMember member) async {
    final l10n = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.sendResetLinkTitle),
        content: Text(l10n.sendResetLinkBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () async {
              try {
                await staffRepository.sendPasswordReset(email: member.email);
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  _showMessage(dialogContext, l10n.resetEmailSent);
                }
              } on StaffManagementFailure catch (error) {
                if (dialogContext.mounted) {
                  _showMessage(dialogContext, localizedFailureMessage(AppLocalizations.of(dialogContext), error));
                }
              }
            },
            child: Text(l10n.sendResetLink),
          ),
        ],
      ),
    );
  }
}

class _SecretRow extends StatelessWidget {
  const _SecretRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          SelectableText(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _StaffTile extends StatelessWidget {
  const _StaffTile({
    required this.member,
    required this.canManage,
    required this.onChanged,
    required this.onResetPassword,
  });

  final StaffMember member;
  final bool canManage;
  final Future<void> Function(UserRole role, bool isActive) onChanged;
  final VoidCallback onResetPassword;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text(member.name.isEmpty ? '?' : member.name[0].toUpperCase())),
        title: Text(member.name.isEmpty ? member.email : member.name),
        subtitle: Text('${member.email} · ${member.role.localizedLabel(l10n)}'),
        trailing: canManage
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: l10n.sendResetLink,
                    onPressed: onResetPassword,
                    icon: const Icon(Icons.lock_reset_outlined),
                  ),
                  Switch(
                    value: member.isActive,
                    onChanged: (value) => onChanged(member.role, value),
                  ),
                ],
              )
            : Chip(label: Text(member.isActive ? l10n.statusActive : l10n.statusInactive)),
      ),
    );
  }
}

class _InvitationTile extends StatelessWidget {
  const _InvitationTile({
    required this.invitation,
    required this.onView,
    required this.onCancel,
  });

  final StaffInvitation invitation;
  final VoidCallback onView;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.hourglass_empty_outlined)),
        title: Text(invitation.name.isEmpty ? invitation.email : invitation.name),
        subtitle: Text('${invitation.email} · ${invitation.role.localizedLabel(l10n)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: l10n.viewInvitationCode,
              onPressed: onView,
              icon: const Icon(Icons.visibility_outlined),
            ),
            IconButton(
              tooltip: l10n.cancelInvitation,
              onPressed: onCancel,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopTile extends StatelessWidget {
  const _ShopTile({required this.shop});

  final Shop shop;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.storefront_outlined)),
        title: Text(shop.name),
        subtitle: Text('${shop.code} · ${shop.timezone}'),
        trailing: Chip(label: Text(shop.isActive ? l10n.statusActive : l10n.statusInactive)),
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
        PageHeader(title: title, subtitle: subtitle, action: action),
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
