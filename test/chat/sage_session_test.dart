import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

import 'package:recipe_genui/chat/sage_session.dart';
import 'package:recipe_genui/chat/transcript.dart';

import '../support/fake_model.dart';

void main() {
  late FakeModel model;
  late SageSession session;

  setUp(() {
    model = FakeModel();
    session = sessionWith(model);
  });

  tearDown(() => session.dispose());

  List<Type> kinds() => [for (final e in session.entries) e.runtimeType];

  const card = <String, Object?>{
    'id': 'card',
    'component': 'RecipeCard',
    'recipeId': 'poha',
  };
  const column = <String, Object?>{
    'id': 'root',
    'component': 'Column',
    'children': ['card'],
  };

  group('turns', () {
    test('echoes the user and shows the reply text and surface', () async {
      model.reply([
        'Here are some ',
        'ideas.\n',
        A2ui.surface('s1', [column, card]),
      ]);
      await session.send('  breakfast  ');
      await settle();

      expect(kinds(), [UserMessage, AssistantText, AssistantSurface]);
      expect((session.entries[0] as UserMessage).text, 'breakfast');
      expect(
        (session.entries[1] as AssistantText).text.trim(),
        'Here are some ideas.',
      );
      expect(session.isBusy, isFalse);
    });

    test('ignores empty input and input while busy', () async {
      await session.send('   ');
      expect(session.entries, isEmpty);
      expect(model.requests, isEmpty);
    });

    test('holds a surface back until the model has finished', () async {
      final shown = <List<Type>>[];
      session.addListener(() => shown.add(kinds()));
      model.reply([
        A2ui.createSurface('s1'),
        A2ui.components('s1', [column, card]),
      ]);

      await session.send('go');
      // While the reply streamed, no surface was in the transcript.
      expect(
        shown.where((k) => k.contains(AssistantSurface) && session.isBusy),
        isEmpty,
      );
      await settle();
      expect(kinds().last, AssistantSurface);
    });

    test('echoes surface actions as user bubbles', () async {
      model
        ..reply([
          A2ui.surface('s1', [
            {...card, 'id': 'root'},
          ]),
        ])
        ..reply(const []);
      await session.send('go');
      await settle();

      session.surfaces.handleUiEvent(
        UserActionEvent(
          name: 'viewRecipe',
          sourceComponentId: 'root',
          context: {'recipeId': 'poha', 'title': 'Poha'},
        ),
      );
      await settle();

      final action = session.entries.whereType<UserAction>().single;
      expect(action.summary, 'Selected: Poha');
      expect(action.payload['action'], isA<JsonMap>());
      expect(model.requests, hasLength(2));
    });

    test(
      'a screen updated in a later turn moves below the user action',
      () async {
        // The model may answer by updating an earlier surface in place instead
        // of creating a new one. The reply must still read top to bottom.
        model
          ..reply([
            A2ui.surface('s1', [
              {...card, 'id': 'root'},
            ]),
          ])
          ..reply([
            A2ui.components('s1', [
              {'id': 'root', 'component': 'RecipeView', 'recipeId': 'poha'},
            ]),
          ]);
        await session.send('go');
        await settle();
        session.surfaces.handleUiEvent(
          UserActionEvent(
            name: 'viewRecipe',
            sourceComponentId: 'root',
            context: {'recipeId': 'poha', 'title': 'Poha'},
          ),
        );
        await settle();
        await settle();

        expect(kinds(), [UserMessage, UserAction, AssistantSurface]);
        expect((session.entries.last as AssistantSurface).surfaceId, 's1');
      },
    );

    test('explains failures in plain words', () async {
      final failing = FakeModel();
      final session = SageSession(
        transport: A2uiTransportAdapter(
          onSend: (_) => throw Exception('RESOURCE_EXHAUSTED: quota'),
        ),
        catalog: sessionWith(failing).surfaces.catalogs.first,
      );
      addTearDown(session.dispose);

      await session.send('hi');
      await settle();

      final error = session.entries.whereType<ErrorNotice>().single;
      expect(error.message, contains('a lot of requests'));
      expect(error.details, contains('RESOURCE_EXHAUSTED'));
      expect(session.isBusy, isFalse);
    });
  });

  group('self-healing', () {
    test('hides an incomplete surface and asks for a precise repair', () async {
      model
        ..reply([
          A2ui.surface('s1', [column]),
        ]) // "card" never sent
        ..reply([
          A2ui.surface('s2', [column, card]),
        ]); // the repair
      await session.send('go');
      await settle();
      await settle();

      expect(model.requests, hasLength(2));
      final report = model.interactions.single;
      expect(report, contains('VALIDATION_FAILED'));
      expect(report, contains('never sent: card'));

      final surfaces = session.entries.whereType<AssistantSurface>();
      expect(surfaces.map((s) => s.surfaceId), [
        's2',
      ], reason: 's1 stays hidden');
      expect(
        session.entries.whereType<RepairNotice>().single.status,
        RepairStatus.fixed,
      );
    });

    test('marks the repair failed when the model cannot fix it', () async {
      model
        ..reply([
          A2ui.surface('s1', [column]),
        ])
        ..reply(['Sorry, I could not do that.']);
      await session.send('go');
      await settle();
      await settle();

      expect(
        session.entries.whereType<RepairNotice>().single.status,
        RepairStatus.failed,
      );
    });

    test('hides a component type the catalog lacks, reported once', () async {
      // Seen live: the model wrote a recipe id where "RecipeCard" belongs.
      // genui reports it to the model itself; the app hides the broken
      // surface and doesn't send a second, duplicate report.
      model
        ..reply([
          A2ui.surface('s1', [
            {'id': 'root', 'component': 'tomato_paneer_masala'},
          ]),
        ])
        ..reply([
          A2ui.surface('s2', [column, card]),
        ]);
      await session.send('go');
      await settle();
      await settle();

      expect(model.requests, hasLength(2));
      expect(model.interactions.single, contains('tomato_paneer_masala'));
      expect(
        session.entries.whereType<RepairNotice>().single.status,
        RepairStatus.fixed,
      );
      expect(
        session.entries.whereType<AssistantSurface>().map((s) => s.surfaceId),
        ['s2'],
      );
    });

    test('gives up after a bounded number of repairs per turn', () async {
      for (var i = 1; i <= SageSession.maxRepairsPerTurn + 2; i++) {
        model.reply([
          A2ui.surface('s$i', [column]),
        ]); // always broken
      }
      await session.send('go');
      for (var i = 0; i < SageSession.maxRepairsPerTurn + 3; i++) {
        await settle();
      }

      expect(model.requests, hasLength(1 + SageSession.maxRepairsPerTurn));
      expect(session.entries.whereType<AssistantSurface>(), isEmpty);
    });

    test('the demo glitch triggers the same repair loop', () async {
      model
        ..reply([
          A2ui.surface('s1', [column, card]),
        ])
        ..reply([
          A2ui.surface('s2', [column, card]),
        ]);
      session.breakNextReply();
      expect(session.nextReplyBreaks, isTrue);

      await session.send('go');
      await settle();
      await settle();

      expect(session.nextReplyBreaks, isFalse);
      expect(model.interactions.single, contains('never sent: card'));
      expect(
        session.entries.whereType<AssistantSurface>().map((s) => s.surfaceId),
        ['s2'],
      );
      expect(
        session.entries.whereType<RepairNotice>().single.status,
        RepairStatus.fixed,
      );
    });
  });

  test('records the protocol behind each surface', () async {
    model.reply([
      A2ui.surface('s1', [column, card]),
    ]);
    await session.send('go');
    await settle();

    final messages = session.protocolFor('s1');
    expect(messages, hasLength(2));
    expect(messages.last['updateComponents'], isA<JsonMap>());
  });
}
