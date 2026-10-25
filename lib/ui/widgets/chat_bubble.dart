import 'package:flutter/material.dart';

import 'package:recipe_genui/app/theme.dart';

/// A message bubble: the user's on the right in the action colour, the
/// model's on the left on the surface colour.
class ChatBubble extends StatelessWidget {
  const ChatBubble.user({super.key, required this.child}) : fromUser = true;

  const ChatBubble.assistant({super.key, required this.child})
    : fromUser = false;

  final bool fromUser;
  final Widget child;

  static const _radius = Radius.circular(18);

  @override
  Widget build(BuildContext context) {
    final c = context.sage;
    return Align(
      alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 12,
          left: fromUser ? 48 : 0,
          right: fromUser ? 0 : 48,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: fromUser ? c.action : c.surface,
          border: fromUser ? null : Border.all(color: c.border),
          borderRadius: BorderRadius.only(
            topLeft: _radius,
            topRight: _radius,
            bottomLeft: fromUser ? _radius : const Radius.circular(4),
            bottomRight: fromUser ? const Radius.circular(4) : _radius,
          ),
        ),
        child: DefaultTextStyle.merge(
          style: TextStyle(
            fontSize: 15,
            height: 1.35,
            color: fromUser ? c.onAction : c.ink,
          ),
          child: child,
        ),
      ),
    );
  }
}
