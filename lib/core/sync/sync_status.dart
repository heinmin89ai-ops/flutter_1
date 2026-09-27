import '../../l10n/app_localizations.dart';

enum SyncStatus {
  online,
  offline,
  syncing,
  pending,
  failed,
}

extension SyncStatusLabel on SyncStatus {
  String label(AppLocalizations l10n) => switch (this) {
    SyncStatus.online => l10n.syncStatusOnline,
    SyncStatus.offline => l10n.syncStatusOffline,
    SyncStatus.syncing => l10n.syncStatusSyncing,
    SyncStatus.pending => l10n.syncStatusPending,
    SyncStatus.failed => l10n.syncStatusFailed,
  };

  String description(AppLocalizations l10n) => switch (this) {
    SyncStatus.online => l10n.syncDescOnline,
    SyncStatus.offline => l10n.syncDescOffline,
    SyncStatus.syncing => l10n.syncDescSyncing,
    SyncStatus.pending => l10n.syncDescPending,
    SyncStatus.failed => l10n.syncDescFailed,
  };
}
