import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

import 'package:recipe_genui/chat/error_messages.dart';
import 'package:recipe_genui/chat/ui_submissions.dart';

void main() {
  ChatMessage submission(Map<String, Object?> body) => ChatMessage.user(
    '',
    parts: [
      UiInteractionPart.create(jsonEncode({'version': 'v0.9', ...body})),
    ],
  );

  String? summaryOf(Map<String, Object?> context) =>
      (UiSubmission.parse(
                submission({
                  'action': {'name': 'x', 'context': context},
                }),
              ).single
              as ActionSubmission)
          .summary;

  group('UiSubmission.parse', () {
    test('reads actions and errors, and ignores anything else', () {
      final parsed = UiSubmission.parse(
        ChatMessage.user(
          'typed text',
          parts: [
            UiInteractionPart.create(
              jsonEncode({
                'action': {'name': 'a'},
              }),
            ),
            UiInteractionPart.create(
              jsonEncode({
                'error': {'code': 'VALIDATION_FAILED'},
              }),
            ),
            UiInteractionPart.create('not json'),
          ],
        ),
      ).toList();
      expect(parsed.map((s) => s.runtimeType), [
        ActionSubmission,
        ErrorSubmission,
      ]);
    });
  });

  group('ActionSubmission.summary', () {
    test('names a chosen recipe', () {
      expect(
        summaryOf({'recipeId': 'poha', 'title': 'Poha'}),
        'Selected: Poha',
      );
    });

    test('names an adjustment', () {
      expect(summaryOf({'adjustment': 'no blender'}), 'Adjust: no blender');
    });

    test('lists chosen values and skips ids', () {
      expect(
        summaryOf({
          'ingredients': ['paneer', 'onion'],
          'time': '15 minutes',
          'servings': 3,
          'surfaceId': 's1',
        }),
        'paneer, onion, 15 minutes, for 3',
      );
    });

    test('is null when there is nothing readable', () {
      expect(summaryOf({}), isNull);
      expect(summaryOf({'recipeId': 'poha'}), isNull);
    });
  });

  group('describeError', () {
    test('explains quota, App Check and network failures', () {
      expect(
        describeError(Exception('429 RESOURCE_EXHAUSTED')),
        contains('a lot of requests'),
      );
      expect(
        describeError(Exception('App attestation failed')),
        contains('App Check'),
      );
      expect(
        describeError(Exception('SocketException: Failed host lookup')),
        contains('internet'),
      );
    });

    test('falls back to a generic message', () {
      expect(
        describeError(StateError('boom')),
        'Something went wrong. Please try again.',
      );
    });
  });
}
