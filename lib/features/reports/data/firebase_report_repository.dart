import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/localized_failure.dart';
import '../domain/report_repository.dart';
import '../domain/workshop_report.dart';

/// Builds the workshop summary from the same shop-scoped documents the rest of
/// the app already reads, so reports work on the free plan where Cloud
/// Functions cannot be deployed.
class FirebaseReportRepository implements ReportRepository {
  FirebaseReportRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<WorkshopReport> loadReport({
    required String shopId,
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final results = await Future.wait([
        _firestore.collection('jobCards').where('shopId', isEqualTo: shopId).get(),
        _firestore.collection('invoices').where('shopId', isEqualTo: shopId).get(),
        _firestore.collection('inventoryItems').where('shopId', isEqualTo: shopId).get(),
      ]);
      return _summarize(
        jobCards: results[0],
        invoices: results[1],
        inventoryItems: results[2],
        from: from,
        to: to,
      );
    } on FirebaseException catch (error) {
      final denied = error.code == 'permission-denied';
      throw ReportFailure(
        denied ? 'You are not authorized to view reports.' : 'Report generation is temporarily unavailable.',
        messageKey: denied ? 'errReportPermission' : 'errReportUnavailable',
      );
    }
  }

  WorkshopReport _summarize({
    required QuerySnapshot<Map<String, dynamic>> jobCards,
    required QuerySnapshot<Map<String, dynamic>> invoices,
    required QuerySnapshot<Map<String, dynamic>> inventoryItems,
    required DateTime from,
    required DateTime to,
  }) {
    var completedJobs = 0;
    for (final jobCard in jobCards.docs) {
      if (jobCard.data()['status'] != 'COMPLETED') continue;
      final updatedAt = _dateOf(jobCard.data()['updatedAt']);
      if (updatedAt == null || _inRange(updatedAt, from, to)) completedJobs++;
    }

    var invoiceCount = 0;
    var revenueMinorUnits = 0;
    var paidMinorUnits = 0;
    var outstandingMinorUnits = 0;
    for (final invoice in invoices.docs) {
      final data = invoice.data();
      if (data['status'] == 'VOIDED') continue;
      final createdAt = _dateOf(data['createdAt']);
      if (createdAt != null && !_inRange(createdAt, from, to)) continue;
      invoiceCount++;
      revenueMinorUnits += _minorUnits(data['totalMinorUnits']);
      paidMinorUnits += _minorUnits(data['amountPaidMinorUnits']);
      outstandingMinorUnits += _minorUnits(data['balanceMinorUnits']);
    }

    var lowStockItems = 0;
    for (final item in inventoryItems.docs) {
      final data = item.data();
      if (data['isActive'] == false) continue;
      if (_minorUnits(data['quantityOnHand']) <= _minorUnits(data['minimumStock'])) lowStockItems++;
    }

    return WorkshopReport(
      from: from,
      to: to,
      completedJobs: completedJobs,
      invoiceCount: invoiceCount,
      revenueMinorUnits: revenueMinorUnits,
      paidMinorUnits: paidMinorUnits,
      outstandingMinorUnits: outstandingMinorUnits,
      lowStockItems: lowStockItems,
    );
  }

  static int _minorUnits(Object? value) => value is num ? value.round() : 0;

  static DateTime? _dateOf(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value)?.toUtc();
    return null;
  }

  static bool _inRange(DateTime moment, DateTime from, DateTime to) =>
      !moment.isBefore(from) && !moment.isAfter(to);
}

class ReportFailure extends LocalizedFailure {
  const ReportFailure(super.message, {super.messageKey = 'errReportUnavailable'});
}
