import 'dart:async';

import 'package:flutter/material.dart';

import 'package:recipe_genui/app/theme.dart';
import 'package:recipe_genui/data/photo_credits.dart';
import 'package:recipe_genui/data/recipes.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shows who took each recipe photo, under which licence, with links.
Future<void> showPhotoCredits(BuildContext context) => showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  builder: (context) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.7,
    maxChildSize: 0.95,
    builder: (context, scrollController) =>
        _PhotoCredits(scrollController: scrollController),
  ),
);

class _PhotoCredits extends StatelessWidget {
  const _PhotoCredits({required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final c = context.sage;
    final text = Theme.of(context).textTheme;
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        Text('Photo credits', style: text.titleLarge),
        const SizedBox(height: 4),
        Text(
          'Thank you to the photographers on Unsplash, Pexels and Wikimedia '
          'Commons.',
          style: text.bodyMedium?.copyWith(color: c.muted),
        ),
        const SizedBox(height: 12),
        for (final recipe in recipes)
          if (photoCredits[recipe.id] case final credit?)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  recipe.imageAsset,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  cacheWidth: 156,
                ),
              ),
              title: Text(recipe.title),
              subtitle: Text('${credit.author} · ${credit.license.label}'),
              trailing: Icon(Icons.open_in_new, size: 18, color: c.action),
              onTap: () => unawaited(
                launchUrl(
                  Uri.parse(credit.source),
                  mode: LaunchMode.externalApplication,
                ),
              ),
            ),
      ],
    );
  }
}
