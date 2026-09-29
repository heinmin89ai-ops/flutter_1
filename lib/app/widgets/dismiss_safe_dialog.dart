import 'dart:async';

import 'package:flutter/material.dart';

/// Shows [builder] as a dialog and only returns once it has left the screen.
///
/// `showDialog` resolves as soon as the route is popped, while its subtree
/// stays mounted for the 150ms exit transition. A caller that releases
/// something the dialog builds from -- typically a `TextEditingController` --
/// at that point has it used after disposal, which trips
/// "A TextEditingController was used after being disposed" whenever the form
/// rebuilds during the transition (typing in a field and then tapping the
/// barrier or Cancel reproduces it).
Future<void> showDialogUntilDismissed(
  BuildContext context, {
  required WidgetBuilder builder,
}) async {
  final route = DialogRoute<void>(context: context, builder: builder);
  await Navigator.of(context, rootNavigator: true).push(route);
  await _transitionFinished(route);
}

Future<void> _transitionFinished(TransitionRoute<void> route) {
  final animation = route.animation;
  if (animation == null || animation.status == AnimationStatus.dismissed) return Future<void>.value();
  final completer = Completer<void>();
  void onStatus(AnimationStatus status) {
    if (status != AnimationStatus.dismissed) return;
    animation.removeStatusListener(onStatus);
    completer.complete();
  }

  animation.addStatusListener(onStatus);
  return completer.future;
}
