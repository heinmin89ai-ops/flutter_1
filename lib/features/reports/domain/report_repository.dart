import 'workshop_report.dart';

abstract interface class ReportRepository {
  Future<WorkshopReport> loadReport({required String shopId, required DateTime from, required DateTime to});
}
