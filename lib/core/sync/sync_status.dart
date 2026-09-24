enum SyncStatus {
  online,
  offline,
  syncing,
  pending,
  failed,
}

extension SyncStatusLabel on SyncStatus {
  String get label {
    switch (this) {
      case SyncStatus.online:
        return 'Online';
      case SyncStatus.offline:
        return 'Offline';
      case SyncStatus.syncing:
        return 'Syncing';
      case SyncStatus.pending:
        return 'Pending changes';
      case SyncStatus.failed:
        return 'Sync failed';
    }
  }

  String get description {
    switch (this) {
      case SyncStatus.online:
        return 'All local changes are synchronized.';
      case SyncStatus.offline:
        return 'Changes will be queued on this device.';
      case SyncStatus.syncing:
        return 'Uploading local changes securely.';
      case SyncStatus.pending:
        return 'Local work is saved and waiting to sync.';
      case SyncStatus.failed:
        return 'Some changes need attention before retrying.';
    }
  }
}
