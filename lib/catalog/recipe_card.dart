import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../recipe_db.dart';

/// Tracks which recipe the user last opened, so that card can stay visibly
/// highlighted across the (persistent) chat history. Shared app-wide because
/// cards live inside model-generated surfaces we don't otherwise control.
final ValueNotifier<String?> selectedRecipeId = ValueNotifier<String?>(null);

/// A custom catalog item the AI can choose to render a recipe.
///
/// The anatomy of every CatalogItem, all visible here:
///   1. name        — the word the model uses to pick this widget
///   2. dataSchema   — the CONTRACT: what data the model must supply
///   3. widgetBuilder — OUR Flutter code that renders it, in our design
///
/// The anti-hallucination move: the schema only accepts a `recipeId`. The model
/// cannot send a title, an image, or a cook time — it can only point at a recipe
/// we already own. The optional `reason` is the one thing we DO let the model
/// write freely, because it's language (the split-hybrid principle).
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
      'reason': S.string(
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
    final data = itemContext.data as Map<String, dynamic>;
    final recipeId = data['recipeId'] as String? ?? '';
    final reason = data['reason'] as String?;

    final recipe = recipeById(recipeId);

    // The model referenced a recipe we don't have. Fail visibly, not silently —
    // this exact case is great talk material about constraining the model.
    if (recipe == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Unknown recipe: "$recipeId"',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    return _RecipeCard(
      recipe: recipe,
      reason: reason,
      onTap: () {
        // Mark this card as the user's choice so it highlights, then close the
        // loop: ask the model for the full recipe view.
        selectedRecipeId.value = recipe.id;
        itemContext.dispatchEvent(
          UserActionEvent(
            name: 'viewRecipe',
            sourceComponentId: itemContext.id,
            context: {'recipeId': recipe.id, 'title': recipe.title},
          ),
        );
      },
    );
  },
);

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.recipe, this.reason, this.onTap});

  final Recipe recipe;
  final String? reason;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<String?>(
      valueListenable: selectedRecipeId,
      builder: (context, selectedId, _) {
        final selected = selectedId == recipe.id;
        return Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: selected
                ? BorderSide(color: theme.colorScheme.primary, width: 2.5)
                : BorderSide.none,
          ),
          elevation: selected ? 4 : 2,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image header loaded from the internet; a branded fallback
                // keeps the demo clean if a URL ever fails to load.
                SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: Image.network(
                    recipe.imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: theme.colorScheme.primaryContainer,
                        alignment: Alignment.center,
                        child: const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stack) => Container(
                      color: theme.colorScheme.primaryContainer,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.restaurant_menu,
                        size: 44,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.title,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (reason != null && reason!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          reason!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _MetaChip(
                            icon: Icons.schedule,
                            label: '${recipe.cookTimeMinutes} min',
                          ),
                          const SizedBox(width: 8),
                          _MetaChip(
                            icon: Icons.bar_chart,
                            label: recipe.difficulty,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Colored affordance; flips to a "Selected" state once
                      // chosen so it's obvious which card the user picked.
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: onTap,
                          icon: Icon(
                            selected
                                ? Icons.check_circle
                                : Icons.menu_book_outlined,
                            size: 18,
                          ),
                          label: Text(selected ? 'Selected' : 'View recipe'),
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label, style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }
}