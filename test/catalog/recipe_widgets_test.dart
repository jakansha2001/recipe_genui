import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

import 'package:recipe_genui/chat/sage_session.dart';

import '../support/fake_model.dart';

void main() {
  late FakeModel model;
  late SageSession session;

  setUp(() {
    model = FakeModel();
    session = sessionWith(model);
  });

  tearDown(() => session.dispose());

  /// Has the fake model answer one turn with [reply], then renders [surfaceId].
  Future<void> show(WidgetTester tester, String surfaceId, String reply) async {
    model.reply([reply]);
    await tester.runAsync(() => session.send('go'));
    await tester.pumpSurface(session, surfaceId);
  }

  group('RecipeCard', () {
    testWidgets('shows facts from our data and words from the model', (
      tester,
    ) async {
      await show(
        tester,
        's1',
        A2ui.surface('s1', [
          {
            'id': 'root',
            'component': 'RecipeCard',
            'recipeId': 'paneer_bhurji',
            'reason': 'Ready in 15 minutes with your paneer.',
          },
        ]),
      );
      expect(find.text('Paneer Bhurji'), findsOneWidget); // ours
      expect(find.text('15 min'), findsOneWidget); // ours
      expect(
        find.text('Ready in 15 minutes with your paneer.'),
        findsOneWidget,
      );
    });

    testWidgets('tapping it sends a viewRecipe action back to the model', (
      tester,
    ) async {
      await show(
        tester,
        's1',
        A2ui.surface('s1', [
          {'id': 'root', 'component': 'RecipeCard', 'recipeId': 'dal_tadka'},
        ]),
      );
      await tester.tap(find.text('View recipe'));
      await tester.settleModel();

      expect(model.interactions.single, contains('"name":"viewRecipe"'));
      expect(model.interactions.single, contains('"recipeId":"dal_tadka"'));
    });

    testWidgets('resolves props sent as data bindings', (tester) async {
      await show(
        tester,
        's1',
        A2ui.surface(
          's1',
          [
            {
              'id': 'root',
              'component': 'RecipeCard',
              'recipeId': {'path': '/pick'},
              'reason': {'path': '/why'},
            },
          ],
          data: {'/pick': 'dal_tadka', '/why': 'Comforting and quick.'},
        ),
      );
      expect(find.byType(FallbackWidget), findsNothing);
      expect(find.text('Dal Tadka'), findsOneWidget);
      expect(find.text('Comforting and quick.'), findsOneWidget);
    });

    testWidgets('an id we do not own fails visibly', (tester) async {
      await show(
        tester,
        's1',
        A2ui.surface('s1', [
          {'id': 'root', 'component': 'RecipeCard', 'recipeId': 'burger'},
        ]),
      );
      expect(find.text('Unknown recipe: "burger"'), findsOneWidget);
    });
  });

  group('RecipeView', () {
    Future<void> showPaneerBhurji(
      WidgetTester tester, {
      Object? servings,
      Map<String, Object?> data = const {},
      Map<String, Object?> extra = const {},
    }) => show(
      tester,
      's1',
      A2ui.surface('s1', [
        {
          'id': 'root',
          'component': 'RecipeView',
          'recipeId': 'paneer_bhurji', // serves 2 with 200 g paneer
          'servings': ?servings,
          ...extra,
        },
      ], data: data),
    );

    Future<void> tapStepper(WidgetTester tester, String tooltip) async {
      final button = find.byTooltip(tooltip);
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.settleModel();
    }

    testWidgets('uses the recipe base servings when none is bound', (
      tester,
    ) async {
      await showPaneerBhurji(tester);
      expect(find.text('200 g'), findsOneWidget);
    });

    testWidgets('scales amounts to the servings in the data model', (
      tester,
    ) async {
      await showPaneerBhurji(
        tester,
        servings: {'path': '/servings'},
        data: {'/servings': 4},
      );
      expect(find.text('400 g'), findsOneWidget);
      expect(find.text('2'), findsWidgets); // 1 onion x 2
    });

    testWidgets('the stepper rescales on the device without a model call', (
      tester,
    ) async {
      await showPaneerBhurji(
        tester,
        servings: {'path': '/servings'},
        data: {'/servings': 2},
      );
      final requestsBefore = model.requests.length;

      await tapStepper(tester, 'More servings');

      expect(find.text('300 g'), findsOneWidget);
      final servings = session.surfaces
          .contextFor('s1')
          .dataModel
          .getValue<Object?>(DataPath('/servings'));
      expect(servings, 3, reason: 'the stepper writes the bound path');
      expect(model.requests.length, requestsBefore, reason: 'no model call');
    });

    testWidgets('a literal servings value still lets the user change it', (
      tester,
    ) async {
      await showPaneerBhurji(tester, servings: 4);
      expect(find.text('400 g'), findsOneWidget);
      await tapStepper(tester, 'Fewer servings');
      expect(find.text('300 g'), findsOneWidget);
    });

    testWidgets('uses adapted steps and a note from the model', (tester) async {
      await showPaneerBhurji(
        tester,
        extra: {
          'steps': ['Mash by hand.', 'Cook gently.'],
          'note': 'Skipped the blender.',
        },
      );
      expect(find.text('Mash by hand.'), findsOneWidget);
      expect(find.text('Skipped the blender.'), findsOneWidget);
    });

    testWidgets('falls back to our steps when steps have the wrong type', (
      tester,
    ) async {
      await showPaneerBhurji(tester, extra: {'steps': 'Mash it. Cook it.'});
      expect(find.byType(FallbackWidget), findsNothing);
      expect(
        find.text('Crumble the paneer with your hands and set aside.'),
        findsOneWidget,
      );
    });

    testWidgets('adjusting sends the request and the current servings', (
      tester,
    ) async {
      await showPaneerBhurji(
        tester,
        servings: {'path': '/servings'},
        data: {'/servings': 5},
      );
      final chip = find.text('No blender');
      await tester.ensureVisible(chip);
      await tester.tap(chip);
      await tester.settleModel();

      final action = model.interactions.last;
      expect(action, contains('"name":"adjustRecipe"'));
      expect(action, contains('"adjustment":"no blender"'));
      expect(action, contains('"servings":5'));
    });
  });
}
