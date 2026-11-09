import 'package:flutter/material.dart';

import 'app_services.dart';
import 'data/content_repository.dart';
import 'data/progress_store.dart';
import 'runner/code_runner.dart';
import 'runner/webview_runner.dart';
import 'screens/root_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final progress = await ProgressStore.load();
  // Beide Sprachen laufen direkt am Handy – ohne Server, ohne Anmeldung.
  final runners = <String, CodeRunner>{
    'python': WebViewRunner.python(),
    'csharp': WebViewRunner.csharp(),
  };

  runApp(ProgTrainerApp(
    repository: ContentRepository(),
    progress: progress,
    runnerFor: (runtime) => runners[runtime],
  ));
}

class ProgTrainerApp extends StatefulWidget {
  const ProgTrainerApp({
    super.key,
    required this.repository,
    required this.progress,
    required this.runnerFor,
  });

  final ContentRepository repository;
  final ProgressStore progress;
  final CodeRunner? Function(String runtime) runnerFor;

  @override
  State<ProgTrainerApp> createState() => _ProgTrainerAppState();
}

class _ProgTrainerAppState extends State<ProgTrainerApp> {
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    widget.progress.onAchievementUnlocked = (a) {
      _messengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(a.icon, color: Colors.amber),
              const SizedBox(width: 12),
              Expanded(child: Text('Achievement freigeschaltet: ${a.title}')),
            ],
          ),
        ),
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    return AppServices(
      repository: widget.repository,
      progress: widget.progress,
      runnerFor: widget.runnerFor,
      child: MaterialApp(
        title: 'Prog Trainer',
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: _messengerKey,
        theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
        home: const RootScreen(),
      ),
    );
  }
}
