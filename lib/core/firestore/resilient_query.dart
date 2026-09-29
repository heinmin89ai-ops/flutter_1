import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

/// A Firestore listen dies for good when the backend rejects the re-subscription
/// the SDK makes after a network drop or a trip to the background. The page is
/// then frozen on its error state until the user navigates away and back, so
/// re-open the query a few times before giving up.
///
/// A rejected read is not a dropped connection: re-asking with the same token
/// and the same rules is guaranteed to fail again, so it is reported at once
/// instead of after five backoffs the user spends watching a spinner.
Stream<T> resilientQuery<T>(Stream<T> Function() subscribe, {int maxAttempts = 5}) {
  late final StreamController<T> controller;
  StreamSubscription<T>? subscription;
  Timer? retry;
  var failures = 0;
  var closed = false;

  void open() {
    subscription = subscribe().listen(
      (value) {
        failures = 0;
        controller.add(value);
      },
      onError: (Object error, StackTrace stack) {
        final dead = subscription;
        subscription = null;
        unawaited(dead?.cancel());
        if (closed) return;
        final denied = error is FirebaseException && error.code == 'permission-denied';
        if (!denied && ++failures < maxAttempts) {
          retry = Timer(Duration(seconds: 2 * failures), open);
          return;
        }
        closed = true;
        controller
          ..addError(error, stack)
          ..close();
      },
      onDone: () {
        if (closed) return;
        closed = true;
        controller.close();
      },
    );
  }

  controller = StreamController<T>(
    onListen: open,
    onCancel: () async {
      closed = true;
      retry?.cancel();
      await subscription?.cancel();
    },
  );
  return controller.stream;
}
