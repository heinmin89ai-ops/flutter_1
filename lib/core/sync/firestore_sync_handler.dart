import 'package:cloud_firestore/cloud_firestore.dart';

import 'sync_engine.dart';
import 'sync_queue_item.dart';

class FirestoreSyncOperationHandler implements SyncOperationHandler {
  FirestoreSyncOperationHandler({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<void> apply(SyncQueueItem item) async {
    final reference = _firestore.collection(item.entityType).doc(item.entityId);
    switch (item.operation) {
      case SyncOperation.create:
      case SyncOperation.update:
        await reference.set({...item.payload, 'shopId': item.shopId, 'syncIdempotencyKey': item.idempotencyKey, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: item.operation == SyncOperation.update));
      case SyncOperation.delete:
        await reference.delete();
    }
  }
}
