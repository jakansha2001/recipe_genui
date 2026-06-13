import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import 'package:recipe_genui/recipe_db.dart';

/// The full-recipe view — the demo's payoff.
///
/// Split-hybrid in action: the facts (title, image, ingredients, default steps)
/// come from our DB by `recipeId`. But the model MAY pass an adapted `steps`
/// list and a `note` — that's the "no blender / make it spicier" money shot,
/// where the model rewrites the language while we still own the facts.
final CatalogItem recipeViewItem = CatalogItem(
  name: 'RecipeView',
  dataSchema: S.object(
    description:
        'A full recipe with ingredients and numbered steps. Use THIS component '
        '(never plain text) to show a complete recipe after the user picks one.',
    properties: {
      'recipeId': S.string(
        description: 'The id of the recipe to show. Must be a known recipe id.',
      ),
      'steps': S.list(
        items: S.string(),
        description:
            'Optional. Provide an adapted list of steps when the user asked for '
            'a change (e.g. "no blender", "make it spicier"). Omit to use the '
            'default steps.',
      ),
      'note': S.string(
        description:
            'Optional one-line note explaining an adaptation, e.g. "Skipped the '
            'blender and mashed by hand instead."',
      ),
    },
    required: ['recipeId'],
  ),
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": "RecipeView",
          "recipeId": "quick_paneer_wrap"
        }
      ]
    ''',
  ],
  widgetBuilder: (itemContext) {
    final data = itemContext.data as Map<String, dynamic>;
    final recipeId = data['recipeId'] as String? ?? '';
    final note = data['note'] as String?;
    final modelSteps =
        (data['steps'] as List?)?.map((e) => e.toString()).toList();

    final recipe = recipeById(recipeId);
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

    // Use the model's adapted steps if it provided any; otherwise our defaults.
    final steps = (modelSteps != null && modelSteps.isNotEmpty)
        ? modelSteps
        : recipe.steps;

    return _RecipeView(
      recipe: recipe,
      steps: steps,
      note: note,
      onAdjust: (adjustment) {
        itemContext.dispatchEvent(
          UserActionEvent(
            name: 'adjustRecipe',
            sourceComponentId: itemContext.id,
            context: {'recipeId': recipe.id, 'adjustment': adjustment},
          ),
        );
      },
    );
  },
);

class _RecipeView extends StatelessWidget {
  const _RecipeView({
    required this.recipe,
    required this.steps,
    required this.onAdjust,
    this.note,
  });

  final Recipe recipe;
  final List<String> steps;
  final String? note;
  final void Function(String adjustment) onAdjust;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero image with branded fallback.
          SizedBox(
            height: 180,
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
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              },
              errorBuilder: (context, error, stack) => Container(
                color: theme.colorScheme.primaryContainer,
                alignment: Alignment.center,
                child: Icon(
                  Icons.restaurant_menu,
                  size: 48,
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
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _Pill(icon: Icons.schedule, label: '${recipe.cookTimeMinutes} min'),
                    const SizedBox(width: 8),
                    _Pill(icon: Icons.bar_chart, label: recipe.difficulty),
                  ],
                ),

                // Adaptation note (the "I changed it for you" moment).
                if (note != null && note!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.auto_awesome,
                            size: 18,
                            color: theme.colorScheme.onSecondaryContainer),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            note!,
                            style: TextStyle(
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 18),
                Text('Ingredients', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: recipe.ingredients
                      .map((ing) => Chip(
                            label: Text(ing),
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                            side: BorderSide.none,
                          ))
                      .toList(),
                ),

                const SizedBox(height: 18),
                Text('Steps', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                for (int i = 0; i < steps.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: theme.colorScheme.primary,
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(steps[i],
                              style: theme.textTheme.bodyMedium),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                Text('Adjust this recipe',
                    style: theme.textTheme.labelLarge
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _AdjustChip(
                        label: 'No blender',
                        onTap: () => onAdjust('no blender')),
                    _AdjustChip(
                        label: 'Make it spicier',
                        onTap: () => onAdjust('make it spicier')),
                    _AdjustChip(
                        label: 'Fewer steps',
                        onTap: () => onAdjust('fewer, simpler steps')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});
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

class _AdjustChip extends StatelessWidget {
  const _AdjustChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      avatar: Icon(Icons.tune, size: 16, color: theme.colorScheme.primary),
      backgroundColor: theme.colorScheme.surface,
      side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.4)),
    );
  }
}