import 'package:cloud_functions/cloud_functions.dart';

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
      throw ReportFailure(error.code == 'permission-denied' ? 'You are not authorized to view reports.' : 'Report generation is temporarily unavailable.');
    }
  }
}

class ReportFailure implements Exception {
  const ReportFailure(this.message);
  final String message;
}
