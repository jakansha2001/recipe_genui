import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:recipe_genui/app/sage_app.dart';
import 'package:recipe_genui/chat/sage_session.dart';
import 'package:recipe_genui/ui/widgets/branding.dart';

import '../support/fake_model.dart';

void main() {
  // Fonts aren't bundled; don't let tests reach for the network.
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  late FakeModel model;
  late SageSession session;

  Future<void> pumpApp(WidgetTester tester) async {
    model = FakeModel();
    await tester.pumpWidget(
      SageApp(createSession: () => session = sessionWith(model)),
    );
    await tester.pump();
  }

  /// The page creates its session inside the test's fake-async zone, so the
  /// fake model's stream hops and the session's timers advance with the fake
  /// clock: pump it forward until the turn has fully played out.
  Future<void> drain(WidgetTester tester) async {
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
  }

  Future<void> ask(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.tap(find.bySemanticsLabel('Send'));
    await drain(tester);
  }

  testWidgets('starts on the welcome screen', (tester) async {
    await pumpApp(tester);
    expect(find.text('What should we cook?'), findsOneWidget);
    for (final prompt in starterPrompts) {
      expect(find.text(prompt), findsOneWidget);
    }
  });

  testWidgets('a starter prompt is sent with one tap', (tester) async {
    await pumpApp(tester);
    model.reply(['On it.']);
    await tester.tap(find.text(starterPrompts.first));
    await drain(tester);

    expect(model.requests, hasLength(1));
    expect(find.text(starterPrompts.first), findsOneWidget); // now a bubble
    expect(find.text('On it.'), findsOneWidget);
  });

  testWidgets('photo credits list every recipe', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byTooltip('Photo credits'));
    await tester.pumpAndSettle();

    expect(find.text('Photo credits'), findsWidgets);
    expect(find.text('Paneer Bhurji'), findsOneWidget);
    expect(find.textContaining('CC BY-SA 4.0'), findsWidgets);
  });

  testWidgets('a reply shows the user message, text and generated UI', (
    tester,
  ) async {
    await pumpApp(tester);
    model.reply([
      'Try this:\n',
      A2ui.surface('s1', [
        {'id': 'root', 'component': 'RecipeCard', 'recipeId': 'poha'},
      ]),
    ]);

    await ask(tester, 'Something light');

    expect(find.text('Something light'), findsOneWidget);
    expect(find.text('Try this:'), findsOneWidget);
    expect(find.text('Poha'), findsOneWidget);
    expect(find.text('What should we cook?'), findsNothing);
  });

  testWidgets('the protocol toggle reveals the A2UI behind a surface', (
    tester,
  ) async {
    await pumpApp(tester);
    model.reply([
      A2ui.surface('s1', [
        {'id': 'root', 'component': 'RecipeCard', 'recipeId': 'poha'},
      ]),
    ]);
    await ask(tester, 'Breakfast');
    expect(find.textContaining('A2UI from model'), findsNothing);

    await tester.tap(find.byTooltip('Show A2UI messages'));
    await tester.pump();
    expect(find.text('A2UI from model · 2 messages'), findsOneWidget);

    await tester.tap(find.text('A2UI from model · 2 messages'));
    await tester.pump();
    expect(find.textContaining('"updateComponents"'), findsOneWidget);
    expect(session.protocolFor('s1'), hasLength(2));
  });

  testWidgets('a reply to an action scrolls into view', (tester) async {
    await pumpApp(tester);
    model
      ..reply([
        A2ui.surface('s1', [
          {
            'id': 'root',
            'component': 'Column',
            'children': ['a', 'b', 'c'],
          },
          {'id': 'a', 'component': 'RecipeCard', 'recipeId': 'poha'},
          {'id': 'b', 'component': 'RecipeCard', 'recipeId': 'upma'},
          {'id': 'c', 'component': 'RecipeCard', 'recipeId': 'dal_tadka'},
        ]),
      ])
      ..reply([
        A2ui.surface('s2', [
          {'id': 'root', 'component': 'RecipeView', 'recipeId': 'poha'},
        ]),
      ]);
    await ask(tester, 'Breakfast');

    // Tap the first card, far above the end of a long transcript.
    await tester.drag(find.byType(ListView), const Offset(0, 2000));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View recipe').first);
    await drain(tester);
    await tester.pumpAndSettle();

    expect(find.byTooltip('More servings'), findsOneWidget);
  });

  testWidgets('the composer is disabled while the model is answering', (
    tester,
  ) async {
    await pumpApp(tester);
    model.reply(['Thinking about it…']);
    await tester.enterText(find.byType(TextField), 'hi');
    await tester.tap(find.bySemanticsLabel('Send'));
    await tester.pump();

    expect(find.text('Thinking…'), findsWidgets);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);

    await drain(tester);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
  });
}
