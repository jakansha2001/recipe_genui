import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:recipe_genui/catalog/recipe_catalog.dart';
import 'package:recipe_genui/catalog/recipe_prompts.dart';
import 'package:recipe_genui/chat/sage_session.dart';

import '../support/fake_model.dart';

/// The prompt teaches the model exact JSON for the gather step. These tests
/// render that same JSON through genui, so a typo in the prompt fails here
/// instead of on stage.
void main() {
  late FakeModel model;
  late SageSession session;

  setUp(() {
    model = FakeModel();
    session = sessionWith(model);
  });

  tearDown(() => session.dispose());

  /// The servings part of the gather surface, built only from the prompt's
  /// own snippets.
  Future<void> showGatherSurface(WidgetTester tester) async {
    final checks = jsonDecode(RecipePrompts.servingsChecks);
    model.reply([
      A2ui.surface(
        's1',
        [
          {
            'id': 'root',
            'component': 'Column',
            'children': ['people', 'caption', 'submit'],
          },
          {
            'id': 'people',
            'component': 'TextField',
            'label': 'How many people?',
            'variant': 'number',
            'value': {'path': '/servings'},
            'checks': checks,
          },
          {
            'id': 'caption',
            'component': 'Text',
            'text': jsonDecode(RecipePrompts.servingsCaption),
          },
          {
            'id': 'submit',
            'component': 'Button',
            'variant': 'primary',
            'child': 'submitLabel',
            'checks': checks,
            'action': {
              'event': {
                'name': 'findRecipes',
                'context': {
                  'servings': {'path': '/servings'},
                },
              },
            },
          },
          {'id': 'submitLabel', 'component': 'Text', 'text': 'Find recipes'},
        ],
        data: {'/servings': 2},
      ),
    ]);
    await tester.runAsync(() => session.send('dinner'));
    await tester.pumpSurface(session, 's1');
  }

  Future<void> typeServings(WidgetTester tester, String value) async {
    await tester.enterText(find.byType(TextField), value);
    await tester.settleModel();
  }

  bool submitEnabled(WidgetTester tester) =>
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed !=
      null;

  testWidgets('formatString + pluralize render on the device', (tester) async {
    await showGatherSurface(tester);
    expect(find.text('Cooking for 2 people'), findsOneWidget);

    await typeServings(tester, '1');
    expect(find.text('Cooking for 1 person'), findsOneWidget);
    expect(
      model.requests,
      hasLength(1),
      reason: 'typing never calls the model',
    );
  });

  testWidgets('checks keep submit disabled until the number is valid', (
    tester,
  ) async {
    await showGatherSurface(tester);
    expect(submitEnabled(tester), isTrue);

    await typeServings(tester, '20');
    expect(submitEnabled(tester), isFalse);

    await typeServings(tester, '');
    expect(submitEnabled(tester), isFalse);

    await typeServings(tester, '4');
    expect(submitEnabled(tester), isTrue);
  });

  testWidgets('submit sends the servings from the data model', (tester) async {
    await showGatherSurface(tester);
    await typeServings(tester, '3');
    await tester.tap(find.byType(ElevatedButton));
    await tester.settleModel();

    expect(model.interactions.last, contains('"servings":3'));
  });

  test('the system instruction carries rules, catalog and recipe menu', () {
    expect(recipeSystemInstruction, contains('createSurface'));
    expect(recipeSystemInstruction, contains('RecipeCard'));
    expect(recipeSystemInstruction, contains('RecipeView'));
    expect(recipeSystemInstruction, contains('paneer_bhurji'));
    expect(recipeSystemInstruction, contains('pluralize'));
    expect(recipeSystemInstruction, contains(recipeCatalog.catalogId));
  });
}
