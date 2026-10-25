import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logging/logging.dart';

import 'package:recipe_genui/agent/gemini_transport.dart';
import 'package:recipe_genui/app/app_check.dart';
import 'package:recipe_genui/app/sage_app.dart';
import 'package:recipe_genui/catalog/recipe_catalog.dart';
import 'package:recipe_genui/chat/sage_session.dart';
import 'package:recipe_genui/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Fonts are bundled in assets/google_fonts; never fetch them at runtime.
  GoogleFonts.config.allowRuntimeFetching = false;
  if (kDebugMode) _logToConsole();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await activateAppCheck();
  runApp(const SageApp(createSession: createGeminiSession));
}

/// The composition root: a session backed by Gemini through Firebase AI Logic.
SageSession createGeminiSession() => SageSession(
  transport: GeminiTransport(systemInstruction: recipeSystemInstruction),
  catalog: recipeCatalog,
);

void _logToConsole() {
  Logger.root
    ..level = Level.INFO
    ..onRecord.listen((record) {
      debugPrint(
        '[${record.loggerName}] ${record.message}'
        '${record.error == null ? '' : ' — ${record.error}'}',
      );
    });
}
