import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

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
    final shopId = user.shopId;
    if (shopId == null) return const Center(child: Text('No workshop is assigned to this account.'));
    return StreamBuilder<List<JobCard>>(
      stream: repository.watchJobCards(shopId),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('Unable to load job cards.'));
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
    final canCreate = user.role != UserRole.mechanic;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Job cards', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Text('${jobCards.length} visible job cards · ${user.role?.label ?? 'Staff'}'),
                ],
              ),
            ),
            if (canCreate)
              FilledButton.icon(
                onPressed: () => _showCreateDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('New job card'),
              ),
          ],
        ),
        const SizedBox(height: 24),
        if (jobCards.isEmpty)
          const Card(child: Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No job cards found.'))))
        else
          ...jobCards.map((jobCard) => _JobCardTile(user: user, repository: repository, shopId: shopId, jobCard: jobCard)),
      ],
    );
  }

  Future<void> _showCreateDialog(BuildContext context) async {
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
            title: const Text('Create job card'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: customerController,
                    decoration: const InputDecoration(labelText: 'Customer ID'),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: vehicleController,
                    decoration: const InputDecoration(labelText: 'Vehicle ID'),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: complaintController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Customer complaint'),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: priority,
                    decoration: const InputDecoration(labelText: 'Priority'),
                    items: const [
                      DropdownMenuItem(value: 'LOW', child: Text('Low')),
                      DropdownMenuItem(value: 'NORMAL', child: Text('Normal')),
                      DropdownMenuItem(value: 'HIGH', child: Text('High')),
                      DropdownMenuItem(value: 'URGENT', child: Text('Urgent')),
                    ],
                    onChanged: (value) => setDialogState(() => priority = value ?? 'NORMAL'),
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
                    if (dialogContext.mounted) _showMessage(dialogContext, error.message);
                  }
                },
                child: const Text('Create'),
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
                Chip(label: Text(jobCard.status.label)),
              ],
            ),
            const SizedBox(height: 8),
            Text(jobCard.complaint),
            const SizedBox(height: 4),
            Text('Priority: ${jobCard.priority} · Vehicle: ${jobCard.vehicleId}'),
            if (jobCard.assignedMechanicIds.isNotEmpty) Text('Assigned mechanics: ${jobCard.assignedMechanicIds.length}'),
            if (nextStatuses.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final status in nextStatuses)
                    OutlinedButton(
                      onPressed: () => _transition(context, status),
                      child: Text(status.label),
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
                  label: const Text('Assign mechanic'),
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
      if (context.mounted) _showMessage(context, error.message);
    }
  }

  Future<void> _assignMechanic(BuildContext context) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Assign mechanic'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Mechanic user ID'),
              validator: _required,
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  await repository.assignMechanic(shopId: shopId, jobCardId: jobCard.jobCardId, mechanicUid: controller.text);
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                } on JobCardFailure catch (error) {
                  if (dialogContext.mounted) _showMessage(dialogContext, error.message);
                }
              },
              child: const Text('Assign'),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
  }
}

String? _required(String? value) => value == null || value.trim().isEmpty ? 'Required' : null;

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
