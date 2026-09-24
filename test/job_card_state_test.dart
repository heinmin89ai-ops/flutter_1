import 'package:flutter_test/flutter_test.dart';

import 'package:workshop_ops/features/auth/domain/auth_user.dart';
import 'package:workshop_ops/features/job_cards/domain/job_card.dart';

void main() {
  test('allows the normal repair workflow by role', () {
    expect(JobCardStatus.draft.canTransitionTo(JobCardStatus.open, UserRole.frontDesk), isTrue);
    expect(JobCardStatus.open.canTransitionTo(JobCardStatus.assigned, UserRole.manager), isTrue);
    expect(JobCardStatus.assigned.canTransitionTo(JobCardStatus.inProgress, UserRole.mechanic), isTrue);
    expect(JobCardStatus.completed.canTransitionTo(JobCardStatus.readyForPickup, UserRole.manager), isTrue);
    expect(JobCardStatus.readyForPickup.canTransitionTo(JobCardStatus.closed, UserRole.frontDesk), isTrue);
  });

  test('blocks unauthorized and backwards transitions', () {
    expect(JobCardStatus.draft.canTransitionTo(JobCardStatus.assigned, UserRole.frontDesk), isFalse);
    expect(JobCardStatus.open.canTransitionTo(JobCardStatus.assigned, UserRole.frontDesk), isFalse);
    expect(JobCardStatus.completed.canTransitionTo(JobCardStatus.inProgress, UserRole.manager), isFalse);
    expect(JobCardStatus.inProgress.canTransitionTo(JobCardStatus.closed, UserRole.mechanic), isFalse);
  });
}