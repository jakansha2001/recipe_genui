import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'agent/recipe_backend.dart';
import 'catalog/recipe_catalog.dart';
import 'firebase_options.dart';

/// App identity. Rename here to rebrand the whole app.
const String kAppName = 'Sage';
const String kAppTagline = 'Cook with what you have';

// Fresh, modern palette — emerald green with a green -> teal gradient.
const Color kSeed = Color(0xFF12B76A); // fresh emerald (primary)
const Color kAccent = Color(0xFF0E9488); // deep teal (accent)
const Color kCream = Color(0xFFF5FAF7); // soft mint-white background
const Color kInk = Color(0xFF18261F); // deep green-charcoal text

/// Green -> teal gradient used on the wordmark and the send button.
const List<Color> kBrandGradient = [
  Color(0xFF2BD46F), // fresh green
  Color(0xFF0E9488), // teal
];
const LinearGradient kBrandLinearGradient = LinearGradient(
  colors: kBrandGradient,
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SageApp());
}

class SageApp extends StatelessWidget {
  const SageApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: kSeed,
      brightness: Brightness.light,
    ).copyWith(surface: kCream, secondary: kAccent);

    final baseText = GoogleFonts.interTextTheme().apply(
      bodyColor: kInk,
      displayColor: kInk,
    );

    return MaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: kCream,
        textTheme: baseText,
        appBarTheme: const AppBarTheme(
          backgroundColor: kCream,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      home: const SageHomePage(),
    );
  }
}

/// One entry in the visible conversation: either the user's own message
/// (so they can see what they sent) or a model-generated surface.
/// What kind of entry this is in the visible transcript.
enum _ItemKind { user, modelText, surface, error }

/// One entry in the visible conversation. The model talks on two channels —
/// generated UI (surfaces) and plain text — and errors arrive on a third, so
/// the transcript has to be able to show all of them.
class _ChatItem {
  _ChatItem.user({this.text, this.imageBytes})
      : kind = _ItemKind.user,
        surfaceId = null;
  _ChatItem.modelText(this.text)
      : kind = _ItemKind.modelText,
        imageBytes = null,
        surfaceId = null;
  _ChatItem.surface(this.surfaceId)
      : kind = _ItemKind.surface,
        text = null,
        imageBytes = null;
  _ChatItem.error(this.text)
      : kind = _ItemKind.error,
        imageBytes = null,
        surfaceId = null;

  final _ItemKind kind;
  String? text; // mutable so streamed model text can accumulate
  final Uint8List? imageBytes;
  final String? surfaceId;
}

class SageHomePage extends StatefulWidget {
  const SageHomePage({super.key});

  @override
  State<SageHomePage> createState() => _SageHomePageState();
}

class _SageHomePageState extends State<SageHomePage> {
  late final SurfaceController _surfaceController;
  late final RecipeBackend _backend;
  late final Conversation _conversation;

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  // The visible transcript (user messages + model surfaces, in order).
  final List<_ChatItem> _items = [];
  final Set<String> _seenSurfaces = {};
  StreamSubscription<ConversationEvent>? _eventsSub;
  StreamSubscription<ChatMessage>? _submitSub;

  ({Uint8List bytes, String mimeType})? _stagedImage;

  @override
  void initState() {
    super.initState();
    _surfaceController = SurfaceController(catalogs: [recipeCatalog]);
    _backend = RecipeBackend();
    _conversation = Conversation(
      controller: _surfaceController,
      transport: _backend.transport,
    );
    // Listen to the conversation's event stream so we can show generated
    // surfaces, the model's plain-text replies, AND errors (which the SDK
    // otherwise swallows). Each becomes a transcript entry, in arrival order.
    _eventsSub = _conversation.events.listen(_onEvent);

    // When the user acts on a widget (picks chips + submits, taps a card, taps
    // an adjust chip), add a right-side bubble echoing their choice — so they
    // can see what they selected. We do NOT remove the panel: it stays in the
    // history and remains usable, so they can scroll back and pick again.
    // (onSubmit is a broadcast stream, so this second listener is safe.)
    _submitSub = _surfaceController.onSubmit.listen(_onUserSubmit);
  }

  void _onUserSubmit(ChatMessage message) {
    final summary = _summarizeInteraction(message);
    if (summary == null) return; // skip non-informative submits
    setState(() => _items.add(_ChatItem.user(text: summary)));
    _scrollToBottom();
  }

