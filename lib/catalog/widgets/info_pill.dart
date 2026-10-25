import 'package:flutter/material.dart';

import 'package:recipe_genui/data/recipe.dart';

/// The cook time and difficulty pills shown on every recipe.
class RecipeFacts extends StatelessWidget {
  const RecipeFacts(this.recipe, {super.key});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        InfoPill(icon: Icons.schedule, label: '${recipe.cookTimeMinutes} min'),
        InfoPill(icon: Icons.bar_chart, label: recipe.difficulty.label),
      ],
    );
  }
}

/// A small rounded label with an icon, e.g. "15 min" or "easy".
class InfoPill extends StatelessWidget {
  const InfoPill({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: theme.colorScheme.onSecondaryContainer),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
