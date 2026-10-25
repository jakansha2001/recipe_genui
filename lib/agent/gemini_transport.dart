import 'dart:async';

import 'package:a2ui_core/a2ui_core.dart' as core;
import 'package:firebase_ai/firebase_ai.dart' as fb;
import 'package:genui/genui.dart';
import 'package:logging/logging.dart';

/// The seam between genui and Gemini, via Firebase AI Logic.
///
/// genui is backend-agnostic: it only needs the model's streamed text fed into
/// an [A2uiTransportAdapter], which parses A2UI out of it. This class does that
/// one job, so swapping model providers means replacing only this file. There
/// is no API key here — Firebase AI Logic holds it, and App Check proves the
/// requests come from this app.
final class GeminiTransport implements Transport {
  GeminiTransport({
    required String systemInstruction,
    String model = defaultModel,
  }) : _chat = fb.FirebaseAI.googleAI()
           .generativeModel(
             model: model,
             systemInstruction: fb.Content.system(systemInstruction),
           )
           .startChat() {
    _adapter = A2uiTransportAdapter(onSend: _send);
  }

  static const String defaultModel = 'gemini-3.1-flash-lite';

  static final Logger _log = Logger('GeminiTransport');

  final fb.ChatSession _chat;
  late final A2uiTransportAdapter _adapter;

  @override
  Stream<String> get incomingText => _adapter.incomingText;

  @override
  Stream<core.A2uiMessage> get incomingMessages => _adapter.incomingMessages;

  @override
  Future<void> sendRequest(ChatMessage message) =>
      _adapter.sendRequest(message);

  @override
  void dispose() => _adapter.dispose();

  Future<void> _send(ChatMessage message) async {
    final reply = StringBuffer();
    await for (final response in _chat.sendMessageStream(_toContent(message))) {
      final text = response.text;
      if (text == null || text.isEmpty) continue;
      // Each chunk goes straight into the A2UI parser, which buffers it and
      // turns complete JSON blocks into messages.
      _adapter.addChunk(text);
      reply.write(text);
    }
    // The raw reply is the ground truth when a turn renders oddly. Silent
    // unless something listens at FINE (the live integration test does).
    _log.fine(reply.toString());
  }

  /// Converts a genui [ChatMessage] to firebase_ai content.
  ///
  /// A UI interaction is technically a DataPart with a special MIME type, so
  /// it MUST be checked before the generic DataPart (image) branch.
  static fb.Content _toContent(ChatMessage message) {
    final parts = <fb.Part>[
      for (final part in message.parts)
        if (part.isUiInteractionPart)
          // Structured state from the UI — the loop closing.
          fb.TextPart(part.asUiInteractionPart!.interaction)
        else if (part is TextPart)
          fb.TextPart(part.text)
        else if (part is DataPart)
          fb.InlineDataPart(part.mimeType, part.bytes),
    ];
    return fb.Content('user', parts);
  }
}
