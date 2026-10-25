import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import 'package:recipe_genui/app/theme.dart';
import 'package:recipe_genui/catalog/widgets/info_pill.dart';
import 'package:recipe_genui/catalog/widgets/recipe_image.dart';
import 'package:recipe_genui/catalog/widgets/recipe_lookup.dart';
import 'package:recipe_genui/catalog/widgets/recipe_selection.dart';
import 'package:recipe_genui/data/recipe.dart';

/// A recipe the model can suggest.
///
/// The anatomy of every CatalogItem, all visible here:
///   1. name          — the word the model uses to pick this widget
///   2. dataSchema    — the CONTRACT: what data the model must supply
///   3. widgetBuilder — OUR Flutter code that renders it, in our design
///
/// The anti-hallucination move: the schema accepts only a `recipeId`. The model
/// can't send a title, an image or a cook time — it can only point at a recipe
/// we own. The optional `reason` is the one thing it writes freely, because
/// it's language: the app owns the facts, the model owns the words.
final CatalogItem recipeCardItem = CatalogItem(
  name: 'RecipeCard',
  dataSchema: S.object(
    description:
        'A card showing one recipe the user can cook. Reference an existing '
        'recipe by its id; never invent recipe details.',
    properties: {
      'recipeId': S.string(
        description:
            'The id of a recipe to display. Must be one of the known recipe '
            'ids provided in the system instructions.',
      ),
      'reason': A2uiSchemas.stringReference(
        description:
            'A short, friendly one-line reason this recipe fits what the user '
            'asked for, e.g. "Quick and uses your paneer."',
      ),
    },
    required: ['recipeId'],
  ),
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": "RecipeCard",
          "recipeId": "paneer_bhurji",
          "reason": "Ready in 15 minutes with the paneer you have."
        }
      ]
    ''',
  ],
  widgetBuilder: (itemContext) {
    final data = itemContext.data as JsonMap;
    return RecipeLookup(
      dataContext: itemContext.dataContext,
      recipeId: data['recipeId'],
      builder: (context, recipe) => BoundString(
        dataContext: itemContext.dataContext,
        value: data['reason'],
        builder: (context, reason) => _RecipeCard(
          recipe: recipe,
          reason: reason,
          onOpen: () => itemContext.dispatchEvent(
            UserActionEvent(
              name: 'viewRecipe',
              sourceComponentId: itemContext.id,
              context: {'recipeId': recipe.id, 'title': recipe.title},
            ),
          ),
        ),
      ),
    );
  },
);

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({
    required this.recipe,
    required this.reason,
    required this.onOpen,
  });

  final Recipe recipe;
  final String? reason;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selection = RecipeSelection.maybeOf(context);
    final selected = selection?.value == recipe.id;
    final reason = this.reason;

    void open() {
      // Highlight this card as the user's choice, then close the loop: ask
      // the model for the full recipe.
      selection?.value = recipe.id;
      onOpen();
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: SageRadii.cardRadius,
        side: selected
            ? BorderSide(color: theme.colorScheme.primary, width: 2.5)
            : BorderSide(color: theme.colorScheme.outline),
      ),
      child: InkWell(
        onTap: open,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RecipeImage(recipe.imageAsset, height: 160),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (reason != null && reason.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      reason,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  RecipeFacts(recipe),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: open,
                      icon: Icon(
                        selected
                            ? Icons.check_circle
                            : Icons.menu_book_outlined,
                        size: 18,
                      ),
                      label: Text(selected ? 'Selected' : 'View recipe'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
