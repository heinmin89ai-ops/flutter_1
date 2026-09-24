class WorkshopReport {
  const WorkshopReport({required this.from, required this.to, required this.completedJobs, required this.invoiceCount, required this.revenueMinorUnits, required this.paidMinorUnits, required this.outstandingMinorUnits, required this.lowStockItems});

  final DateTime from;
  final DateTime to;
  final int completedJobs;
  final int invoiceCount;
  final int revenueMinorUnits;
  final int paidMinorUnits;
  final int outstandingMinorUnits;
  final int lowStockItems;

  factory WorkshopReport.fromMap(Map<String, dynamic> map) => WorkshopReport(
        from: DateTime.parse(map['from'] as String), to: DateTime.parse(map['to'] as String), completedJobs: (map['completedJobs'] as num?)?.toInt() ?? 0,
        invoiceCount: (map['invoiceCount'] as num?)?.toInt() ?? 0, revenueMinorUnits: (map['revenueMinorUnits'] as num?)?.toInt() ?? 0,
        paidMinorUnits: (map['paidMinorUnits'] as num?)?.toInt() ?? 0, outstandingMinorUnits: (map['outstandingMinorUnits'] as num?)?.toInt() ?? 0,
        lowStockItems: (map['lowStockItems'] as num?)?.toInt() ?? 0,
      );
}
