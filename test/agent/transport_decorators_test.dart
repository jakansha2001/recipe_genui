import 'dart:async';

import 'package:a2ui_core/a2ui_core.dart' as core;
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

import 'package:recipe_genui/agent/transport_decorators.dart';

import '../support/fake_model.dart';

void main() {
  group('ObservedTransport', () {
    test('records the messages that built each surface', () async {
      final model = FakeModel([
        [
          A2ui.surface('s1', [
            {'id': 'root', 'component': 'Text', 'text': 'Hi'},
          ]),
        ],
      ]);
      final transport = ObservedTransport(model.transport);
      final received = <core.A2uiMessage>[];
      transport.incomingMessages.listen(received.add);

      await transport.sendRequest(ChatMessage.user('hi'));
      await settle();

      expect(received, hasLength(2));
      final log = transport.messagesFor('s1');
      expect(log.map((m) => m.keys), [
        contains('createSurface'),
        contains('updateComponents'),
      ]);
      expect(transport.messagesFor('unknown'), isEmpty);
      transport.dispose();
    });

    test('is busy until every request in flight has finished', () async {
      final first = Completer<void>();
      final second = Completer<void>();
      final pending = [first, second];
      final transport = ObservedTransport(
        A2uiTransportAdapter(onSend: (_) => pending.removeAt(0).future),
      );

      final a = transport.sendRequest(ChatMessage.user('a'));
      final b = transport.sendRequest(ChatMessage.user('b'));
      expect(transport.busy.value, isTrue);

      first.complete();
      await a;
      expect(transport.busy.value, isTrue, reason: 'b is still running');

      second.complete();
      await b;
      expect(transport.busy.value, isFalse);
      transport.dispose();
    });
  });

  group('GlitchInjector', () {
    final column = {
      'id': 'root',
      'component': 'Column',
      'children': ['a', 'b'],
    };
    final a = {'id': 'a', 'component': 'Text', 'text': 'A'};
    final b = {'id': 'b', 'component': 'Text', 'text': 'B'};

    Future<List<List<String>>> componentIdsSeen(
      GlitchInjector injector,
      FakeModel model,
    ) async {
      final seen = <List<String>>[];
      injector.incomingMessages.listen((message) {
        if (message is core.UpdateComponentsMessage) {
          seen.add([for (final c in message.components) c['id']! as String]);
        }
      });
      await injector.sendRequest(ChatMessage.user('1'));
      await injector.sendRequest(ChatMessage.user('2'));
      await settle();
      return seen;
    }

    test('passes messages through untouched when not armed', () async {
      final model = FakeModel([
        [
          A2ui.components('s1', [column, a, b]),
        ],
        [
          A2ui.components('s2', [column, a, b]),
        ],
      ]);
      final injector = GlitchInjector(model.transport);
      expect(await componentIdsSeen(injector, model), [
        ['root', 'a', 'b'],
        ['root', 'a', 'b'],
      ]);
      injector.dispose();
    });

    test('drops one child from the next reply only', () async {
      final model = FakeModel([
        [
          A2ui.components('s1', [column, a, b]),
        ],
        [
          A2ui.components('s2', [column, a, b]),
        ],
      ]);
      final injector = GlitchInjector(model.transport)..armOnce();
      expect(await componentIdsSeen(injector, model), [
        ['root', 'a'],
        ['root', 'a', 'b'],
      ]);
      expect(injector.isArmed, isFalse);
      injector.dispose();
    });

    test('stays armed through replies without children', () async {
      final model = FakeModel([
        [
          A2ui.components('s1', [
            {'id': 'root', 'component': 'Text', 'text': 'solo'},
          ]),
        ],
        [
          A2ui.components('s2', [column, a, b]),
        ],
      ]);
      final injector = GlitchInjector(model.transport)..armOnce();
      expect(await componentIdsSeen(injector, model), [
        ['root'],
        ['root', 'a'],
      ]);
      injector.dispose();
    });
  });
}
