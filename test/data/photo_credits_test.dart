import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:recipe_genui/data/photo_credits.dart';
import 'package:recipe_genui/data/recipes.dart';

void main() {
  test('every recipe has a bundled photo and a credit', () {
    for (final recipe in recipes) {
      expect(
        File(recipe.imageAsset).existsSync(),
        isTrue,
        reason: '${recipe.id}: missing ${recipe.imageAsset}',
      );
      expect(photoCredits[recipe.id], isNotNull, reason: recipe.id);
    }
  });

  test('credits only name recipes that exist, with real links', () {
    for (final MapEntry(:key, value: credit) in photoCredits.entries) {
      expect(recipeById(key), isNotNull, reason: key);
      expect(credit.author, isNotEmpty, reason: key);
      expect(Uri.parse(credit.source).isScheme('https'), isTrue, reason: key);
    }
  });
}
