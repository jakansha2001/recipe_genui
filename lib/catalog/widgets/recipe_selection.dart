import 'package:flutter/widgets.dart';

/// Which recipe the user last opened, shared with the cards inside generated
/// surfaces so the chosen one stays highlighted across the transcript.
///
/// Catalog widgets are built by genui, not by us, so state reaches them
/// through the widget tree rather than constructor arguments.
class RecipeSelection extends InheritedNotifier<ValueNotifier<String?>> {
  const RecipeSelection({
    super.key,
    required ValueNotifier<String?> selected,
    required super.child,
  }) : super(notifier: selected);

  /// The selection above [context], or null when there is none (as in tests
  /// that render a surface on its own).
  static ValueNotifier<String?>? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RecipeSelection>()?.notifier;
}
