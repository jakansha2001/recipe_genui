import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:recipe_genui/app/theme.dart';

/// Ready-made first messages, so a demo starts with one tap.
const List<String> starterPrompts = [
  'Something quick with paneer',
  'A cosy dal dinner for 4',
  'Breakfast in 15 minutes',
  'What can I make with eggs?',
];

/// The "Sage" wordmark with its tagline, for the app bar.
class SageWordmark extends StatelessWidget {
  const SageWordmark({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.sage;
    final text = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          Brand.name,
          style: text.headlineSmall?.copyWith(
            color: c.action,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            height: 1.1,
          ),
        ),
        Text(
          Brand.tagline,
          style: text.labelSmall?.copyWith(
            color: c.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// The welcome screen before the first message, with starter prompts.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.onPrompt, required this.onPhoto});

  final ValueChanged<String> onPrompt;
  final VoidCallback onPhoto;

  @override
  Widget build(BuildContext context) {
    final c = context.sage;
    final text = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: c.tint,
                  shape: BoxShape.circle,
                ),
                child: SizedBox.square(
                  dimension: 76,
                  child: Icon(Icons.soup_kitchen, size: 36, color: c.onTint),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'What should we cook?',
                textAlign: TextAlign.center,
                style: text.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                "Tell me what you feel like — or snap your fridge and I'll "
                'build you a menu.',
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(color: c.muted, height: 1.5),
              ),
              const SizedBox(height: 24),
              for (final prompt in starterPrompts)
                _StarterTile(
                  icon: Icons.north_east,
                  label: prompt,
                  onTap: () => onPrompt(prompt),
                ),
              _StarterTile(
                icon: Icons.photo_camera_outlined,
                label: 'Use a photo of my fridge',
                onTap: onPhoto,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StarterTile extends StatelessWidget {
  const _StarterTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.sage;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: SageRadii.controlRadius,
          side: BorderSide(color: c.border),
        ),
        child: InkWell(
          customBorder: const RoundedRectangleBorder(
            borderRadius: SageRadii.controlRadius,
          ),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(icon, size: 18, color: c.action),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown above the composer while the model is answering: three pulsing dots
/// (static when the platform asks for reduced motion).
class ThinkingIndicator extends StatefulWidget {
  const ThinkingIndicator({super.key});

  @override
  State<ThinkingIndicator> createState() => _ThinkingIndicatorState();
}

class _ThinkingIndicatorState extends State<ThinkingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      unawaited(_pulse.repeat());
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sage;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) => Row(
              children: [
                for (var i = 0; i < 3; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Opacity(
                      // Each dot peaks a third of a cycle after the last.
                      opacity:
                          0.3 +
                          0.7 *
                              (0.5 +
                                  0.5 *
                                      math.sin(
                                        2 * math.pi * (_pulse.value - i / 3),
                                      )),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: c.accent,
                          shape: BoxShape.circle,
                        ),
                        child: const SizedBox.square(dimension: 7),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Thinking…',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: c.muted),
          ),
        ],
      ),
    );
  }
}
