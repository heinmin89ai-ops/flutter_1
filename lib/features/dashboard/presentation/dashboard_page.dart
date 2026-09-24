import 'package:flutter/material.dart';

import '../../../core/sync/sync_status.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.syncStatus});

  final SyncStatus syncStatus;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Workshop overview',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'A clear view of today\'s work, even when the network is unavailable.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        _SyncBanner(status: syncStatus),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 900 ? 4 : 2;
            return GridView.count(
              crossAxisCount: columns,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.45,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                _MetricCard(
                  icon: Icons.assignment_outlined,
                  label: 'Open job cards',
                  value: '0',
                  detail: 'No records loaded yet',
                ),
                _MetricCard(
                  icon: Icons.directions_car_outlined,
                  label: 'Vehicles today',
                  value: '0',
                  detail: 'Ready for local search',
                ),
                _MetricCard(
                  icon: Icons.build_outlined,
                  label: 'In progress',
                  value: '0',
                  detail: 'Assigned mechanic work',
                ),
                _MetricCard(
                  icon: Icons.payments_outlined,
                  label: 'Pending balance',
                  value: '0.00',
                  detail: 'Currency will come from shop settings',
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        const _TodaySection(),
      ],
    );
  }
}

class _SyncBanner extends StatelessWidget {
  const _SyncBanner({required this.status});

  final SyncStatus status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.cloud_done_outlined, color: colorScheme.onSecondaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(status.label, style: Theme.of(context).textTheme.titleMedium),
                  Text(status.description),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const Spacer(),
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            Text(detail, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _TodaySection extends StatelessWidget {
  const _TodaySection();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Today', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.search_outlined),
              title: Text('License plate search'),
              subtitle: Text('Local indexed search will be available in the Customers and Vehicles phase.'),
            ),
            const Divider(),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.sync_outlined),
              title: Text('Sync queue'),
              subtitle: Text('Every offline mutation will remain visible until cloud synchronization completes.'),
            ),
          ],
        ),
      ),
    );
  }
}
