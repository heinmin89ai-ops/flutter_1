import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Shown in place of a list when its read failed, so the page header and its
/// create action stay reachable instead of the whole screen collapsing.
class LoadFailure extends StatelessWidget {
  const LoadFailure({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        leading: Icon(Icons.cloud_off_outlined, color: colors.error),
        title: Text(message, style: TextStyle(color: colors.error)),
        trailing: onRetry == null
            ? null
            : TextButton(onPressed: onRetry, child: Text(l10n.retry)),
      ),
    );
  }
}
