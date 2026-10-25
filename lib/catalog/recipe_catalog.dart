import 'package:genui/genui.dart';

import 'package:recipe_genui/catalog/recipe_card.dart';
import 'package:recipe_genui/catalog/recipe_prompts.dart';
import 'package:recipe_genui/catalog/recipe_view.dart';

/// The built-in catalog (Text, Column, ChoicePicker, TextField, … plus the
/// client functions like formatString, pluralize and the validation checks),
/// minus media the model would have to invent URLs for.
final Catalog _basicCatalog = BasicCatalogItems.asCatalog().copyWithout(
  itemsToRemove: [
    BasicCatalogItems.audioPlayer,
    BasicCatalogItems.image,
    BasicCatalogItems.video,
  ],
);

/// Everything the model may build with: the basic components and functions,
/// our RecipeCard and RecipeView, and the steering prompts layered on top.
final Catalog recipeCatalog = _basicCatalog.copyWith(
  systemPromptFragments: [
    ...RecipePrompts.all,
    ..._basicCatalog.systemPromptFragments,
  ],
  newItems: [recipeCardItem, recipeViewItem],
);

/// The full system instruction for the model, built once.
///
/// `PromptBuilder.chat` combines the A2UI format rules (HOW to emit UI), the
/// catalog's schemas and prompt fragments (WHAT to build), and the framework
/// fragments passed here: acknowledge the user, always offer a submit element,
/// and don't generate UI when it isn't useful.
final String recipeSystemInstruction = PromptBuilder.chat(
  catalog: recipeCatalog,
  systemPromptFragments: [
    PromptFragments.acknowledgeUser(),
    PromptFragments.requireAtLeastOneSubmitElement(
      prefix: PromptBuilder.defaultImportancePrefix,
    ),
    PromptFragments.uiGenerationRestriction(
      prefix: PromptBuilder.defaultImportancePrefix,
    ),
  ],
).systemPromptJoined();
