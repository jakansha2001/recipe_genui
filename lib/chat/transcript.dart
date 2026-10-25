import 'dart:typed_data';

import 'package:genui/genui.dart';

/// One entry in the visible conversation. Entries are immutable; the session
/// replaces an entry to change it (e.g. as streamed text grows).
sealed class TranscriptEntry {
  const TranscriptEntry(this.id);

  /// Unique within a session; used as the list key so generated surfaces keep
  /// their state while the transcript grows.
  final int id;
}

/// Something the user typed, optionally with a photo.
final class UserMessage extends TranscriptEntry {
  const UserMessage(super.id, {required this.text, this.image});

  final String text;
  final Uint8List? image;
}

/// What the user did inside a generated surface, echoed as a bubble.
final class UserAction extends TranscriptEntry {
  const UserAction(super.id, {required this.summary, required this.payload});

  /// Human-readable, e.g. "Selected: Dal Tadka".
  final String summary;

  /// The A2UI action message that went back to the model.
  final JsonMap payload;
}

/// The model's plain-text reply, which grows as it streams.
final class AssistantText extends TranscriptEntry {
  const AssistantText(super.id, this.text);

  final String text;

  AssistantText append(String chunk) => AssistantText(id, text + chunk);
}

/// A generated surface, added once it is complete and safe to render.
final class AssistantSurface extends TranscriptEntry {
  const AssistantSurface(super.id, this.surfaceId);

  final String surfaceId;
}

enum RepairStatus { inProgress, fixed, failed }

/// Shown while the app asks the model to rebuild a broken surface — the
/// self-healing loop made visible.
final class RepairNotice extends TranscriptEntry {
  const RepairNotice(super.id, {this.status = RepairStatus.inProgress});

  final RepairStatus status;

  RepairNotice resolved({required bool fixed}) => RepairNotice(
    id,
    status: fixed ? RepairStatus.fixed : RepairStatus.failed,
  );
}

/// A failed request, explained in words the user can act on.
final class ErrorNotice extends TranscriptEntry {
  const ErrorNotice(super.id, {required this.message, required this.details});

  final String message;

  /// The raw error, for debugging.
  final String details;
}
