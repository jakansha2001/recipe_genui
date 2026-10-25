import 'package:flutter/material.dart';

import 'package:recipe_genui/app/theme.dart';
import 'package:recipe_genui/ui/home_page.dart';

class SageApp extends StatelessWidget {
  const SageApp({super.key, required this.createSession});

  final SessionFactory createSession;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Brand.name,
      debugShowCheckedModeBanner: false,
      theme: buildSageTheme(Brightness.light),
      darkTheme: buildSageTheme(Brightness.dark),
      home: SageHomePage(createSession: createSession),
    );
  }
}
