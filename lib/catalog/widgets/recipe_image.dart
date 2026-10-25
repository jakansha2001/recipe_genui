import 'package:flutter/material.dart';

/// A recipe's header photo, bundled with the app.
///
/// It is decoded at the size it's shown (`cacheWidth`) rather than full
/// resolution, which keeps memory flat as the transcript grows, and fades in
/// once decoded.
class RecipeImage extends StatelessWidget {
  const RecipeImage(this.asset, {super.key, required this.height});

  final String asset;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: ColoredBox(
        color: scheme.secondaryContainer,
        child: LayoutBuilder(
          builder: (context, constraints) => Image.asset(
            asset,
            fit: BoxFit.cover,
            cacheWidth: constraints.hasBoundedWidth
                ? (constraints.maxWidth *
                          MediaQuery.devicePixelRatioOf(context))
                      .round()
                : null,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) =>
                wasSynchronouslyLoaded
                ? child
                : AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    child: child,
                  ),
            errorBuilder: (context, error, stackTrace) => Center(
              child: Icon(
                Icons.restaurant_menu,
                size: 44,
                color: scheme.onSecondaryContainer,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
