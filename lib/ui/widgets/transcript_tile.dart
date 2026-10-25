import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';

import 'package:recipe_genui/chat/sage_session.dart';
import 'package:recipe_genui/chat/transcript.dart';
import 'package:recipe_genui/ui/widgets/chat_bubble.dart';
import 'package:recipe_genui/ui/widgets/notice.dart';
import 'package:recipe_genui/ui/widgets/protocol_peek.dart';

/// Renders one [TranscriptEntry].
class TranscriptTile extends StatelessWidget {
  const TranscriptTile({
    super.key,
    required this.entry,
    required this.session,
    required this.showProtocol,
  });

  final TranscriptEntry entry;
  final SageSession session;

  /// Whether to show the raw A2UI messages under surfaces and actions.
  final bool showProtocol;

  @override
  Widget build(BuildContext context) {
    return switch (entry) {
      UserMessage(:final text, :final image) => ChatBubble.user(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (image != null)
              Padding(
                padding: EdgeInsets.only(bottom: text.isEmpty ? 0 : 6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(image, width: 140, cacheWidth: 420),
                ),
              ),
            if (text.isNotEmpty) Text(text),
          ],
        ),
      ),
      UserAction(:final summary, :final payload) => Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ChatBubble.user(child: Text(summary)),
          if (showProtocol)
            Padding(
              padding: const EdgeInsets.only(left: 48, bottom: 12),
              child: ProtocolPeek(label: 'A2UI to model', messages: [payload]),
            ),
        ],
      ),
      AssistantText(:final text) => ChatBubble.assistant(
        child: Text(text.trim()),
      ),
      AssistantSurface(:final surfaceId) => Padding(
        padding: const EdgeInsets.only(bottom: 12, right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Surface(surfaceContext: session.surfaces.contextFor(surfaceId)),
            if (showProtocol)
              ProtocolPeek(
                label: 'A2UI from model',
                messages: session.protocolFor(surfaceId),
              ),
          ],
        ),
      ),
      RepairNotice(:final status) => switch (status) {
        RepairStatus.inProgress => const Notice(
          tone: NoticeTone.working,
          message: 'Sage sent an incomplete screen. Asking it to rebuild…',
        ),
        RepairStatus.fixed => const Notice(
          tone: NoticeTone.success,
          message: 'Rebuilt — the model fixed its screen.',
        ),
        RepairStatus.failed => const Notice(
          tone: NoticeTone.warning,
          message: "Sage couldn't rebuild that screen. Try asking again.",
        ),
      },
      ErrorNotice(:final message, :final details) => Notice(
        tone: NoticeTone.error,
        message: message,
        details: kDebugMode ? details : null,
      ),
    };
  }
}
