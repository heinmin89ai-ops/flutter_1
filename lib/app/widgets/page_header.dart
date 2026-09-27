import 'package:flutter/material.dart';

/// Title, subtitle and optional action used at the top of every feature page.
///
/// The action drops below the text on narrow screens: a long translated
/// button label otherwise steals the row's width and the title wraps into a
/// tower of one-character lines.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme;
    final texts = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: textStyle.headlineMedium),
        const SizedBox(height: 4),
        Text(subtitle, style: textStyle.bodyMedium),
      ],
    );
    final currentAction = action;
    if (currentAction == null) return texts;

    final isWide = MediaQuery.sizeOf(context).width >= 560;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: texts),
            if (isWide) currentAction,
          ],
        ),
        if (!isWide) ...[
          const SizedBox(height: 12),
          currentAction,
        ],
      ],
    );
  }
}
