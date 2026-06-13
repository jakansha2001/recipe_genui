import 'package:genui/genui.dart';

import '../recipe_db.dart';
import 'recipe_card.dart';

/// The system-prompt fragments that steer the model: what to do, when, and with
/// which components. Registering a widget (Step 3) makes it *possible* for the
/// model to use; these instructions make it *likely*. Both halves are required.
abstract final class RecipePrompts {
  RecipePrompts._();

  static const String persona =
      'You are a warm, practical home-cooking assistant for Indian home cooks. '
      'You help the user decide what to cook using the ingredients they have '
      'and the time available. Keep a friendly, concise tone. '
      'ALWAYS follow this exact flow and never skip a step: '
      '(1) gather the ingredients and time using input components; '
      '(2) show multiple recipe cards to choose from; '
      '(3) only after the user taps a card, show that full recipe.';

  /// Step 1 of the flow: gather preferences with inputs instead of asking the
  /// user to type. References the built-in ChoicePicker by its real name.
  static String get gatherPreferences =>
      'When the user first asks for something to cook, do NOT list recipes yet. '
      'First gather what you need using the '
      "'${BasicCatalogItems.choicePicker.name}' component (displayStyle "
      '"chips", multiple selection) to confirm which ingredients they have, and '
      'another to ask how much time they have. Pre-select ingredients the user '
      'already mentioned or that appear in their photo. Keep it to one short '
      'surface that ends with a submit button.';

  /// Step 2 of the flow: show results as RecipeCards, by id only.
  static String get showRecipes =>
      'Once you know the ingredients and time, present at least TWO and ideally '
      "THREE different options, each as its own '${recipeCardItem.name}' "
      'component, so the user can choose. This is a REQUIRED step: do NOT pick a '
      'single recipe for the user, and do NOT show full recipe steps yet. Only '
      'show the full recipe after the user taps a card (see the next rule). '
      'Reference recipes ONLY by an id from this list, and NEVER invent an id or '
      'describe a recipe in plain text:\n$_recipeMenu\n'
      'For each card, write a short, friendly "reason" that mentions the '
      "user's ingredients or time, e.g. \"Ready in 15 minutes with your paneer.\"";

  /// Step 3 of the flow: the loop-closing action from tapping a card.
  static String get viewRecipe =>
      "When a 'viewRecipe' action arrives, the user tapped a recipe card. "
      'Respond by showing that recipe\'s full ingredient list and numbered '
      'steps using Text components. If the user adds a constraint (for example '
      '"no blender" or "make it spicier"), adapt the steps sensibly while '
      'keeping them safe and realistic.';

  /// Inject the menu of valid recipe ids straight from our database, so the
  /// model always knows exactly what it's allowed to choose.
  static String get _recipeMenu => recipes
      .map(
        (r) =>
            '- ${r.id}: ${r.title} (${r.cookTimeMinutes} min, ${r.difficulty}; '
            'uses ${r.ingredients.take(3).join(", ")})',
      )
      .join('\n');
}

/// Start from the built-in catalog (Text, Column, ChoicePicker, TextField, ...)
/// but remove components we don't want the model reaching for. We strip image/
/// video/audio so the model can't try to render media it would have to invent.
final Catalog _basicCatalog = BasicCatalogItems.asCatalog().copyWithout(
  itemsToRemove: [
    BasicCatalogItems.audioPlayer,
    BasicCatalogItems.image,
    BasicCatalogItems.video,
  ],
);

/// Our full catalog: the basic components plus our custom RecipeCard, with the
/// domain steering prompts layered on top of the basic ones.
final Catalog recipeCatalog = _basicCatalog.copyWith(
  systemPromptFragments: [
    RecipePrompts.persona,
    RecipePrompts.gatherPreferences,
    RecipePrompts.showRecipes,
    RecipePrompts.viewRecipe,
    ..._basicCatalog.systemPromptFragments,
  ],
  newItems: [recipeCardItem],
);