import '../../auth/domain/auth_user.dart';
import 'job_card.dart';

abstract interface class JobCardRepository {
  Stream<List<JobCard>> watchJobCards(String shopId);

  Future<JobCard> createJobCard(JobCard jobCard);

  Future<JobCard> transitionJobCard({
    required String shopId,
    required String jobCardId,
    required JobCardStatus target,
  });

  Future<void> assignMechanic({
    required String shopId,
    required String jobCardId,
    required String mechanicUid,
  });

  Future<void> updateWorkNotes({
    required String shopId,
    required String jobCardId,
    required String notes,
    String? diagnosis,
  });
}
