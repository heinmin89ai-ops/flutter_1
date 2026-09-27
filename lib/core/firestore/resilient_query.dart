import 'dart:async';

/// A Firestore listen dies for good when the backend rejects the re-subscription
/// the SDK makes after a network drop or a trip to the background. The page is
/// then frozen on its error state until the user navigates away and back, so
/// re-open the query a few times before giving up.
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
        if (++failures >= maxAttempts) {
          closed = true;
          controller
            ..addError(error, stack)
            ..close();
          return;
        }
        retry = Timer(Duration(seconds: 2 * failures), open);
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
