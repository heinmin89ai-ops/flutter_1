import 'package:flutter/material.dart';

import '../../../core/sync/sync_status.dart';
import '../../../l10n/app_localizations.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.syncStatus});

  final SyncStatus syncStatus;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          l10n.workshopOverview,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.workshopOverviewSubtitle,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        _SyncBanner(status: syncStatus),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 900 ? 4 : 2;
            const spacing = 16.0;
            final cardWidth = (constraints.maxWidth - spacing * (columns - 1)) / columns;
            // A grid forces a fixed cell height, which clips the cards as soon
            // as a translated label wraps. Wrap lets each card size itself.
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                SizedBox(width: cardWidth, child: _MetricCard(
                  icon: Icons.assignment_outlined,
                  label: l10n.metricOpenJobCards,
                  value: '0',
                  detail: l10n.metricOpenJobCardsDetail,
                )),
                SizedBox(width: cardWidth, child: _MetricCard(
                  icon: Icons.directions_car_outlined,
                  label: l10n.metricVehiclesToday,
                  value: '0',
                  detail: l10n.metricVehiclesTodayDetail,
                )),
                SizedBox(width: cardWidth, child: _MetricCard(
                  icon: Icons.build_outlined,
                  label: l10n.metricInProgress,
                  value: '0',
                  detail: l10n.metricInProgressDetail,
                )),
                SizedBox(width: cardWidth, child: _MetricCard(
                  icon: Icons.payments_outlined,
                  label: l10n.metricPendingBalance,
                  value: '0.00',
                  detail: l10n.metricPendingBalanceDetail,
                )),
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
    final l10n = AppLocalizations.of(context);
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
                  Text(status.label(l10n), style: Theme.of(context).textTheme.titleMedium),
                  Text(status.description(l10n)),
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
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            Text(detail, maxLines: 2, overflow: TextOverflow.ellipsis),
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
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.todaySectionTitle, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.search_outlined),
              title: Text(l10n.todayPlateSearchTitle),
              subtitle: Text(l10n.todayPlateSearchSubtitle),
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.sync_outlined),
              title: Text(l10n.todaySyncQueueTitle),
              subtitle: Text(l10n.todaySyncQueueSubtitle),
            ),
          ],
        ),
      ),
    );
  }
}
