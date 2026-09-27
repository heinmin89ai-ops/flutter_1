import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../app/localization/enum_l10n.dart';
import '../../../app/widgets/page_header.dart';
import '../../../core/errors/localized_failure.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/domain/auth_user.dart';
import '../data/firebase_job_card_repository.dart';
import '../domain/job_card.dart';
import '../domain/job_card_repository.dart';

class JobCardsPage extends StatelessWidget {
  const JobCardsPage({super.key, required this.user, required this.repository});

  final AuthUser user;
  final JobCardRepository repository;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shopId = user.shopId;
    if (shopId == null) return Center(child: Text(l10n.noWorkshopAssigned));
    return StreamBuilder<List<JobCard>>(
      stream: repository.watchJobCards(shopId),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text(l10n.jobCardsLoadError));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var jobCards = snapshot.data!;
        if (user.role == UserRole.mechanic) {
          jobCards = jobCards.where((job) => job.assignedMechanicIds.contains(user.uid)).toList();
        }
        return _JobCardsContent(
          user: user,
          repository: repository,
          shopId: shopId,
          jobCards: jobCards,
        );
      },
    );
  }
}

class _JobCardsContent extends StatelessWidget {
  const _JobCardsContent({required this.user, required this.repository, required this.shopId, required this.jobCards});

  final AuthUser user;
  final JobCardRepository repository;
  final String shopId;
  final List<JobCard> jobCards;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canCreate = user.role != UserRole.mechanic;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        PageHeader(
          title: l10n.navJobCards,
          subtitle: l10n.jobCardsSubtitle(jobCards.length, user.role?.localizedLabel(l10n) ?? l10n.jobCardsFallbackRole),
          action: canCreate
              ? FilledButton.icon(
                  onPressed: () => _showCreateDialog(context),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.jobCardsNew),
                )
              : null,
        ),
        const SizedBox(height: 24),
        if (jobCards.isEmpty)
          Card(child: Padding(padding: const EdgeInsets.all(32), child: Center(child: Text(l10n.jobCardsEmpty))))
        else
          ...jobCards.map((jobCard) => _JobCardTile(user: user, repository: repository, shopId: shopId, jobCard: jobCard)),
      ],
    );
  }

  Future<void> _showCreateDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final customerController = TextEditingController();
    final vehicleController = TextEditingController();
    final complaintController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var priority = 'NORMAL';
    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(l10n.jobCardsCreateTitle),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: customerController,
                    decoration: InputDecoration(labelText: l10n.customerIdLabel),
                    validator: (value) => _required(l10n, value),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: vehicleController,
                    decoration: InputDecoration(labelText: l10n.vehicleIdLabel),
                    validator: (value) => _required(l10n, value),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: complaintController,
                    maxLines: 3,
                    decoration: InputDecoration(labelText: l10n.jobCardsComplaintLabel),
                    validator: (value) => _required(l10n, value),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(isExpanded: true,
                    value: priority,
                    decoration: InputDecoration(labelText: l10n.jobCardsPriorityLabel),
                    items: [
                      DropdownMenuItem(value: 'LOW', child: Text(l10n.jobCardsPriorityLow)),
                      DropdownMenuItem(value: 'NORMAL', child: Text(l10n.jobCardsPriorityNormal)),
                      DropdownMenuItem(value: 'HIGH', child: Text(l10n.jobCardsPriorityHigh)),
                      DropdownMenuItem(value: 'URGENT', child: Text(l10n.jobCardsPriorityUrgent)),
                    ],
                    onChanged: (value) => setDialogState(() => priority = value ?? 'NORMAL'),
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
                    final id = const Uuid().v4();
                    await repository.createJobCard(JobCard(
                      jobCardId: id,
                      shopId: shopId,
                      jobNumber: 'JC-${DateTime.now().millisecondsSinceEpoch}',
                      customerId: customerController.text.trim(),
                      vehicleId: vehicleController.text.trim(),
                      status: JobCardStatus.draft,
                      priority: priority,
                      complaint: complaintController.text.trim(),
                      diagnosis: null,
                      repairNotes: null,
                      assignedMechanicIds: const [],
                      createdBy: user.uid,
                      approvedBy: null,
                      grandTotalMinorUnits: 0,
                      openedAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    ));
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                  } on JobCardFailure catch (error) {
                    if (dialogContext.mounted) _showMessage(dialogContext, localizedFailureMessage(AppLocalizations.of(dialogContext), error));
                  }
                },
                child: Text(l10n.create),
              ),
            ],
          ),
        ),
      );
    } finally {
      customerController.dispose();
      vehicleController.dispose();
      complaintController.dispose();
    }
  }
}

class _JobCardTile extends StatelessWidget {
  const _JobCardTile({required this.user, required this.repository, required this.shopId, required this.jobCard});

  final AuthUser user;
  final JobCardRepository repository;
  final String shopId;
  final JobCard jobCard;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final nextStatuses = JobCardStatus.values.where((status) => jobCard.status.canTransitionTo(status, user.role!)).toList();
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(jobCard.jobNumber, style: Theme.of(context).textTheme.titleLarge)),
                Chip(label: Text(jobCard.status.localizedLabel(l10n))),
              ],
            ),
            const SizedBox(height: 8),
            Text(jobCard.complaint),
            const SizedBox(height: 4),
            Text(l10n.jobCardsTilePriorityVehicle(jobCard.priority, jobCard.vehicleId)),
            if (jobCard.assignedMechanicIds.isNotEmpty) Text(l10n.jobCardsAssignedMechanics(jobCard.assignedMechanicIds.length)),
            if (nextStatuses.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final status in nextStatuses)
                    OutlinedButton(
                      onPressed: () => _transition(context, status),
                      child: Text(status.localizedLabel(l10n)),
                    ),
                ],
              ),
            ],
            if (jobCard.status == JobCardStatus.open && (user.role == UserRole.manager || user.role == UserRole.shopOwner))
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _assignMechanic(context),
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  label: Text(l10n.jobCardsAssignMechanic),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _transition(BuildContext context, JobCardStatus status) async {
    try {
      await repository.transitionJobCard(shopId: shopId, jobCardId: jobCard.jobCardId, target: status);
    } on JobCardFailure catch (error) {
      if (context.mounted) _showMessage(context, localizedFailureMessage(AppLocalizations.of(context), error));
    }
  }

  Future<void> _assignMechanic(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.jobCardsAssignMechanic),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(labelText: l10n.jobCardsMechanicIdLabel),
              validator: (value) => _required(l10n, value),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.cancel)),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  await repository.assignMechanic(shopId: shopId, jobCardId: jobCard.jobCardId, mechanicUid: controller.text);
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                } on JobCardFailure catch (error) {
                  if (dialogContext.mounted) _showMessage(dialogContext, localizedFailureMessage(AppLocalizations.of(dialogContext), error));
                }
              },
              child: Text(l10n.jobCardsAssign),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
  }
}

String? _required(AppLocalizations l10n, String? value) => value == null || value.trim().isEmpty ? l10n.validationRequired : null;

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
