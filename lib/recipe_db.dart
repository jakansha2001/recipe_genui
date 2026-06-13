/// The recipe "database" — a small, fixed set of facts.
///
/// This is the trusted source from the talk's core principle:
/// *the model proposes, your data disposes.* The model only ever references a
/// recipe by [id]; it can never invent a title, a cook time, or an image. The
/// images are fetched from the internet by keyword (see [imageUrl]) so you don't
/// have to bundle any photo files yourself. Swap any URL for a specific one
/// (e.g. an Unsplash/Pexels link) when you want exact control.
library;

class Recipe {
  const Recipe({
    required this.id,
    required this.title,
    required this.cookTimeMinutes,
    required this.difficulty,
    required this.ingredients,
    required this.steps,
    required this.imageUrl,
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

  /// A live image URL. We use loremflickr.com, which returns a real photo
  /// matching the keywords — no API key, no bundled files. The `lock` value
  /// keeps each recipe's image stable across reloads.
  final String imageUrl;
}

/// The fixed catalog of recipes the assistant can choose from.
const List<Recipe> recipes = [
  // ---- Paneer ----
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
    imageUrl: 'https://loremflickr.com/640/400/paneer,indian,food?lock=11',
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
    imageUrl: 'https://loremflickr.com/640/400/paneer,curry,indian?lock=12',
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
    imageUrl: 'https://loremflickr.com/640/400/wrap,roll,food?lock=13',
  ),

  // ---- Potato & vegetables ----
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
    imageUrl: 'https://loremflickr.com/640/400/potato,curry,indian?lock=14',
  ),
  Recipe(
    id: 'aloo_gobi',
    title: 'Aloo Gobi',
    cookTimeMinutes: 25,
    difficulty: 'easy',
    ingredients: ['potato', 'cauliflower', 'onion', 'tomato', 'turmeric', 'cumin', 'ginger'],
    steps: [
      'Heat oil and temper cumin; add onion and ginger until soft.',
      'Add tomato and turmeric and cook to a paste.',
      'Add potato and cauliflower florets, coat well, and add a splash of water.',
      'Cover and cook on low until tender, then garnish with coriander.',
    ],
    imageUrl: 'https://loremflickr.com/640/400/cauliflower,potato,indian?lock=15',
  ),
  Recipe(
    id: 'bhindi_masala',
    title: 'Bhindi Masala',
    cookTimeMinutes: 20,
    difficulty: 'easy',
    ingredients: ['okra', 'onion', 'tomato', 'turmeric', 'coriander powder', 'amchur'],
    steps: [
      'Wash and fully dry the okra, then slice into pieces.',
      'Saute the okra in oil until it loses its stickiness, then set aside.',
      'In the same pan cook onion and tomato with the spices.',
      'Return the okra, toss, finish with amchur, and serve with roti.',
    ],
    imageUrl: 'https://loremflickr.com/640/400/okra,indian,food?lock=16',
  ),