  /// Best-effort, comma-separated summary of what the user selected, pulled from
  /// the interaction payload's action context. Returns null if there's nothing
  /// readable to show.
  String? _summarizeInteraction(ChatMessage message) {
    for (final part in message.parts) {
      if (!part.isUiInteractionPart) continue;
      try {
        final json = jsonDecode(part.asUiInteractionPart!.interaction)
            as Map<String, dynamic>;
        final action = json['action'] as Map<String, dynamic>?;
        final context = action?['context'] as Map<String, dynamic>?;
        if (context == null || context.isEmpty) return null;

        if (context['title'] != null) return 'Selected: ${context['title']}';
        if (context['adjustment'] != null) {
          return 'Adjust: ${context['adjustment']}';
        }

        final bits = <String>[];
        context.forEach((key, value) {
          if (key.toLowerCase().contains('id')) return;
          if (value is List) {
            bits.addAll(value.map((e) => e.toString()));
          } else if (value is String && value.isNotEmpty) {
            bits.add(value);
          } else if (value is num) {
            bits.add('$value');
          }
        });
        return bits.isEmpty ? null : bits.join(', ');
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  void _onEvent(ConversationEvent event) {
    switch (event) {
      case ConversationSurfaceAdded(:final surfaceId):
        if (_seenSurfaces.add(surfaceId)) {
          // Keep the full transcript — every new surface is appended, nothing
          // is wiped. (Used interactive panels are collapsed into bubbles by
          // _onUserSubmit instead.)
          setState(() => _items.add(_ChatItem.surface(surfaceId)));
          _scrollToBottom();
        }
      case ConversationContentReceived(:final text):
        final trimmed = text.trim();
        if (trimmed.isEmpty) break;
        setState(() {
          // Merge consecutive text chunks into one model bubble.
          if (_items.isNotEmpty && _items.last.kind == _ItemKind.modelText) {
            _items.last.text = '${_items.last.text} $trimmed'.trim();
          } else {
            _items.add(_ChatItem.modelText(trimmed));
          }
        });
        _scrollToBottom();
      case ConversationError(:final error):
        debugPrint('GenUI ConversationError: $error');
        setState(() => _items.add(_ChatItem.error(error.toString())));
        _scrollToBottom();
      default:
        break;
    }
  }

  @override
  void dispose() {
    _eventsSub?.cancel();
    _submitSub?.cancel();
    _conversation.dispose();
    _backend.dispose();
    _surfaceController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickFridgePhoto() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _stagedImage = (bytes: bytes, mimeType: file.mimeType ?? 'image/jpeg');
    });
  }

  Future<void> _send() async {
    // Don't allow a new request while one is already in flight.
    if (_conversation.state.value.isWaiting) return;
    final text = _textController.text.trim();
    final staged = _stagedImage;
    if (text.isEmpty && staged == null) return;

    // Echo the user's message into the transcript immediately.
    setState(() {
      _items.add(_ChatItem.user(text: text, imageBytes: staged?.bytes));
      _stagedImage = null;
    });
    _textController.clear();
    _scrollToBottom();

    final parts = <StandardPart>[
      if (staged != null) DataPart(staged.bytes, mimeType: staged.mimeType),
    ];
    await _conversation.sendRequest(ChatMessage.user(text, parts: parts));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (bounds) =>
                  kBrandLinearGradient.createShader(bounds),
              child: Text(
                kAppName,
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: Colors.white, // painted over by the gradient shader
                ),
              ),
            ),
            Text(
              kAppTagline,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: kInk.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _items.isEmpty
                  ? const _EmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: _items.length,
                      itemBuilder: (context, i) => _buildItem(_items[i]),
                    ),
            ),
            ValueListenableBuilder<ConversationState>(
              valueListenable: _conversation.state,
              builder: (context, state, _) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  state.isWaiting
                      ? const _ThinkingRow()
                      : const SizedBox(height: 4),
                  _Composer(
                    textController: _textController,
                    stagedImage: _stagedImage?.bytes,
                    isBusy: state.isWaiting,
                    onPickPhoto: _pickFridgePhoto,
                    onClearPhoto: () => setState(() => _stagedImage = null),
                    onSend: _send,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(_ChatItem item) {
    switch (item.kind) {
      case _ItemKind.user:
        return Align(
          alignment: Alignment.centerRight,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12, left: 48),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kSeed,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (item.imageBytes != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(
                        item.imageBytes!,
                        width: 140,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                if (item.text != null && item.text!.isNotEmpty)
                  Text(
                    item.text!,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
              ],
            ),
          ),
        );

      case _ItemKind.modelText:
        // The model replied in prose instead of generating UI. Showing it means
        // a text-only turn is never invisible to the user.
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12, right: 48),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: const Color(0x14000000)),
            ),
            child: Text(item.text ?? '', style: const TextStyle(fontSize: 15)),
          ),
        );

      case _ItemKind.surface:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12, right: 16),
          child: Surface(
            surfaceContext: _surfaceController.contextFor(item.surfaceId!),
          ),
        );

      case _ItemKind.error:
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFCEBEB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0A0A0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline, color: Color(0xFFA32D2D), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.text ?? 'Something went wrong.',
                  style: const TextStyle(color: Color(0xFF791F1F), fontSize: 13),
                ),
              ),
            ],
          ),
        );
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                gradient: kBrandLinearGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.restaurant_menu,
                  size: 38, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              'What should we cook?',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: kInk,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tell me what you feel like — or snap a photo of\nyour fridge and I\'ll suggest something.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: kInk.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThinkingRow extends StatelessWidget {
  const _ThinkingRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: kSeed),
          ),
          const SizedBox(width: 10),
          Text(
            'Thinking…',
            style: TextStyle(color: kInk.withValues(alpha: 0.6), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.textController,
    required this.stagedImage,
    required this.isBusy,
    required this.onPickPhoto,
    required this.onClearPhoto,
    required this.onSend,
  });

  final TextEditingController textController;
  final Uint8List? stagedImage;
  final bool isBusy;
  final VoidCallback onPickPhoto;
  final VoidCallback onClearPhoto;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: kCream,
        border: Border(top: BorderSide(color: Color(0x14000000))),
      ),
      child: Column(
        children: [
          if (stagedImage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      stagedImage!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Photo attached'),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: onClearPhoto,
                  ),
                ],
              ),
            ),
          Row(
            children: [
              IconButton(
                onPressed: isBusy ? null : onPickPhoto,
                icon: const Icon(Icons.add_a_photo_outlined),
                color: kSeed,
                tooltip: 'Add a fridge photo',
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0x1A000000)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: textController,
                    enabled: !isBusy,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: isBusy ? 'Thinking...' : 'What should I cook?',
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => onSend(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isBusy ? null : kBrandLinearGradient,
                  color: isBusy ? Colors.grey.shade400 : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: isBusy ? null : onSend,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        isBusy ? Icons.stop : Icons.arrow_upward,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}