import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart';
import 'package:logging/logging.dart';

import 'package:recipe_genui/agent/surface_check.dart';
import 'package:recipe_genui/agent/transport_decorators.dart';
import 'package:recipe_genui/chat/error_messages.dart';
import 'package:recipe_genui/chat/transcript.dart';
import 'package:recipe_genui/chat/ui_submissions.dart';

/// A photo attached to a message.
typedef ImageAttachment = ({Uint8List bytes, String mimeType});

/// One conversation with Sage: the genui loop, plus the transcript the UI
/// renders.
///
/// It owns the [SurfaceController] / [Conversation] pair, decides when a
/// generated surface is complete enough to show, asks the model to repair the
/// ones that aren't, and turns protocol traffic into [TranscriptEntry]s. It
/// has no Flutter UI and takes its model connection as a [Transport], so it
/// can be tested with a fake.
final class SageSession extends ChangeNotifier {
  SageSession({required Transport transport, required Catalog catalog})
    : _catalog = catalog {
    _glitches = GlitchInjector(transport);
    _transport = ObservedTransport(_glitches);
    surfaces = SurfaceController(catalogs: [catalog]);
    _conversation = Conversation(controller: surfaces, transport: _transport);
    _subscriptions.addAll([
      _conversation.events.listen(_onEvent),
      surfaces.onSubmit.listen(_onSubmit),
    ]);
    _transport.busy.addListener(_onBusyChanged);
  }

  /// Repair requests the app sends per user turn before giving up, so a model
  /// that keeps sending broken UI can't loop forever.
  static const int maxRepairsPerTurn = 2;

  static final Logger _log = Logger('SageSession');

  final Catalog _catalog;

  late final GlitchInjector _glitches;
  late final ObservedTransport _transport;
  late final Conversation _conversation;

  /// The engine holding every generated surface's state.
  late final SurfaceController surfaces;

  /// The recipe the user last opened, highlighted across the transcript.
  final ValueNotifier<String?> selectedRecipeId = ValueNotifier(null);

  final List<StreamSubscription<Object?>> _subscriptions = [];
  final List<TranscriptEntry> _entries = [];

  /// Surfaces the model created that aren't shown yet, in creation order.
  final Set<String> _pendingSurfaces = {};
  final Set<String> _repairRequested = {};
  int _repairsThisTurn = 0;
  int? _openRepairNoticeId;
  int _nextEntryId = 0;
  bool _disposed = false;

  List<TranscriptEntry> get entries => UnmodifiableListView(_entries);

  /// True while the model is working on a request.
  bool get isBusy => _transport.busy.value;

  /// Whether the next model reply will be broken on purpose (demo tool).
  bool get nextReplyBreaks => _glitches.isArmed;

  /// The A2UI messages that built [surfaceId], as JSON.
  List<JsonMap> protocolFor(String surfaceId) =>
      _transport.messagesFor(surfaceId);

  /// Sends what the user typed (and an optional photo) to the model.
  Future<void> send(String text, {ImageAttachment? image}) async {
    final trimmed = text.trim();
    if (isBusy || (trimmed.isEmpty && image == null)) return;
    _repairsThisTurn = 0;
    _add((id) => UserMessage(id, text: trimmed, image: image?.bytes));
    notifyListeners();
    await _conversation.sendRequest(
      ChatMessage.user(
        trimmed,
        parts: [
          if (image != null) DataPart(image.bytes, mimeType: image.mimeType),
        ],
      ),
    );
  }

  /// Demo tool: the next reply that has nested components loses one, so the
  /// self-healing loop can be shown on demand.
  void breakNextReply() {
    _glitches.armOnce();
    notifyListeners();
  }

  void _onEvent(ConversationEvent event) {
    switch (event) {
      case ConversationSurfaceAdded(:final surfaceId):
        // Held back until the turn ends; see _finishTurn.
        _pendingSurfaces.add(surfaceId);
      case ConversationComponentsUpdated(:final surfaceId):
        _resurface(surfaceId);
      case ConversationContentReceived(:final text):
        _appendAssistantText(text);
      case ConversationError(:final error, :final stackTrace):
        _log.warning('Model request failed', error, stackTrace);
        _add(
          (id) =>
              ErrorNotice(id, message: describeError(error), details: '$error'),
        );
        notifyListeners();
      default:
        break;
    }
  }

  /// A2UI lets a model answer by updating a surface it showed in an earlier
  /// turn instead of creating a new one. In a chat that would change content
  /// above the user's latest message, so the surface moves: it leaves its old
  /// place now and is shown again, complete, at the end when the turn ends.
  void _resurface(String surfaceId) {
    final index = _entries.indexWhere(
      (entry) => entry is AssistantSurface && entry.surfaceId == surfaceId,
    );
    if (index == -1) return; // not shown yet: still this turn's own surface
    _entries.removeAt(index);
    _pendingSurfaces.add(surfaceId);
    _repairRequested.remove(surfaceId); // it's new content; check it afresh
    notifyListeners();
  }

