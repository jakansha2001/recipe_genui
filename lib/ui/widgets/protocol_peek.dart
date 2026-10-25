import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';

import 'package:recipe_genui/app/theme.dart';

/// A collapsible view of raw A2UI messages — the JSON behind a surface, or an
/// action going back to the model. Teaching aid: the model sends data, not
/// code, and any A2UI renderer could draw the same messages.
class ProtocolPeek extends StatefulWidget {
  const ProtocolPeek({super.key, required this.label, required this.messages});

  final String label;
  final List<JsonMap> messages;

  @override
  State<ProtocolPeek> createState() => _ProtocolPeekState();
}

class _ProtocolPeekState extends State<ProtocolPeek> {
  static const _encoder = JsonEncoder.withIndent('  ');

  bool _expanded = false;

  // Pretty-printing can be large; do it only when opened, and only again if
  // more messages arrived.
  String? _json;
  int _encodedCount = -1;

  String get _prettyJson {
    if (_encodedCount != widget.messages.length) {
      _json = widget.messages.map(_encoder.convert).join('\n\n');
      _encodedCount = widget.messages.length;
    }
    return _json!;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.sage;
    final count = widget.messages.length;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.data_object,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${widget.label} · $count '
                      '${count == 1 ? 'message' : 'messages'}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _expanded
                ? DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.code,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.all(12),
                      child: SelectableText(
                        _prettyJson,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontFamilyFallback: const ['Menlo', 'Courier'],
                          fontSize: 11.5,
                          height: 1.4,
                          color: c.onCode,
                        ),
                      ),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
