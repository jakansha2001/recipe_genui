import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:recipe_genui/app/theme.dart';

/// The input bar: attach a photo, type, send.
class Composer extends StatelessWidget {
  const Composer({
    super.key,
    required this.controller,
    required this.stagedImage,
    required this.enabled,
    required this.onPickPhoto,
    required this.onClearPhoto,
    required this.onSend,
  });

  final TextEditingController controller;
  final Uint8List? stagedImage;

  /// False while the model is answering.
  final bool enabled;
  final VoidCallback onPickPhoto;
  final VoidCallback onClearPhoto;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final stagedImage = this.stagedImage;
    final c = context.sage;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.background,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (stagedImage != null)
              _StagedPhoto(bytes: stagedImage, onClear: onClearPhoto),
            Row(
              children: [
                IconButton(
                  onPressed: enabled ? onPickPhoto : null,
                  icon: const Icon(Icons.add_a_photo_outlined),
                  color: c.action,
                  tooltip: 'Add a fridge photo',
                ),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: c.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: controller,
                        enabled: enabled,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.send,
                        decoration: InputDecoration(
                          hintText: enabled
                              ? 'What should I cook?'
                              : 'Thinking…',
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                        ),
                        onSubmitted: (_) => onSend(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _SendButton(enabled: enabled, onPressed: onSend),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StagedPhoto extends StatelessWidget {
  const _StagedPhoto({required this.bytes, required this.onClear});

  final Uint8List bytes;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              bytes,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              cacheWidth: 132, // 44 logical px at up to 3x
            ),
          ),
          const SizedBox(width: 8),
          const Text('Photo attached'),
          const Spacer(),
          IconButton(
            tooltip: 'Remove photo',
            icon: const Icon(Icons.close, size: 20),
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.sage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: enabled ? c.action : c.border,
      ),
      child: Material(
        type: MaterialType.transparency,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onPressed : null,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.arrow_upward,
              color: enabled ? c.onAction : c.muted,
              semanticLabel: 'Send',
            ),
          ),
        ),
      ),
    );
  }
}
