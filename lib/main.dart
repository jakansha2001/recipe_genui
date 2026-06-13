import 'package:flutter/material.dart';

void main() {
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
      home: const _Placeholder(),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recipe GenUI')),
      body: const Center(
        child: Text("Step 1 checkpoint: the app runs.\nGenUI comes next."),
      ),
    );
  }
}