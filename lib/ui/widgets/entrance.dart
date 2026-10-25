import 'dart:async';

import 'package:flutter/material.dart';

/// Fades and lifts [child] in the first time an entry appears.
///
/// List items are rebuilt as they scroll back into view, so whether an entry
/// has already been introduced is remembered in [seen], not in this widget's
/// state. Skipped when the platform asks for reduced motion.
class Entrance extends StatefulWidget {
  const Entrance({
    super.key,
    required this.id,
    required this.seen,
    required this.child,
  });

  final int id;
  final Set<int> seen;
  final Widget child;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    value: widget.seen.add(widget.id) ? 0 : 1,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (_controller.value == 0) {
      unawaited(_controller.forward());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(_curve),
        child: widget.child,
      ),
    );
  }
}
