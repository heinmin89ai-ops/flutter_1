import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/localized_failure.dart';
import '../domain/job_card.dart';
import '../domain/job_card_repository.dart';

class FirebaseJobCardRepository implements JobCardRepository {
  FirebaseJobCardRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Stream<List<JobCard>> watchJobCards(String shopId) {
    return _firestore
        .collection('jobCards')
        .where('shopId', isEqualTo: shopId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => JobCard.fromMap(doc.id, _mapTimestamps(doc.data()))).toList());
  }

  @override
  Future<JobCard> createJobCard(JobCard jobCard) async {
    await _firestore.collection('jobCards').doc(jobCard.jobCardId).set({
      ...jobCard.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return jobCard;
  }

  @override
  Future<JobCard> transitionJobCard({
    required String shopId,
    required String jobCardId,
    required JobCardStatus target,
  }) async {
    final reference = _firestore.collection('jobCards').doc(jobCardId);
    final milestone = switch (target.value) {
      'OPEN' => 'openedAt',
      'IN_PROGRESS' => 'startedAt',
      'COMPLETED' => 'completedAt',
      'CLOSED' => 'closedAt',
      _ => null,
    };
    try {
      await reference.update({
        'status': target.value,
        'updatedAt': FieldValue.serverTimestamp(),
        if (milestone != null) milestone: FieldValue.serverTimestamp(),
      });
      final snapshot = await reference.get();
      return JobCard.fromMap(jobCardId, _mapTimestamps(snapshot.data() ?? const <String, dynamic>{}));
    } on FirebaseException catch (error) {
      final failure = _failureForCode(error.code);
      throw JobCardFailure(failure.message, messageKey: failure.messageKey);
    }
  }

  @override
  Future<void> assignMechanic({required String shopId, required String jobCardId, required String mechanicUid}) async {
    try {
      await _firestore.collection('jobCards').doc(jobCardId).update({
        'assignedMechanicIds': [mechanicUid.trim()],
        'status': 'ASSIGNED',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error) {
      final failure = _failureForCode(error.code);
      throw JobCardFailure(failure.message, messageKey: failure.messageKey);
    }
  }

  @override
  Future<void> updateWorkNotes({
    required String shopId,
    required String jobCardId,
    required String notes,
    String? diagnosis,
  }) async {
    try {
      await _firestore.collection('jobCards').doc(jobCardId).update({
        'repairNotes': notes,
        'diagnosis': diagnosis,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error) {
      final failure = _failureForCode(error.code);
      throw JobCardFailure(failure.message, messageKey: failure.messageKey);
    }
  }

  Map<String, dynamic> _mapTimestamps(Map<String, dynamic> data) {
    return data.map((key, value) {
      if (value is Timestamp) return MapEntry(key, value.toDate());
      return MapEntry(key, value);
    });
  }

  ({String messageKey, String message}) _failureForCode(String code) {
    switch (code) {
      case 'permission-denied':
        return (messageKey: 'errJobCardPermission', message: 'You are not authorized to perform this job-card action.');
      case 'failed-precondition':
        return (messageKey: 'errJobCardStale', message: 'This job card changed. Refresh and try again.');
      case 'not-found':
        return (messageKey: 'errJobCardNotFound', message: 'Job card was not found in this workshop.');
      default:
        return (messageKey: 'errJobCardUnavailable', message: 'Job card operation is temporarily unavailable.');
    }
  }
}

class JobCardFailure extends LocalizedFailure {
  const JobCardFailure(super.message, {super.messageKey = 'errJobCardUnavailable'});
}
