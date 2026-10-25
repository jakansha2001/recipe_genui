import 'package:flutter/material.dart';
import 'package:genui/genui.dart';

import 'package:recipe_genui/data/recipe.dart';
import 'package:recipe_genui/data/recipes.dart';

/// Resolves the `recipeId` a model sent — a literal or a data binding — to a
/// recipe we own, and builds it. An id we don't know fails visibly instead of
/// rendering something the model made up.
class RecipeLookup extends StatelessWidget {
  const RecipeLookup({
    super.key,
    required this.dataContext,
    required this.recipeId,
    required this.builder,
  });

  final DataContext dataContext;

  /// The raw `recipeId` prop from the model.
  final Object? recipeId;
  final Widget Function(BuildContext context, Recipe recipe) builder;

  @override
  Widget build(BuildContext context) {
    // BoundString resolves literals and {"path": ...} bindings alike, and never
    // throws on an odd type — unlike a raw `as String` cast.
    return BoundString(
      dataContext: dataContext,
      value: recipeId,
      builder: (context, id) {
        final recipe = recipeById(id ?? '');
        return recipe == null
            ? _UnknownRecipe(id: id ?? '')
            : builder(context, recipe);
      },
    );
  }
}

class _UnknownRecipe extends StatelessWidget {
  const _UnknownRecipe({required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Unknown recipe: "$id"',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
    );
  }
}
