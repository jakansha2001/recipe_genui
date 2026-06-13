import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:image_picker/image_picker.dart';

import 'agent/recipe_backend.dart';
import 'catalog/recipe_catalog.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase AI Logic needs Firebase initialized before any model call.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const RecipeGenUiApp());
}

class RecipeGenUiApp extends StatelessWidget {
  const RecipeGenUiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recipe GenUI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE8593C)),
        useMaterial3: true,
      ),
      home: const RecipeHomePage(),
    );
  }
}

class RecipeHomePage extends StatefulWidget {
  const RecipeHomePage({super.key});

  @override
  State<RecipeHomePage> createState() => _RecipeHomePageState();
}

class _RecipeHomePageState extends State<RecipeHomePage> {
  // The three pieces from the architecture diagram, assembled:
  late final SurfaceController _surfaceController; // renders catalog widgets
  late final RecipeBackend _backend; // Gemini via Firebase AI Logic
  late final Conversation _conversation; // orchestrates the loop

  final TextEditingController _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // A fridge photo staged to send with the next message.
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
  }

  @override
  void dispose() {
    _conversation.dispose();
    _backend.dispose();
    _surfaceController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickFridgePhoto() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery, // gallery is reliable for recording
      maxWidth: 1024,
    );
    if (file == null) return;
    final Uint8List bytes = await file.readAsBytes();
    setState(() {
      _stagedImage = (bytes: bytes, mimeType: file.mimeType ?? 'image/jpeg');
    });
  }

  Future<void> _send() async {
    final String text = _textController.text.trim();
    final staged = _stagedImage;
    if (text.isEmpty && staged == null) return;

    // Build a genui ChatMessage: the typed text, plus the photo (if any) as a
    // DataPart. This is the user's intent entering the loop.
    final parts = <StandardPart>[
      if (staged != null) DataPart(staged.bytes, mimeType: staged.mimeType),
    ];

    _textController.clear();
    setState(() => _stagedImage = null);

    await _conversation.sendRequest(ChatMessage.user(text, parts: parts));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recipe GenUI')),
      body: SafeArea(
        child: Column(
          children: [
            // The generated surfaces stack here, newest at the bottom.
            Expanded(
              child: ValueListenableBuilder<ConversationState>(
                valueListenable: _conversation.state,
                builder: (context, state, _) {
                  if (state.surfaces.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Tell me what you want to cook —\nor snap a photo of your fridge.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: state.surfaces.length,
                    itemBuilder: (context, i) {
                      final String surfaceId = state.surfaces[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Surface(
                          surfaceContext:
                              _surfaceController.contextFor(surfaceId),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Thinking indicator while the model streams.
            ValueListenableBuilder<ConversationState>(
              valueListenable: _conversation.state,
              builder: (context, state, _) => state.isWaiting
                  ? const LinearProgressIndicator(minHeight: 2)
                  : const SizedBox(height: 2),
            ),

            // Staged-photo chip.
            if (_stagedImage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        _stagedImage!.bytes,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('Photo attached'),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _stagedImage = null),
                    ),
                  ],
                ),
              ),

            // Input bar: photo + text + send.
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.photo_camera_outlined),
                    tooltip: 'Add a fridge photo',
                    onPressed: _pickFridgePhoto,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: 'What should I cook?',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    icon: const Icon(Icons.send),
                    onPressed: _send,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}