  void _appendAssistantText(String chunk) {
    final last = _entries.lastOrNull;
    if (last is AssistantText) {
      // Since genui 0.10.2 chunks keep their whitespace: concatenate as-is.
      _entries.last = last.append(chunk);
    } else if (chunk.trim().isNotEmpty) {
      _add((id) => AssistantText(id, chunk.trimLeft()));
    } else {
      return;
    }
    notifyListeners();
  }

  void _onSubmit(ChatMessage message) {
    for (final submission in UiSubmission.parse(message)) {
      switch (submission) {
        case ActionSubmission(:final summary?, :final payload):
          _repairsThisTurn = 0;
          _add((id) => UserAction(id, summary: summary, payload: payload));
        case ActionSubmission():
          _repairsThisTurn = 0;
        case ErrorSubmission(:final surfaceId):
          // genui (or _finishTurn) just reported broken UI to the model, and
          // the Conversation is already sending it. Show that it's happening,
          // and don't report the same surface a second time.
          if (surfaceId != null) _repairRequested.add(surfaceId);
          _openRepairNoticeId ??= _add(RepairNotice.new).id;
      }
    }
    notifyListeners();
  }

  void _onBusyChanged() {
    notifyListeners();
    // The final chunks may still be in the parser's stream pipeline; a
    // zero-delay timer runs after those queued microtasks have drained.
    if (!isBusy) Timer.run(_finishTurn);
  }

  /// Shows this turn's surfaces now that the model has finished.
  ///
  /// Rendering mid-stream is risky: a model may send a Column before the
  /// children it lists, so genui would draw red fallback boxes and fire an
  /// error request at the model while it is still answering. A surface that
  /// is still missing components stays hidden, and the model gets a precise
  /// error naming them — genui's own report would only say INTERNAL_ERROR.
  void _finishTurn() {
    if (_disposed || isBusy) return;
    var revealed = false;
    var repairRequested = false;
    for (final surfaceId in _pendingSurfaces.toList()) {
      final problem = _problemWith(surfaceId);
      if (problem == null) {
        _pendingSurfaces.remove(surfaceId);
        _add((id) => AssistantSurface(id, surfaceId));
        revealed = true;
      } else if (_repairsThisTurn < maxRepairsPerTurn &&
          _repairRequested.add(surfaceId)) {
        _repairsThisTurn++;
        repairRequested = true;
        _requestRepair(surfaceId, problem);
      }
    }

    final noticeId = _openRepairNoticeId;
    if (noticeId != null && !repairRequested) {
      _openRepairNoticeId = null;
      _replace(noticeId, (entry) {
        return (entry as RepairNotice).resolved(fixed: revealed);
      });
    }
    notifyListeners();
  }

  /// Why [surfaceId] can't be rendered as sent, in words the model can act
  /// on, or null when it's complete.
  String? _problemWith(String surfaceId) {
    final definition = surfaces.contextFor(surfaceId).definition.value;
    if (definition == null) return 'Surface "$surfaceId" has no components.';
    final missing = missingComponentIds(definition);
    final unknown = unknownComponentTypes(definition, _catalog);
    if (missing.isEmpty && unknown.isEmpty) return null;
    return [
      if (missing.isNotEmpty)
        'Surface "$surfaceId" references components that were never sent: '
            '${missing.join(', ')}. Every id used as a child must be defined '
            'in updateComponents.',
      if (unknown.isNotEmpty)
        'Surface "$surfaceId" uses component types that are not in the '
            'catalog: ${unknown.join(', ')}. Use only: '
            '${_catalog.items.map((i) => i.name).join(', ')}.',
      'Send a complete new surface.',
    ].join(' ');
  }

  void _requestRepair(String surfaceId, String problem) {
    _log.info('Asking for a rebuild: $problem');
    surfaces.reportError(
      A2uiValidationException(problem, surfaceId: surfaceId),
      StackTrace.current,
    );
  }

  /// Appends an entry built with the next id, without notifying.
  TranscriptEntry _add(TranscriptEntry Function(int id) create) {
    final entry = create(_nextEntryId++);
    _entries.add(entry);
    return entry;
  }

  void _replace(int id, TranscriptEntry Function(TranscriptEntry) update) {
    final index = _entries.lastIndexWhere((entry) => entry.id == id);
    if (index != -1) _entries[index] = update(_entries[index]);
  }

  @override
  void dispose() {
    _disposed = true;
    _transport.busy.removeListener(_onBusyChanged);
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _conversation.dispose();
    _transport.dispose(); // disposes the whole decorator chain
    surfaces.dispose();
    selectedRecipeId.dispose();
    super.dispose();
  }
}
