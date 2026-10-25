import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

import 'package:recipe_genui/catalog/recipe_catalog.dart';
import 'package:recipe_genui/chat/sage_session.dart';

/// A scripted stand-in for the model. Each request is answered with the next
/// queued reply, streamed chunk by chunk through the same
/// [A2uiTransportAdapter] the app feeds Gemini's output into.
class FakeModel {
  FakeModel([Iterable<List<String>> replies = const []])
    : _replies = Queue.of(replies);

  final Queue<List<String>> _replies;

  /// Every request the app sent, in order.
  final List<ChatMessage> requests = [];

  late final A2uiTransportAdapter transport = A2uiTransportAdapter(
    onSend: _answer,
  );

  void reply(List<String> chunks) => _replies.add(chunks);

  /// The UI interaction payloads (actions and error reports) sent so far.
  List<String> get interactions => [
    for (final request in requests)
      for (final part in request.parts)
        if (part.isUiInteractionPart) part.asUiInteractionPart!.interaction,
  ];

  Future<void> _answer(ChatMessage message) async {
    requests.add(message);
    final chunks = _replies.isEmpty ? const <String>[] : _replies.removeFirst();
    for (final chunk in chunks) {
      transport.addChunk(chunk);
      await Future<void>.delayed(Duration.zero);
    }
  }
}

/// A2UI v0.9 messages, written the way a model writes them: fenced JSON.
abstract final class A2ui {
  static String createSurface(String surfaceId) => _fenced({
    'createSurface': {
      'surfaceId': surfaceId,
      'catalogId': recipeCatalog.catalogId,
    },
  });

  static String components(String surfaceId, List<JsonMap> components) =>
      _fenced({
        'updateComponents': {'surfaceId': surfaceId, 'components': components},
      });

  static String data(String surfaceId, String path, Object? value) => _fenced({
    'updateDataModel': {'surfaceId': surfaceId, 'path': path, 'value': value},
  });

  /// A whole surface in one reply: create, optional data, components.
  static String surface(
    String surfaceId,
    List<JsonMap> components, {
    Map<String, Object?> data = const {},
  }) => [
    createSurface(surfaceId),
    for (final MapEntry(:key, :value) in data.entries)
      A2ui.data(surfaceId, key, value),
    A2ui.components(surfaceId, components),
  ].join();

  static String _fenced(JsonMap body) =>
      '```json\n${jsonEncode({'version': 'v0.9', ...body})}\n```\n';
}

SageSession sessionWith(FakeModel model) =>
    SageSession(transport: model.transport, catalog: recipeCatalog);

/// Lets streamed replies and the session's turn bookkeeping finish. The
/// streams live in the real zone, so this needs real time, not fake pumps.
Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 30));

extension SettleTester on WidgetTester {
  /// [settle] from inside a widget test, then rebuild.
  Future<void> settleModel() async {
    await runAsync(settle);
    await pump();
  }

  /// Renders one surface of [session] on its own.
  Future<void> pumpSurface(SageSession session, String surfaceId) async {
    await pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Surface(
              surfaceContext: session.surfaces.contextFor(surfaceId),
            ),
          ),
        ),
      ),
    );
    await settleModel();
  }
}
