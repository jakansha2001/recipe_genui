import 'dart:convert';

import 'package:genui/genui.dart';

/// What a generated surface sent back to the model: a user action, or an
/// error report that asks the model to fix its UI.
sealed class UiSubmission {
  const UiSubmission(this.payload);

  /// The A2UI message as sent, e.g. `{"version": "v0.9", "action": {...}}`.
  final JsonMap payload;

  /// The submissions in [message]'s UI interaction parts. Anything that isn't
  /// an A2UI action or error is ignored.
  static Iterable<UiSubmission> parse(ChatMessage message) sync* {
    for (final part in message.parts) {
      if (!part.isUiInteractionPart) continue;
      final Object? json;
      try {
        json = jsonDecode(part.asUiInteractionPart!.interaction);
      } on FormatException {
        continue;
      }
      if (json is! JsonMap) continue;
      if (json['action'] case final JsonMap action) {
        yield ActionSubmission(json, action);
      } else if (json['error'] is JsonMap) {
        yield ErrorSubmission(json);
      }
    }
  }
}

final class ActionSubmission extends UiSubmission {
  const ActionSubmission(super.payload, this.action);

  final JsonMap action;

  /// A short echo of what the user chose, or null if there is nothing
  /// readable to show.
  String? get summary {
    final context = action['context'];
    if (context is! JsonMap || context.isEmpty) return null;
    if (context['title'] case final Object title) return 'Selected: $title';
    if (context['adjustment'] case final Object adjustment) {
      return 'Adjust: $adjustment';
    }
    final parts = <String>[
      for (final MapEntry(:key, :value) in context.entries)
        if (!key.toLowerCase().contains('id')) ..._readable(key, value),
    ];
    return parts.isEmpty ? null : parts.join(', ');
  }

  static Iterable<String> _readable(String key, Object? value) sync* {
    switch (value) {
      case final List<Object?> items:
        yield* items.map((item) => '$item');
      case final String text when text.isNotEmpty:
        yield text;
      case final num number:
        yield key == 'servings' ? 'for $number' : '$number';
    }
  }
}

final class ErrorSubmission extends UiSubmission {
  const ErrorSubmission(super.payload);

  /// The surface the error is about, when it names one.
  String? get surfaceId => switch (payload['error']) {
    {'surfaceId': final String id} => id,
    _ => null,
  };
}
