import 'package:flutter/material.dart';

enum NoticeTone { working, success, warning, error }

/// A full-width status line in the transcript: repairs and errors.
class Notice extends StatelessWidget {
  const Notice({
    super.key,
    required this.tone,
    required this.message,
    this.details,
  });

  final NoticeTone tone;
  final String message;

  /// Extra technical detail, shown smaller underneath.
  final String? details;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (tone) {
      NoticeTone.working => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
      NoticeTone.success => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      NoticeTone.warning => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      NoticeTone.error => (scheme.errorContainer, scheme.onErrorContainer),
    };
    final leading = switch (tone) {
      NoticeTone.working => SizedBox.square(
        dimension: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
      ),
      NoticeTone.success => Icon(
        Icons.auto_fix_high,
        size: 20,
        color: foreground,
      ),
      NoticeTone.warning => Icon(
        Icons.info_outline,
        size: 20,
        color: foreground,
      ),
      NoticeTone.error => Icon(
        Icons.error_outline,
        size: 20,
        color: foreground,
      ),
    };
    final details = this.details;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leading,
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(color: foreground, fontSize: 14),
                ),
                if (details != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    details,
                    style: TextStyle(
                      color: foreground.withValues(alpha: 0.75),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
