import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import 'package:recipe_genui/catalog/widgets/info_pill.dart';
import 'package:recipe_genui/catalog/widgets/recipe_image.dart';
import 'package:recipe_genui/catalog/widgets/recipe_lookup.dart';
import 'package:recipe_genui/data/recipe.dart';

/// The full recipe — the demo's payoff.
///
/// The facts (title, image, ingredient amounts, default steps) come from our
/// data by `recipeId`. The model may pass adapted `steps` and a `note` — the
/// "no blender" moment, where it rewrites the language while we keep the
/// facts. `servings` is a two-way data binding: the stepper writes the surface
/// data model and the amounts rescale on the device, with no model call.
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
      'servings': A2uiSchemas.numberReference(
        description:
            'How many people to cook for. Bind it to the data model, e.g. '
            '{"path": "/servings"}, so the user can change it on the device; '
            'the app rescales the ingredient amounts itself.',
      ),
      'steps': S.list(
        items: S.string(),
        description:
            'Optional. Provide an adapted list of steps when the user asked '
            'for a change (e.g. "no blender", "make it spicier"). Omit to use '
            'the default steps.',
      ),
      'note': A2uiSchemas.stringReference(
        description:
            'Optional one-line note explaining an adaptation, e.g. "Skipped '
            'the blender and mashed by hand instead."',
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
          "recipeId": "quick_paneer_wrap",
          "servings": {"path": "/servings"}
        }
      ]
    ''',
  ],
  widgetBuilder: (itemContext) {
    final data = itemContext.data as JsonMap;
    return RecipeLookup(
      dataContext: itemContext.dataContext,
      recipeId: data['recipeId'],
      builder: (context, recipe) => _BoundRecipeView(
        itemContext: itemContext,
        data: data,
        recipe: recipe,
      ),
    );
  },
);

/// Servings the stepper allows; the prompt's validation uses the same range.
const int minServings = 1;
const int maxServings = 12;

/// Changes the user can ask for in place.
const List<({String label, String request})> _adjustments = [
  (label: 'No blender', request: 'no blender'),
  (label: 'Make it spicier', request: 'make it spicier'),
  (label: 'Fewer steps', request: 'fewer, simpler steps'),
];

/// Resolves the model-supplied props — each may be a literal or a data
/// binding — and builds the view. Resolution never throws: an odd type falls
/// back to our own facts.
class _BoundRecipeView extends StatelessWidget {
  const _BoundRecipeView({
    required this.itemContext,
    required this.data,
    required this.recipe,
  });

  final CatalogItemContext itemContext;
  final JsonMap data;
  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final dataContext = itemContext.dataContext;
    // Like genui's Slider: write to the bound path, or to a path scoped to
    // this component when the model sent a literal.
    final servingsRef = data['servings'];
    final servingsPath = servingsRef is Map && servingsRef['path'] is String
        ? servingsRef['path'] as String
        : '${itemContext.id}.servings';

    return BoundString(
      dataContext: dataContext,
      value: data['note'],
      builder: (context, note) => BoundList(
        dataContext: dataContext,
        value: data['steps'],
        builder: (context, modelSteps) => BoundNumber(
          dataContext: dataContext,
          value: {'path': servingsPath},
          builder: (context, boundServings) {
            final servings =
                (boundServings ??
                        (servingsRef is num ? servingsRef : recipe.servings))
                    .round()
                    .clamp(minServings, maxServings);
            final steps = modelSteps?.map((s) => s.toString()).toList();
            return _RecipeView(
              recipe: recipe,
              steps: steps == null || steps.isEmpty ? recipe.steps : steps,
              note: note,
              servings: servings,
              onServingsChanged: (value) =>
                  dataContext.update(DataPath(servingsPath), value),
              onAdjust: (request) => itemContext.dispatchEvent(
                UserActionEvent(
                  name: 'adjustRecipe',
                  sourceComponentId: itemContext.id,
                  context: {
                    'recipeId': recipe.id,
                    'adjustment': request,
                    'servings': servings,
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RecipeView extends StatelessWidget {
  const _RecipeView({
    required this.recipe,
    required this.steps,
    required this.note,
    required this.servings,
    required this.onServingsChanged,
    required this.onAdjust,
  });

  final Recipe recipe;
  final List<String> steps;
  final String? note;
  final int servings;
  final ValueChanged<int> onServingsChanged;
  final ValueChanged<String> onAdjust;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final note = this.note;
    final factor = servings / recipe.servings;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RecipeImage(recipe.imageAsset, height: 180),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(recipe.title, style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                RecipeFacts(recipe),
                if (note != null && note.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _AdaptationNote(note),
                ],
                const SizedBox(height: 18),
                _ServingsStepper(
                  servings: servings,
                  onChanged: onServingsChanged,
                ),
                const SizedBox(height: 18),
                Text('Ingredients', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final ingredient in recipe.ingredients)
                  _IngredientRow(
                    name: ingredient.name,
                    amount: ingredient.formatAmount(factor: factor),
                  ),
                const SizedBox(height: 18),
                Text('Steps', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final (index, step) in steps.indexed)
                  _StepRow(number: index + 1, text: step),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Adjust this recipe',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final adjustment in _adjustments)
                      ActionChip(
                        label: Text(adjustment.label),
                        onPressed: () => onAdjust(adjustment.request),
                        avatar: Icon(
                          Icons.tune,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                      ),
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

/// The "I changed it for you" callout.
class _AdaptationNote extends StatelessWidget {
  const _AdaptationNote(this.note);

  final String note;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              Icons.auto_awesome,
              size: 18,
              color: scheme.onSecondaryContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                note,
                style: TextStyle(color: scheme.onSecondaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServingsStepper extends StatelessWidget {
  const _ServingsStepper({required this.servings, required this.onChanged});

  final int servings;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final stepStyle = IconButton.styleFrom(
      backgroundColor: scheme.secondary,
      foregroundColor: scheme.onSecondary,
      disabledBackgroundColor: scheme.outline,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    );
    return Row(
      children: [
        Icon(Icons.people_outline, color: scheme.primary),
        const SizedBox(width: 8),
        Text('Servings', style: theme.textTheme.titleMedium),
        const Spacer(),
        IconButton(
          style: stepStyle,
          tooltip: 'Fewer servings',
          icon: const Icon(Icons.remove),
          onPressed: servings > minServings
              ? () => onChanged(servings - 1)
              : null,
        ),
        SizedBox(
          width: 40,
          child: _Rolling(
            '$servings',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
        ),
        IconButton(
          style: stepStyle,
          tooltip: 'More servings',
          icon: const Icon(Icons.add),
          onPressed: servings < maxServings
              ? () => onChanged(servings + 1)
              : null,
        ),
      ],
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({required this.name, required this.amount});

  final String name;

  /// Null means "to taste".
  final String? amount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(name, style: theme.textTheme.bodyMedium)),
          _Rolling(
            amount ?? 'to taste',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: theme.colorScheme.primary,
            child: Text(
              '$number',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

/// Text that cross-fades and lifts when its value changes, so rescaled
/// amounts visibly update on the device.
class _Rolling extends StatelessWidget {
  const _Rolling(this.text, {this.style, this.textAlign});

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: Text(
        text,
        key: ValueKey(text),
        style: style,
        textAlign: textAlign,
      ),
    );
  }
}
