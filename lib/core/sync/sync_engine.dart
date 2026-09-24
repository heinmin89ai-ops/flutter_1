import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'sqlite_sync_queue.dart';
import 'sync_queue_item.dart';
import 'sync_status.dart';

abstract interface class SyncOperationHandler {
  Future<void> apply(SyncQueueItem item);
}

class SyncEngine {
  SyncEngine({required this.queue, required this.handler, Connectivity? connectivity}) : _connectivity = connectivity ?? Connectivity();

  final SqliteSyncQueue queue;
  final SyncOperationHandler handler;
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _running = false;
  final status = ValueNotifier<SyncStatus>(SyncStatus.pending);

  Future<void> start() async {
    status.value = SyncStatus.pending;
    await queue.initialize();
    await queue.recoverStaleSyncing();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
      if (results.any((result) => result != ConnectivityResult.none)) syncNow();
    });
    await syncNow();
  }

  Future<void> syncNow() async {
    if (_running) return;
    _running = true;
    status.value = SyncStatus.syncing;
    try {
      final items = await queue.pending();
      if (items.isEmpty) status.value = SyncStatus.online;
      for (final item in items) {
        if (item.retryCount >= 8) continue;
        await queue.markSyncing(item.id);
        try {
          await handler.apply(item);
          await queue.markCompleted(item.id);
          status.value = SyncStatus.online;
        } catch (error) {
          await queue.markFailed(item.id, error.toString());
          status.value = SyncStatus.failed;
          final delaySeconds = 1 << (item.retryCount > 5 ? 5 : item.retryCount);
          await Future<void>.delayed(Duration(seconds: delaySeconds));
        }
      }
    } finally {
      _running = false;
    }
  }

  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    status.dispose();
  }
}
