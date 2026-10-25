/// The recipe model — the trusted facts the app owns.
///
/// The talk's core principle: *the model proposes, your data disposes.* The
/// model only ever references a recipe by [Recipe.id]; titles, times, amounts
/// and default steps always come from here.
library;

/// How hard a recipe is.
enum Difficulty {
  easy,
  medium,
  hard;

  String get label => name;
}

/// What an ingredient amount is measured in, and how scaled amounts round.
enum Unit {
  gram('g', metric: true),
  millilitre('ml', metric: true),
  teaspoon('tsp'),
  tablespoon('tbsp'),
  cup('cup'),

  /// A count of whole items ("2" onions); the ingredient name says what.
  piece('');

  const Unit(this.symbol, {this.metric = false});

  final String symbol;

  /// Metric amounts round to whole numbers (to 5 once they're large); others
  /// round to the nearest quarter, which is how people measure spoons.
  final bool metric;
}

/// One ingredient line. A null [amount] means "to taste".
class Ingredient {
  const Ingredient(this.name, [this.amount, this.unit = Unit.piece]);

  final String name;
  final double? amount;
  final Unit unit;

  /// The amount for [factor] times the recipe's base servings, formatted for
  /// display ("200 g", "1½ tsp", "2"), or null when it's "to taste".
  String? formatAmount({double factor = 1}) {
    final base = amount;
    if (base == null) return null;
    final scaled = _round(base * factor);
    final number = unit.metric ? '${scaled.round()}' : _fraction(scaled);
    return unit.symbol.isEmpty ? number : '$number ${unit.symbol}';
  }

  double _round(double value) {
    if (unit.metric) {
      return value >= 20 ? (value / 5).round() * 5 : value.roundToDouble();
    }
    final quarters = (value * 4).round();
    return (quarters < 1 ? 1 : quarters) / 4;
  }

  static const _fractions = {1: '¼', 2: '½', 3: '¾'};

  static String _fraction(double value) {
    final whole = value.floor();
    final quarters = ((value - whole) * 4).round();
    final fraction = _fractions[quarters] ?? '';
    if (whole == 0) return fraction.isEmpty ? '0' : fraction;
    return '$whole$fraction';
  }
}

class Recipe {
  const Recipe({
    required this.id,
    required this.title,
    required this.cookTimeMinutes,
    required this.difficulty,
    required this.servings,
    required this.ingredients,
    required this.steps,
  });

  /// Stable identifier. This is the ONLY field the model sends back to us.
  final String id;
  final String title;
  final int cookTimeMinutes;
  final Difficulty difficulty;

  /// How many people the listed [ingredients] amounts serve.
  final int servings;
  final List<Ingredient> ingredients;

  /// Canonical steps. The model may *adapt* these (e.g. drop a blender step),
  /// but these are the trustworthy default.
  final List<String> steps;

  /// The bundled photo, named after the id. Bundled rather than fetched so a
  /// demo never depends on a third-party image service; see photo_credits.dart.
  String get imageAsset => 'assets/images/recipes/$id.jpg';
}
