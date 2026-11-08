import 'package:flutter/material.dart';

import 'data/content_repository.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(ProgTrainerApp(repository: ContentRepository()));
}

class ProgTrainerApp extends StatelessWidget {
  const ProgTrainerApp({super.key, required this.repository});

  final ContentRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prog Trainer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: HomeScreen(repository: repository),
    );
  }
}
