/// The recipe "database" — a small, fixed set of facts.
///
/// This is the trusted source from the talk's core principle:
/// *the model proposes, your data disposes.* The model is only ever allowed to
/// reference a recipe by its [id]; it can never invent a title, a cook time, or
/// (critically) an image URL. Everything factual lives here, owned by us.
library;

class Recipe {
  const Recipe({
    required this.id,
    required this.title,
    required this.cookTimeMinutes,
    required this.difficulty,
    required this.ingredients,
    required this.steps,
    required this.image,
  });

  /// Stable identifier. This is the ONLY field the model sends back to us.
  final String id;
  final String title;
  final int cookTimeMinutes;

  /// One of: easy, medium, hard.
  final String difficulty;
  final List<String> ingredients;

  /// Canonical steps. The model may *adapt* these (e.g. drop a blender step),
  /// but these are the trustworthy default.
  final List<String> steps;

  /// Filename under assets/recipes/. The model never supplies this.
  final String image;
}

/// The fixed catalog of recipes the assistant can choose from.
const List<Recipe> recipes = [
  Recipe(
    id: 'paneer_bhurji',
    title: 'Paneer Bhurji',
    cookTimeMinutes: 15,
    difficulty: 'easy',
    ingredients: ['paneer', 'onion', 'tomato', 'green chilli', 'turmeric', 'cumin'],
    steps: [
      'Crumble the paneer with your hands and set aside.',
      'Heat oil, add cumin, then saute onion until soft.',
      'Add tomato, green chilli and turmeric; cook until the tomato breaks down.',
      'Add the crumbled paneer, toss for 3-4 minutes, and season with salt.',
      'Garnish with coriander and serve hot with roti.',
    ],
    image: 'paneer_bhurji.jpg',
  ),
  Recipe(
    id: 'tomato_paneer_masala',
    title: 'Tomato Paneer Masala',
    cookTimeMinutes: 20,
    difficulty: 'medium',
    ingredients: ['paneer', 'tomato', 'onion', 'ginger', 'garlic', 'cream', 'garam masala'],
    steps: [
      'Blend tomato, onion, ginger and garlic into a smooth puree.',
      'Cook the puree in oil until it thickens and darkens, about 8 minutes.',
      'Stir in garam masala and a splash of cream.',
      'Add cubed paneer and simmer gently for 5 minutes.',
      'Finish with a swirl of cream and serve with naan.',
    ],
    image: 'tomato_paneer_masala.jpg',
  ),
  Recipe(
    id: 'quick_paneer_wrap',
    title: 'Quick Paneer Wrap',
    cookTimeMinutes: 10,
    difficulty: 'easy',
    ingredients: ['paneer', 'roti', 'onion', 'capsicum', 'mint chutney'],
    steps: [
      'Pan-fry paneer strips with a pinch of chaat masala until golden.',
      'Warm a roti and spread mint chutney across it.',
      'Add the paneer, sliced onion and capsicum.',
      'Roll tightly, slice in half, and serve.',
    ],
    image: 'quick_paneer_wrap.jpg',
  ),
  Recipe(
    id: 'jeera_aloo',
    title: 'Jeera Aloo',
    cookTimeMinutes: 20,
    difficulty: 'easy',
    ingredients: ['potato', 'cumin', 'green chilli', 'turmeric', 'coriander'],
    steps: [
      'Boil potatoes until just tender, then cube them.',
      'Temper cumin in hot oil until fragrant.',
      'Add green chilli and turmeric, then the potatoes.',
      'Toss until the edges crisp, season with salt, and garnish with coriander.',
    ],
    image: 'jeera_aloo.jpg',
  ),
  Recipe(
    id: 'masala_omelette',
    title: 'Masala Omelette',
    cookTimeMinutes: 8,
    difficulty: 'easy',
    ingredients: ['eggs', 'onion', 'tomato', 'green chilli', 'coriander'],
    steps: [
      'Whisk eggs with chopped onion, tomato, chilli, coriander and salt.',
      'Pour into a hot, lightly oiled pan.',
      'Cook until the base sets, then fold and cook through.',
      'Serve with buttered toast.',
    ],
    image: 'masala_omelette.jpg',
  ),
  Recipe(
    id: 'dal_tadka',
    title: 'Dal Tadka',
    cookTimeMinutes: 30,
    difficulty: 'medium',
    ingredients: ['toor dal', 'onion', 'tomato', 'garlic', 'cumin', 'red chilli'],
    steps: [
      'Pressure-cook the dal with turmeric and salt until soft.',
      'Prepare a tadka: fry cumin, garlic and red chilli in ghee.',
      'Saute onion and tomato until soft, then add to the dal.',
      'Pour the sizzling tadka over the top just before serving.',
    ],
    image: 'dal_tadka.jpg',
  ),
];

/// Look up a recipe by id. Returns null if the model references one that
/// doesn't exist (which we handle gracefully in the widget).
Recipe? recipeById(String id) {
  for (final r in recipes) {
    if (r.id == id) return r;
  }
  return null;
}