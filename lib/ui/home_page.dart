import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:recipe_genui/catalog/widgets/recipe_selection.dart';
import 'package:recipe_genui/chat/sage_session.dart';
import 'package:recipe_genui/chat/transcript.dart';
import 'package:recipe_genui/ui/widgets/branding.dart';
import 'package:recipe_genui/ui/widgets/composer.dart';
import 'package:recipe_genui/ui/widgets/entrance.dart';
import 'package:recipe_genui/ui/widgets/photo_credits_sheet.dart';
import 'package:recipe_genui/ui/widgets/transcript_tile.dart';

/// Creates the session the home page talks to. The app passes one wired to
/// Gemini; tests pass one with a fake transport.
typedef SessionFactory = SageSession Function();

/// The chat screen: the transcript of messages and generated surfaces, and
/// the composer.
class SageHomePage extends StatefulWidget {
  const SageHomePage({super.key, required this.createSession});

  final SessionFactory createSession;

  @override
  State<SageHomePage> createState() => _SageHomePageState();
}

class _SageHomePageState extends State<SageHomePage> {
  /// How close to the end (in pixels) still counts as "reading the latest",
  /// so streamed text follows without yanking someone reading back.
  static const double _followThreshold = 160;

  int _entryCount = 0;

  late final SageSession _session = widget.createSession()
    ..addListener(_followNewContent);
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final ImagePicker _picker = ImagePicker();

  ImageAttachment? _stagedImage;
  bool _showProtocol = false;
  bool _scrollScheduled = false;

  /// Built tiles, keyed weakly by entry. Entries are immutable — a change
  /// makes a new entry — so reusing the identical widget lets Flutter skip
  /// rebuilding every tile (and every surface) on each streamed chunk.
  Expando<Widget> _tiles = Expando();

  /// Entries that have played their entrance animation.
  final Set<int> _introduced = {};

  Widget _tileFor(TranscriptEntry entry) => _tiles[entry] ??= Entrance(
    key: ValueKey(entry.id),
    id: entry.id,
    seen: _introduced,
    child: TranscriptTile(
      entry: entry,
      session: _session,
      showProtocol: _showProtocol,
    ),
  );

  void _toggleProtocol() => setState(() {
    _showProtocol = !_showProtocol;
    _tiles = Expando(); // every tile renders differently now
  });

  @override
  void dispose() {
    _session
      ..removeListener(_followNewContent)
      ..dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// A new entry (message, action echo, reply, surface, notice) always scrolls
  /// into view. Streamed text growing the last bubble only follows when the
  /// user is already at the end.
  void _followNewContent() {
    final count = _session.entries.length;
    final added = count > _entryCount;
    _entryCount = count;
    // The user just acted on a generated screen (submitted, picked a card):
    // put the keyboard away so the reply has the whole screen.
    if (added && _session.entries.last is UserAction) _dismissKeyboard();
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    if (added ||
        position.maxScrollExtent - position.pixels <= _followThreshold) {
      _scrollToEnd();
    }
  }

  /// Scrolls to the end after the next layout, once per frame at most.
  void _scrollToEnd() {
    if (_scrollScheduled) return;
    _scrollScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollScheduled = false;
      if (!_scroll.hasClients) return;
      unawaited(
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        ),
      );
    });
  }

  Future<void> _pickPhoto() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _stagedImage = (bytes: bytes, mimeType: file.mimeType ?? 'image/jpeg');
    });
  }

  /// Sends a starter prompt as if it had been typed.
  Future<void> _sendPrompt(String prompt) async {
    _input.text = prompt;
    await _send();
  }

  void _dismissKeyboard() => FocusManager.instance.primaryFocus?.unfocus();

  Future<void> _send() async {
    final text = _input.text;
    final image = _stagedImage;
    if (_session.isBusy || (text.trim().isEmpty && image == null)) return;
    _dismissKeyboard();
    _input.clear();
    setState(() => _stagedImage = null);
    _scrollToEnd();
    await _session.send(text, image: image);
  }

  void _breakNextReply() {
    _session.breakNextReply();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'The next reply will arrive with a component missing — watch Sage '
          'repair it.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const SageWordmark(),
        actions: [
          IconButton(
            isSelected: _showProtocol,
            icon: const Icon(Icons.data_object),
            tooltip: _showProtocol
                ? 'Hide A2UI messages'
                : 'Show A2UI messages',
            onPressed: _toggleProtocol,
          ),
          IconButton(
            icon: const Icon(Icons.photo_library_outlined),
            tooltip: 'Photo credits',
            onPressed: () => unawaited(showPhotoCredits(context)),
          ),
          if (kDebugMode)
            ListenableBuilder(
              listenable: _session,
              builder: (context, _) => IconButton(
                isSelected: _session.nextReplyBreaks,
                icon: const Icon(Icons.bug_report_outlined),
                selectedIcon: const Icon(Icons.bug_report),
                tooltip: 'Break the next reply (demo)',
                onPressed: _session.nextReplyBreaks ? null : _breakNextReply,
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RecipeSelection(
                selected: _session.selectedRecipeId,
                child: ListenableBuilder(
                  listenable: _session,
                  builder: (context, _) {
                    final entries = _session.entries;
                    if (entries.isEmpty) {
                      return EmptyState(
                        onPrompt: (prompt) => unawaited(_sendPrompt(prompt)),
                        onPhoto: () => unawaited(_pickPhoto()),
                      );
                    }
                    return ListView.builder(
                      controller: _scroll,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: entries.length,
                      itemBuilder: (context, index) => _tileFor(entries[index]),
                    );
                  },
                ),
              ),
            ),
            ListenableBuilder(
              listenable: _session,
              builder: (context, _) {
                final busy = _session.isBusy;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (busy)
                      const ThinkingIndicator()
                    else
                      const SizedBox(height: 4),
                    Composer(
                      controller: _input,
                      stagedImage: _stagedImage?.bytes,
                      enabled: !busy,
                      onPickPhoto: _pickPhoto,
                      onClearPhoto: () => setState(() => _stagedImage = null),
                      onSend: _send,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
