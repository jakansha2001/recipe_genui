import 'dart:async';

import 'package:firebase_ai/firebase_ai.dart' as fb;
import 'package:genui/genui.dart';

import '../catalog/recipe_catalog.dart';

/// Builds the full system instruction string for the model.
///
/// `PromptBuilder.chat` combines three things: the A2UI format rules (so the
/// model knows HOW to emit UI), our catalog's own prompt fragments (the recipe
/// steering from Step 4), and the framework fragments we pass here (acknowledge
/// the user, always include a submit element, don't generate UI when it isn't
/// useful). `.systemPromptJoined()` flattens it all into one string.
String buildRecipeSystemInstruction() {
  return PromptBuilder.chat(
    catalog: recipeCatalog,
    systemPromptFragments: [
      PromptFragments.acknowledgeUser(),
      PromptFragments.requireAtLeastOneSubmitElement(
        prefix: PromptBuilder.defaultImportancePrefix,
      ),
      PromptFragments.uiGenerationRestriction(
        prefix: PromptBuilder.defaultImportancePrefix,
      ),
    ],
  ).systemPromptJoined();
}

/// The bridge between genui and Firebase AI Logic.
///
/// genui is backend-agnostic: it only needs streamed text chunks fed into an
/// [A2uiTransportAdapter]. That adapter already implements [Transport], so we
/// don't write a Transport ourselves — we just give it an `onSend` callback
/// that calls Gemini (via firebase_ai) and pipes the streamed text back in
/// through `addChunk`. Swapping providers later means changing only this file.
class RecipeBackend {
  RecipeBackend({String modelName = 'gemini-3.1-flash-lite'}) {
    _model = fb.FirebaseAI.googleAI().generativeModel(
      model: modelName,
      // No API key here — Firebase AI Logic holds it. The system instruction
      // carries the A2UI rules + our recipe steering.
      systemInstruction: fb.Content.system(buildRecipeSystemInstruction()),
    );
    _chat = _model.startChat();
    _adapter = A2uiTransportAdapter(onSend: _handleSend);
  }

  late final fb.GenerativeModel _model;
  late final fb.ChatSession _chat;
  late final A2uiTransportAdapter _adapter;

  /// Hand this to a [Conversation] as its transport.
  Transport get transport => _adapter;

  /// Called by genui whenever the user (or a UI interaction) sends a request.
  Future<void> _handleSend(ChatMessage message) async {
    final fb.Content content = _toFirebaseContent(message);
    final Stream<fb.GenerateContentResponse> stream = _chat.sendMessageStream(
      content,
    );
    await for (final fb.GenerateContentResponse response in stream) {
      final String? text = response.text;
      if (text != null && text.isNotEmpty) {
        // Each chunk goes straight into the A2UI parser. The adapter buffers
        // and turns it into surfaces — this is the backend-agnostic seam.
        _adapter.addChunk(text);
      }
    }
  }

  /// Convert a genui [ChatMessage] into a firebase_ai [fb.Content].
  ///
  /// A UI interaction is technically a DataPart with a special MIME type, so it
  /// MUST be checked before the generic image-DataPart branch.
  fb.Content _toFirebaseContent(ChatMessage message) {
    final parts = <fb.Part>[];
    for (final part in message.parts) {
      if (part.isUiInteractionPart) {
        // Structured state coming back from the UI (the loop closing).
        parts.add(fb.TextPart(part.asUiInteractionPart!.interaction));
      } else if (part is TextPart) {
        parts.add(fb.TextPart(part.text));
      } else if (part is DataPart) {
        // e.g. the fridge photo — sent as inline image bytes.
        parts.add(fb.InlineDataPart(part.mimeType, part.bytes));
      }
    }
    return fb.Content('user', parts);
  }

  void dispose() => _adapter.dispose();
}