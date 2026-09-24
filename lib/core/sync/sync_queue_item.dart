enum SyncOperation { create, update, delete }
enum SyncQueueStatus { pending, syncing, failed, completed }

class SyncQueueItem {
  const SyncQueueItem({required this.id, required this.shopId, required this.entityType, required this.entityId, required this.operation, required this.payload, required this.createdAt, required this.retryCount, required this.lastAttemptAt, required this.status, required this.errorMessage});

  final String id;
  final String shopId;
  final String entityType;
  final String entityId;
  final SyncOperation operation;
  final Map<String, Object?> payload;
  final DateTime createdAt;
  final int retryCount;
  final DateTime? lastAttemptAt;
  final SyncQueueStatus status;
  final String? errorMessage;

  String get idempotencyKey => '$entityType:$entityId:${operation.name}';

  factory SyncQueueItem.fromMap(Map<String, Object?> map) => SyncQueueItem(
        id: map['id']! as String,
        shopId: map['shopId']! as String,
        entityType: map['entityType']! as String,
        entityId: map['entityId']! as String,
        operation: SyncOperation.values.byName(map['operation']! as String),
        payload: Map<String, Object?>.from((map['payload'] as Map?)?.cast<String, Object?>() ?? const {}),
        createdAt: DateTime.parse(map['createdAt']! as String),
        retryCount: map['retryCount']! as int,
        lastAttemptAt: map['lastAttemptAt'] == null ? null : DateTime.parse(map['lastAttemptAt']! as String),
        status: SyncQueueStatus.values.byName(map['status']! as String),
        errorMessage: map['errorMessage'] as String?,
      );
}
