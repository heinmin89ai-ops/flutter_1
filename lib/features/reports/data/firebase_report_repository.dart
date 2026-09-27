import 'package:cloud_functions/cloud_functions.dart';

import '../../../core/errors/localized_failure.dart';
import '../domain/report_repository.dart';
import '../domain/workshop_report.dart';

class FirebaseReportRepository implements ReportRepository {
  FirebaseReportRepository({FirebaseFunctions? functions}) : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  @override
  Future<WorkshopReport> loadReport({required String shopId, required DateTime from, required DateTime to}) async {
    try {
      final result = await _functions.httpsCallable('getWorkshopReport').call({'shopId': shopId, 'from': from.toUtc().toIso8601String(), 'to': to.toUtc().toIso8601String()});
      return WorkshopReport.fromMap(Map<String, dynamic>.from(result.data as Map));
    } on FirebaseFunctionsException catch (error) {
      final denied = error.code == 'permission-denied';
      throw ReportFailure(
        denied ? 'You are not authorized to view reports.' : 'Report generation is temporarily unavailable.',
        messageKey: denied ? 'errReportPermission' : 'errReportUnavailable',
      );
    }
  }
}

class ReportFailure extends LocalizedFailure {
  const ReportFailure(super.message, {super.messageKey = 'errReportUnavailable'});
}
