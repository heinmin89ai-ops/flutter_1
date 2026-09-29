import 'dart:async';

import 'package:flutter/material.dart';

import 'resilient_query.dart';

typedef QueryBuilder<T> = Widget Function(BuildContext context, AsyncSnapshot<T> snapshot, VoidCallback retry);

/// Owns a Firestore listen so the page that shows its failure can re-open it.
/// A plain [StreamBuilder] cannot retry: the stream is built once and, once it
/// has closed with an error, the only way to re-read is to leave and return.
class RetryableQuery<T> extends StatefulWidget {
  const RetryableQuery({super.key, required this.subscribe, required this.builder});

  final Stream<T> Function() subscribe;
  final QueryBuilder<T> builder;

  @override
  State<RetryableQuery<T>> createState() => _RetryableQueryState<T>();
}

class _RetryableQueryState<T> extends State<RetryableQuery<T>> {
  late Stream<T> _stream;
  int _attempt = 0;

  @override
  void initState() {
    super.initState();
    _open();
  }

  void _open() {
    _stream = resilientQuery(widget.subscribe);
  }

  void _retry() {
    setState(() {
      _attempt++;
      _open();
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      key: ValueKey(_attempt),
      stream: _stream,
      builder: (context, snapshot) => widget.builder(context, snapshot, _retry),
    );
  }
}
