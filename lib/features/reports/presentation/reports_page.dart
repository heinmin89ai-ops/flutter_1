import 'package:flutter/material.dart';

import '../../../app/widgets/page_header.dart';
import '../../../core/errors/localized_failure.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/domain/auth_user.dart';
import '../data/firebase_report_repository.dart';
import '../domain/report_repository.dart';
import '../domain/workshop_report.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key, required this.user, required this.repository});

  final AuthUser user;
  final ReportRepository repository;

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  WorkshopReport? _report;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (widget.user.shopId == null) return Center(child: Text(l10n.noWorkshopAssigned));
    return ListView(padding: const EdgeInsets.all(24), children: [
      PageHeader(title: l10n.navReports, subtitle: l10n.reportsPageSubtitle),
      const SizedBox(height: 24),
      if (_loading) const LinearProgressIndicator(),
      if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
      if (_report != null) _ReportContent(report: _report!),
    ]);
  }

  Future<void> _load() async {
    final shopId = widget.user.shopId;
    if (shopId == null) return;
    final to = DateTime.now().toUtc();
    final from = to.subtract(const Duration(days: 30));
    setState(() { _loading = true; _error = null; });
    try {
      final report = await widget.repository.loadReport(shopId: shopId, from: from, to: to);
      if (mounted) setState(() => _report = report);
    } on ReportFailure catch (error) {
      if (mounted) setState(() => _error = localizedFailureMessage(AppLocalizations.of(context), error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _ReportContent extends StatelessWidget {
  const _ReportContent({required this.report});
  final WorkshopReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cards = <Widget>[
      _Metric(label: l10n.reportsMetricCompletedJobs, value: '${report.completedJobs}', icon: Icons.check_circle_outline),
      _Metric(label: l10n.reportsMetricInvoices, value: '${report.invoiceCount}', icon: Icons.receipt_long_outlined),
      _Metric(label: l10n.reportsMetricRevenue, value: '${report.revenueMinorUnits}', icon: Icons.trending_up_outlined),
      _Metric(label: l10n.reportsMetricPaid, value: '${report.paidMinorUnits}', icon: Icons.payments_outlined),
      _Metric(label: l10n.reportsMetricOutstanding, value: '${report.outstandingMinorUnits}', icon: Icons.account_balance_wallet_outlined),
      _Metric(label: l10n.reportsMetricLowStock, value: '${report.lowStockItems}', icon: Icons.warning_amber_outlined),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth >= 900 ? 3 : 2;
      const spacing = 12.0;
      final cardWidth = (constraints.maxWidth - spacing * (columns - 1)) / columns;
      // A fixed-height grid clips these cards whenever a label wraps.
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [for (final card in cards) SizedBox(width: cardWidth, child: Card(child: Padding(padding: const EdgeInsets.all(16), child: card)))],
      );
    });
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Icon(icon, color: Theme.of(context).colorScheme.primary),
    const SizedBox(height: 12),
    Text(label),
    Text(value, style: Theme.of(context).textTheme.headlineSmall),
  ]);
}
