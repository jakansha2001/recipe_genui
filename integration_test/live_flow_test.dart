// Live end-to-end runs against the real model, driving the real UI.
// Needs network and your Firebase project. This test reinstalls the app, which
// resets its App Check debug token, so pass a registered one (from a secret
// store, never a file) and prefer a simulator you don't use day to day:
//   flutter test integration_test/live_flow_test.dart -d <device-id> \
//     --dart-define=APP_CHECK_DEBUG_TOKEN=<registered token>
// Optional: --dart-define=RUNS=3 repeats the main flow to catch flaky output.
// ignore_for_file: avoid_print
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:integration_test/integration_test.dart';
import 'package:logging/logging.dart';

import 'package:recipe_genui/app/app_check.dart';
import 'package:recipe_genui/app/sage_app.dart';
import 'package:recipe_genui/firebase_options.dart';
import 'package:recipe_genui/main.dart';

const int runs = int.fromEnvironment('RUNS', defaultValue: 1);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // A tap that misses its target should fail loudly, not time out later.
  WidgetController.hitTestWarningShouldBeFatal = true;

  // The model's raw reply for the current turn, printed when a step fails.
  var lastReply = '';
  hierarchicalLoggingEnabled = true;
  Logger('GeminiTransport')
    ..level = Level.FINE
    ..onRecord.listen((r) => lastReply = r.message);
  Logger('SageSession').onRecord.listen((r) => print('[session] ${r.message}'));

  setUpAll(() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await activateAppCheck();
  });

  final problems = <String>[];
  tearDownAll(() {
    print('\n=== render problems: ${problems.length}');
    problems.forEach(print);
    expect(problems, isEmpty);
  });

  Future<_Driver> start(WidgetTester tester, String label) async {
    await tester.pumpWidget(
      SageApp(key: UniqueKey(), createSession: createGeminiSession),
    );
    await tester.pumpAndSettle();
    return _Driver(tester, label, problems, () => lastReply);
  }

  for (var run = 1; run <= runs; run++) {
    testWidgets(
      'run $run: gather -> suggest -> cook -> scale -> adapt',
      (tester) async {
        final app = await start(tester, 'run $run');

        // 1. Gather: plain language in, input UI out.
        await app.ask('Something quick for dinner with paneer');
        await app.waitFor('gather', () => app.has(find.byType(FilterChip)));
        expect(find.text('View recipe'), findsNothing); // no recipes yet
        await app.setServingsIfAsked('3');
        app.checkRendering('gather');

        // 2. Suggest.
        await app.tap(find.byType(ElevatedButton).last);
        await app.waitFor(
          'suggest',
          () => app.count(find.text('View recipe')) >= 2,
        );
        app.checkRendering('suggest');

        // 3. Cook: open the card that's on screen.
        await app.tap(find.text('View recipe').last);
        await app.waitFor(
          'cook',
          () => app.has(find.byTooltip('More servings')),
        );
        app.checkRendering('cook');

        // 4. Scale on the device: amounts change, the model is not called.
        await app.expectLocalServingsChange();

        // 5. Adapt: a new RecipeView arrives with an adaptation note. (The
        // earlier view may have scrolled out of the lazily built list.)
        await app.tap(find.text('No blender').last);
        await app.waitFor(
          'adapt',
          () => app.has(find.byIcon(Icons.auto_awesome)),
        );
        app.checkRendering('adapt');
      },
      timeout: const Timeout(Duration(minutes: 6)),
    );
  }

  testWidgets(
    'self-healing: a broken reply is detected and rebuilt',
    (tester) async {
      final app = await start(tester, 'healing');
      await app.ask('Something quick for dinner with paneer');
      await app.waitFor('gather', () => app.has(find.byType(FilterChip)));

      // Break the next reply (the suggestions), then submit.
      await app.tap(find.byTooltip('Break the next reply (demo)'));
      await app.tap(find.byType(ElevatedButton).last);
      await app.waitFor(
        'repair resolved',
        () =>
            app.has(find.textContaining('Rebuilt')) ||
            app.has(find.textContaining("couldn't rebuild")),
      );
      expect(find.textContaining('Rebuilt'), findsOneWidget);
      expect(app.count(find.text('View recipe')), greaterThanOrEqualTo(1));
      app.checkRendering('healed');
    },
    timeout: const Timeout(Duration(minutes: 6)),
  );
}

/// Drives the real app like a user, on real time.
class _Driver {
  _Driver(this.tester, this.label, this.problems, this.lastReply);

  final WidgetTester tester;
  final String label;
  final List<String> problems;
  final String Function() lastReply;

  bool has(Finder finder) => finder.evaluate().isNotEmpty;
  int count(Finder finder) => finder.evaluate().length;
  bool get busy => has(find.text('Thinking…'));

  Future<void> wait(Duration duration) async {
    await tester.runAsync(() => Future<void>.delayed(duration));
    await tester.pump();
  }

  Future<void> ask(String text) async {
    await tester.enterText(find.byType(TextField).last, text);
    await tester.tap(find.bySemanticsLabel('Send'));
    await tester.pump();
  }

  /// Scrolls [finder] to the middle of the screen (the top edge can sit under
  /// the app bar), then taps it.
  Future<void> tap(Finder finder) async {
    await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pump();
  }

  /// Waits on real time until the model is idle and [done] holds.
  Future<void> waitFor(String step, bool Function() done) async {
    final watch = Stopwatch()..start();
    while (watch.elapsed < const Duration(seconds: 90)) {
      await wait(const Duration(milliseconds: 300));
      if (!busy && done()) {
        print('✓ $label: $step in ${watch.elapsed.inMilliseconds} ms');
        return;
      }
    }
    print('--- last model reply ---\n${lastReply()}\n---');
    fail('$label: timed out waiting for $step');
  }

  /// Fills "How many people?" if the model built it, and checks the device
  /// computed the caption (built-in formatString + pluralize).
  Future<void> setServingsIfAsked(String value) async {
    final field = find.descendant(
      of: find.byType(Surface),
      matching: find.byType(TextField),
    );
    if (!has(field)) {
      print('· $label: no servings field this time');
      return;
    }
    await tester.enterText(field.first, value);
    await wait(const Duration(milliseconds: 300));
    final caption = has(find.textContaining('Cooking for $value'));
    print('· $label: servings caption computed on device: $caption');
  }

  /// Taps "More servings" and checks the amounts changed with no model call.
  Future<void> expectLocalServingsChange() async {
    String amounts() => tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .where((s) => RegExp(r'^\d+ g$').hasMatch(s))
        .join(',');
    final before = amounts();
    await tap(find.byTooltip('More servings').last);
    await wait(const Duration(milliseconds: 300));
    expect(busy, isFalse, reason: 'scaling must not call the model');
    if (before.isNotEmpty) expect(amounts(), isNot(before));
    print('✓ $label: rescaled on device ($before -> ${amounts()})');
  }

  /// Records (rather than stops on) render failures.
  void checkRendering(String step) {
    for (final w in tester.widgetList<FallbackWidget>(
      find.byType(FallbackWidget),
    )) {
      problems.add('$label / $step: FallbackWidget: ${w.error}');
    }
    if (has(find.textContaining('Unknown recipe'))) {
      problems.add('$label / $step: unknown recipe id');
    }
    // FallbackWidget uses the same icon as the app's error notices.
    if (count(find.byIcon(Icons.error_outline)) >
        count(find.byType(FallbackWidget))) {
      problems.add('$label / $step: error notice shown');
    }
  }
}