  // ---- Lentils & beans ----
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
    imageUrl: 'https://loremflickr.com/640/400/dal,lentil,indian?lock=17',
  ),
  Recipe(
    id: 'chana_masala',
    title: 'Chana Masala',
    cookTimeMinutes: 30,
    difficulty: 'medium',
    ingredients: ['chickpeas', 'onion', 'tomato', 'ginger', 'garlic', 'garam masala', 'chana masala powder'],
    steps: [
      'Saute onion, ginger and garlic until golden.',
      'Add tomato and the spices; cook to a thick masala.',
      'Add boiled chickpeas with a little of their water.',
      'Simmer 10 minutes until thick, then finish with garam masala.',
    ],
    imageUrl: 'https://loremflickr.com/640/400/chickpea,curry,indian?lock=18',
  ),
  Recipe(
    id: 'rajma',
    title: 'Rajma Masala',
    cookTimeMinutes: 40,
    difficulty: 'medium',
    ingredients: ['kidney beans', 'onion', 'tomato', 'ginger', 'garlic', 'garam masala'],
    steps: [
      'Soak kidney beans overnight, then pressure-cook until very soft.',
      'Make a masala by frying onion, ginger, garlic and tomato with spices.',
      'Add the beans with their cooking liquid and simmer until thick.',
      'Lightly mash a few beans for body and serve with rice.',
    ],
    imageUrl: 'https://loremflickr.com/640/400/beans,curry,indian?lock=19',
  ),

  // ---- Rice ----
  Recipe(
    id: 'veg_pulao',
    title: 'Vegetable Pulao',
    cookTimeMinutes: 25,
    difficulty: 'medium',
    ingredients: ['basmati rice', 'mixed vegetables', 'onion', 'whole spices', 'ginger garlic paste'],
    steps: [
      'Rinse and soak the rice for 15 minutes.',
      'Fry whole spices and onion, then add ginger garlic paste and vegetables.',
      'Add the drained rice and water (1 cup rice to about 1.75 cups water).',
      'Cover and cook on low until done, then rest 5 minutes and fluff.',
    ],
    imageUrl: 'https://loremflickr.com/640/400/pulao,rice,indian?lock=20',
  ),
  Recipe(
    id: 'lemon_rice',
    title: 'Lemon Rice',
    cookTimeMinutes: 15,
    difficulty: 'easy',
    ingredients: ['cooked rice', 'lemon', 'peanuts', 'mustard seeds', 'curry leaves', 'turmeric'],
    steps: [
      'Temper mustard seeds, peanuts and curry leaves in oil.',
      'Add turmeric, then the cooked rice, and toss to coat.',
      'Turn off the heat and squeeze in fresh lemon juice.',
      'Mix gently, season with salt, and serve.',
    ],
    imageUrl: 'https://loremflickr.com/640/400/rice,south,indian?lock=21',
  ),
  Recipe(
    id: 'veg_fried_rice',
    title: 'Veg Fried Rice',
    cookTimeMinutes: 15,
    difficulty: 'easy',
    ingredients: ['cooked rice', 'mixed vegetables', 'spring onion', 'soy sauce', 'garlic'],
    steps: [
      'Heat oil on high; fry garlic and finely chopped vegetables fast.',
      'Add the cold cooked rice and toss on high heat.',
      'Splash in soy sauce and season.',
      'Finish with spring onion and serve hot.',
    ],
    imageUrl: 'https://loremflickr.com/640/400/fried,rice,vegetable?lock=22',
  ),

  // ---- Eggs ----
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
    imageUrl: 'https://loremflickr.com/640/400/omelette,eggs,food?lock=23',
  ),
  Recipe(
    id: 'egg_curry',
    title: 'Egg Curry',
    cookTimeMinutes: 30,
    difficulty: 'medium',
    ingredients: ['eggs', 'onion', 'tomato', 'ginger garlic paste', 'garam masala', 'turmeric'],
    steps: [
      'Boil and peel the eggs, then lightly fry them with a little turmeric.',
      'Make an onion-tomato masala with ginger garlic paste and spices.',
      'Add water to make a gravy and simmer.',
      'Slip in the eggs, simmer 5 minutes, and serve with rice.',
    ],
    imageUrl: 'https://loremflickr.com/640/400/egg,curry,indian?lock=24',
  ),

  // ---- Chicken ----
  Recipe(
    id: 'chicken_curry',
    title: 'Home-Style Chicken Curry',
    cookTimeMinutes: 40,
    difficulty: 'medium',
    ingredients: ['chicken', 'onion', 'tomato', 'ginger garlic paste', 'yogurt', 'garam masala'],
    steps: [
      'Brown the chicken pieces and set aside.',
      'Fry onion until deep golden, add ginger garlic paste and tomato.',
      'Add yogurt and spices, then return the chicken with water.',
      'Cover and simmer until tender, then finish with garam masala.',
    ],
    imageUrl: 'https://loremflickr.com/640/400/chicken,curry,indian?lock=25',
  ),

  // ---- Breakfast ----
  Recipe(
    id: 'poha',
    title: 'Poha',
    cookTimeMinutes: 15,
    difficulty: 'easy',
    ingredients: ['flattened rice', 'onion', 'peanuts', 'mustard seeds', 'curry leaves', 'turmeric', 'lemon'],
    steps: [
      'Rinse the flattened rice briefly so it softens but stays separate.',
      'Temper mustard seeds, peanuts and curry leaves; add onion and turmeric.',
      'Fold in the poha and warm through gently.',
      'Finish with lemon juice and coriander.',
    ],
    imageUrl: 'https://loremflickr.com/640/400/poha,indian,breakfast?lock=26',
  ),
  Recipe(
    id: 'upma',
    title: 'Upma',
    cookTimeMinutes: 20,
    difficulty: 'easy',
    ingredients: ['semolina', 'onion', 'mustard seeds', 'curry leaves', 'green chilli', 'ginger'],
    steps: [
      'Dry-roast the semolina until fragrant and set aside.',
      'Temper mustard seeds, curry leaves, chilli, ginger and onion.',
      'Add hot water (about 1 part semolina to 2.5 parts water) and salt.',
      'Stir in the semolina slowly to avoid lumps; cook until fluffy.',
    ],
    imageUrl: 'https://loremflickr.com/640/400/upma,indian,breakfast?lock=27',
  ),
  Recipe(
    id: 'besan_chilla',
    title: 'Besan Chilla',
    cookTimeMinutes: 15,
    difficulty: 'easy',
    ingredients: ['gram flour', 'onion', 'tomato', 'green chilli', 'coriander', 'turmeric'],
    steps: [
      'Whisk gram flour with water into a smooth, pourable batter.',
      'Stir in chopped onion, tomato, chilli, coriander, turmeric and salt.',
      'Pour onto a hot pan and spread into a thin pancake.',
      'Cook both sides until golden and serve with chutney.',
    ],
    imageUrl: 'https://loremflickr.com/640/400/savory,pancake,indian?lock=28',
  ),

  // ---- Quick & relatable ----
  Recipe(
    id: 'masala_maggi',
    title: 'Masala Maggi',
    cookTimeMinutes: 10,
    difficulty: 'easy',
    ingredients: ['instant noodles', 'onion', 'tomato', 'peas', 'green chilli'],
    steps: [
      'Saute onion, tomato, peas and chilli for a couple of minutes.',
      'Add water and bring to a boil.',
      'Add the noodles and the tastemaker and cook 2-3 minutes.',
      'Cook to your preferred consistency and serve hot.',
    ],
    imageUrl: 'https://loremflickr.com/640/400/instant,noodles,food?lock=29',
  ),
  Recipe(
    id: 'grilled_sandwich',
    title: 'Grilled Veg Sandwich',
    cookTimeMinutes: 10,
    difficulty: 'easy',
    ingredients: ['bread', 'potato', 'onion', 'tomato', 'cucumber', 'green chutney', 'butter'],
    steps: [
      'Butter the bread and spread green chutney inside.',
      'Layer sliced boiled potato, onion, tomato and cucumber; season.',
      'Close the sandwich and grill until crisp and golden.',
      'Slice diagonally and serve with ketchup.',
    ],
    imageUrl: 'https://loremflickr.com/640/400/grilled,sandwich,food?lock=30',
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