import 'package:flutter/material.dart';

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
    if (widget.user.shopId == null) return const Center(child: Text('No workshop is assigned to this account.'));
    return ListView(padding: const EdgeInsets.all(24), children: [
      Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Reports', style: Theme.of(context).textTheme.headlineMedium), const SizedBox(height: 4), const Text('Operational and financial summary for the last 30 days.')]))]),
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
      if (mounted) setState(() => _error = error.message);
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
    final cards = <Widget>[
      _Metric(label: 'Completed jobs', value: '${report.completedJobs}', icon: Icons.check_circle_outline),
      _Metric(label: 'Invoices', value: '${report.invoiceCount}', icon: Icons.receipt_long_outlined),
      _Metric(label: 'Revenue', value: '${report.revenueMinorUnits}', icon: Icons.trending_up_outlined),
      _Metric(label: 'Paid', value: '${report.paidMinorUnits}', icon: Icons.payments_outlined),
      _Metric(label: 'Outstanding', value: '${report.outstandingMinorUnits}', icon: Icons.account_balance_wallet_outlined),
      _Metric(label: 'Low stock', value: '${report.lowStockItems}', icon: Icons.warning_amber_outlined),
    ];
    return GridView.count(crossAxisCount: MediaQuery.sizeOf(context).width >= 900 ? 3 : 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.6, children: cards);
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: Theme.of(context).colorScheme.primary), const Spacer(), Text(label), Text(value, style: Theme.of(context).textTheme.headlineSmall)])));
}
