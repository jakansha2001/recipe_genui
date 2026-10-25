import 'dart:async';

import 'package:a2ui_core/a2ui_core.dart' as core;
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart';

import 'package:recipe_genui/agent/surface_check.dart';

/// A [Transport] that wraps another and can observe or rewrite the A2UI
/// messages flowing in from the model. Text and requests pass straight through.
///
/// It subscribes to [inner] once and re-broadcasts, so [onMessage] runs once
/// per message no matter how many listeners there are.
abstract base class TransportDecorator implements Transport {
  TransportDecorator(this.inner) {
    _subscription = inner.incomingMessages.listen((message) {
      final forwarded = onMessage(message);
      if (forwarded != null) _messages.add(forwarded);
    }, onError: _messages.addError);
  }

  final Transport inner;
  final StreamController<core.A2uiMessage> _messages =
      StreamController.broadcast();
  late final StreamSubscription<core.A2uiMessage> _subscription;

  /// Returns the message to forward — [message] itself, a rewritten copy, or
  /// null to drop it.
  @protected
  core.A2uiMessage? onMessage(core.A2uiMessage message);

  @override
  Stream<String> get incomingText => inner.incomingText;

  @override
  Stream<core.A2uiMessage> get incomingMessages => _messages.stream;

  @override
  Future<void> sendRequest(ChatMessage message) => inner.sendRequest(message);

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    unawaited(_messages.close());
    inner.dispose();
  }
}

/// The session's view of the wire: which A2UI messages built each surface
/// (for the protocol peek), and whether a request is still in flight.
///
/// [busy] is tracked here rather than read from `Conversation.state` because
/// genui can send a second request (an error report) while the first is still
/// streaming; `Conversation` then reports idle when the *first* one ends.
/// Counting requests at the transport is exact.
final class ObservedTransport extends TransportDecorator {
  ObservedTransport(super.inner);

  final Map<String, List<Map<String, Object?>>> _bySurface = {};
  final ValueNotifier<bool> _busy = ValueNotifier(false);
  int _inFlight = 0;

  /// True while any request to the model is in flight.
  ValueListenable<bool> get busy => _busy;

  /// The A2UI messages (as JSON) the renderer received for [surfaceId].
  List<Map<String, Object?>> messagesFor(String surfaceId) =>
      UnmodifiableListView(_bySurface[surfaceId] ?? const []);

  @override
  core.A2uiMessage onMessage(core.A2uiMessage message) {
    final surfaceId = _surfaceIdOf(message);
    if (surfaceId != null) {
      _bySurface.putIfAbsent(surfaceId, () => []).add(message.toJson());
    }
    return message;
  }

  @override
  Future<void> sendRequest(ChatMessage message) async {
    _inFlight++;
    _busy.value = true;
    try {
      await super.sendRequest(message);
    } finally {
      _inFlight--;
      _busy.value = _inFlight > 0;
    }
  }

  @override
  void dispose() {
    _busy.dispose();
    super.dispose();
  }

  static String? _surfaceIdOf(core.A2uiMessage message) => switch (message) {
    core.CreateSurfaceMessage(:final surfaceId) => surfaceId,
    core.UpdateComponentsMessage(:final surfaceId) => surfaceId,
    core.UpdateDataModelMessage(:final surfaceId) => surfaceId,
    core.DeleteSurfaceMessage(:final surfaceId) => surfaceId,
    _ => null,
  };
}

/// A demo tool: breaks the next model reply on purpose, so the self-healing
/// loop can be shown on demand instead of waiting for a real model mistake.
///
/// When armed, it drops one child component from the next `updateComponents`
/// that has any — the same mistake models occasionally make.
final class GlitchInjector extends TransportDecorator {
  GlitchInjector(super.inner);

  bool _armed = false;

  bool get isArmed => _armed;

  /// Breaks the next reply that contains a parent with children.
  void armOnce() => _armed = true;

  @override
  core.A2uiMessage onMessage(core.A2uiMessage message) {
    if (!_armed || message is! core.UpdateComponentsMessage) return message;
    final referenced = message.components.expand(childComponentIds).toSet();
    final victim = message.components.lastWhereOrNull(
      (component) => referenced.contains(component['id']),
    );
    if (victim == null) return message; // nothing to break yet; stay armed
    _armed = false;
    return core.UpdateComponentsMessage(
      version: message.version,
      surfaceId: message.surfaceId,
      components: [
        for (final component in message.components)
          if (!identical(component, victim)) component,
      ],
    );
  }
}
