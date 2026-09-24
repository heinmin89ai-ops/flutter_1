import 'package:flutter_test/flutter_test.dart';

import 'package:workshop_ops/core/sync/sync_queue_item.dart';

void main() {
  test('creates a stable idempotency key for a queued mutation', () {
    final item = SyncQueueItem(
      id: 'queue-1',
      shopId: 'shop-1',
      entityType: 'vehicles',
      entityId: 'vehicle-1',
      operation: SyncOperation.create,
      payload: <String, Object?>{'licensePlate': 'ABC123'},
      createdAt: DateTime(2026, 1, 1),
      retryCount: 0,
      lastAttemptAt: null,
      status: SyncQueueStatus.pending,
      errorMessage: null,
    );

    expect(item.idempotencyKey, 'vehicles:vehicle-1:create');
  });
}