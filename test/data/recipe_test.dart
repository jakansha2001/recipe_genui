import 'package:flutter_test/flutter_test.dart';

import 'package:recipe_genui/data/recipe.dart';
import 'package:recipe_genui/data/recipes.dart';

void main() {
  group('Ingredient.formatAmount', () {
    test('formats metric amounts as whole numbers with a unit', () {
      expect(
        const Ingredient('paneer', 200, Unit.gram).formatAmount(),
        '200 g',
      );
    });

    test('scales metric amounts and rounds large ones to 5', () {
      const paneer = Ingredient('paneer', 200, Unit.gram);
      expect(paneer.formatAmount(factor: 1.5), '300 g');
      expect(paneer.formatAmount(factor: 7 / 3), '465 g'); // 466.7 -> 465
    });

    test('keeps small metric amounts exact', () {
      expect(
        const Ingredient('saffron', 3, Unit.gram).formatAmount(factor: 1.5),
        '5 g', // 4.5 rounds half up
      );
    });

    test('shows spoon and cup amounts as quarter fractions', () {
      const turmeric = Ingredient('turmeric', 0.25, Unit.teaspoon);
      expect(turmeric.formatAmount(), '¼ tsp');
      expect(turmeric.formatAmount(factor: 2), '½ tsp');
      expect(turmeric.formatAmount(factor: 3), '¾ tsp');
      expect(const Ingredient('rice', 1.5, Unit.cup).formatAmount(), '1½ cup');
    });

    test('never rounds a real amount down to zero', () {
      expect(
        const Ingredient(
          'turmeric',
          0.25,
          Unit.teaspoon,
        ).formatAmount(factor: 0.25),
        '¼ tsp',
      );
    });

    test('counts whole items without a unit', () {
      const onion = Ingredient('onion', 1);
      expect(onion.formatAmount(), '1');
      expect(onion.formatAmount(factor: 2.5), '2½');
    });

    test('returns null for "to taste"', () {
      expect(const Ingredient('salt').formatAmount(factor: 3), isNull);
    });
  });

  group('recipes', () {
    test('ids are unique', () {
      final ids = recipes.map((r) => r.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('every recipe is complete', () {
      for (final recipe in recipes) {
        expect(recipe.servings, greaterThan(0), reason: recipe.id);
        expect(recipe.ingredients, isNotEmpty, reason: recipe.id);
        expect(recipe.steps, isNotEmpty, reason: recipe.id);
      }
    });

    test('recipeById finds known ids and rejects others', () {
      expect(recipeById('dal_tadka')?.title, 'Dal Tadka');
      expect(recipeById('burger'), isNull);
    });
  });
}
