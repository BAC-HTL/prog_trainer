import 'package:flutter/material.dart';

import '../app_services.dart';
import '../models/challenge.dart';
import '../models/content.dart';
import '../runner/code_runner.dart';
import '../widgets/code_block.dart';
import '../widgets/code_editor.dart';
import 'settings_screen.dart';

/// Eine Herausforderung: Code schreiben, ausführen, gegen Tests prüfen.
class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({
    super.key,
    required this.track,
    required this.challenge,
  });

  final Track track;
  final Challenge challenge;

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  late final TextEditingController _code =
      TextEditingController(text: widget.challenge.starterCode);
  bool _running = false;
  RunResult? _runResult;
  List<TestOutcome>? _outcomes;
  int _failedAttempts = 0;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  CodeRunner? get _runner {
    final runtime = widget.track.runtime;
    return runtime == null ? null : AppServices.of(context).runnerFor(runtime);
  }

  Future<void> _run() async {
    final runner = _runner;
    if (runner == null) return;
    setState(() {
      _running = true;
      _outcomes = null;
    });
    final tests = widget.challenge.tests;
    final result = await runner.run(_code.text,
        stdin: tests.isEmpty ? '' : tests.first.stdin);
    if (!mounted) return;
    setState(() {
      _running = false;
      _runResult = result;
    });
  }

  Future<void> _check() async {
    final runner = _runner;
    if (runner == null) return;
    setState(() {
      _running = true;
      _runResult = null;
    });
    final outcomes = await runTests(runner, _code.text, widget.challenge.tests);
    if (!mounted) return;
    final allPassed = outcomes.length == widget.challenge.tests.length &&
        outcomes.every((o) => o.passed);
    setState(() {
      _running = false;
      _outcomes = outcomes;
      if (!allPassed) _failedAttempts++;
    });
    if (allPassed) {
      final progress = AppServices.of(context).progress;
      final isNew =
          await progress.solveChallenge(widget.track.id, widget.challenge);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isNew
            ? 'Gelöst! +${widget.challenge.points} Punkte 🎉'
            : 'Wieder gelöst – Punkte gibt es nur beim ersten Mal.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.challenge;
    final theme = Theme.of(context);
    final progress = AppServices.of(context).progress;
    final runner = _runner;
    final solved = progress.isSolved(widget.track.id, c.id);
    final example = c.tests.isEmpty ? null : c.tests.first;

    return Scaffold(
      appBar: AppBar(title: Text(c.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            children: [
              Chip(label: Text(widget.track.title)),
              Chip(label: Text(levelTitles[c.level] ?? c.level)),
              Chip(
                avatar: const Icon(Icons.bolt, size: 18),
                label: Text('${c.points} Punkte'),
              ),
              if (solved)
                const Chip(
                  avatar: Icon(Icons.check, size: 18),
                  label: Text('Gelöst'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(c.description, style: theme.textTheme.bodyLarge),
          if (example != null) ...[
            const SizedBox(height: 12),
            Text('Beispiel', style: theme.textTheme.titleSmall),
            if (example.stdin.isNotEmpty) ...[
              const Text('Eingabe:'),
              CodeBlock(example.stdin),
            ],
            const Text('Erwartete Ausgabe:'),
            CodeBlock(example.expected),
          ],
          if (c.hints.isNotEmpty)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              leading: const Icon(Icons.lightbulb_outline),
              title: Text('Tipps (${c.hints.length})'),
              children: [
                for (final h in c.hints)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.arrow_right),
                    title: Text(h),
                  ),
              ],
            ),
          const SizedBox(height: 12),
          if (runner == null)
            _RunnerMissing(track: widget.track)
          else ...[
            Text('Dein Code', style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            CodeEditor(controller: _code),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Ausführen'),
                    onPressed: _running ? null : _run,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.fact_check),
                    label: const Text('Prüfen'),
                    onPressed: _running ? null : _check,
                  ),
                ),
              ],
            ),
            if (_running) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
              const SizedBox(height: 4),
              Text(
                widget.track.runtime == 'python'
                    ? 'Läuft … (beim ersten Mal wird Python geladen, das dauert etwas)'
                    : 'Läuft …',
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (_runResult != null) _RunOutput(result: _runResult!),
            if (_outcomes != null) _TestResults(outcomes: _outcomes!),
          ],
          if (solved || _failedAttempts >= 3)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              leading: const Icon(Icons.visibility),
              title: const Text('Musterlösung anzeigen'),
              children: [CodeBlock(c.solution)],
            ),
        ],
      ),
    );
  }
}

class _RunnerMissing extends StatelessWidget {
  const _RunnerMissing({required this.track});

  final Track track;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${track.title}-Ausführung einrichten',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
                'C#-Code wird auf einem Server (Judge0) kompiliert. Trage in '
                'den Einstellungen einen kostenlosen API-Key ein, dann kannst '
                'du hier Code ausführen.'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
              ),
              child: const Text('Zu den Einstellungen'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RunOutput extends StatelessWidget {
  const _RunOutput({required this.result});

  final RunResult result;

  @override
  Widget build(BuildContext context) {
    final text = [
      if (result.stdout.isNotEmpty) result.stdout,
      if (result.error != null) result.error!,
      if (result.stdout.isEmpty && result.error == null) '(keine Ausgabe)',
    ].join('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text('Ausgabe (mit Eingabe aus dem Beispiel)',
            style: Theme.of(context).textTheme.titleSmall),
        CodeBlock(text),
      ],
    );
  }
}

class _TestResults extends StatelessWidget {
  const _TestResults({required this.outcomes});

  final List<TestOutcome> outcomes;

  @override
  Widget build(BuildContext context) {
    final passed = outcomes.where((o) => o.passed).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text('Tests: $passed von ${outcomes.length} bestanden',
            style: Theme.of(context).textTheme.titleSmall),
        for (var i = 0; i < outcomes.length; i++)
          Card(
            child: ExpansionTile(
              leading: Icon(
                outcomes[i].passed ? Icons.check_circle : Icons.cancel,
                color: outcomes[i].passed ? Colors.green : Colors.red,
              ),
              title: Text('Test ${i + 1}'),
              initiallyExpanded: !outcomes[i].passed,
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (outcomes[i].test.stdin.isNotEmpty) ...[
                  const Text('Eingabe:'),
                  CodeBlock(outcomes[i].test.stdin),
                ],
                const Text('Erwartet:'),
                CodeBlock(outcomes[i].test.expected),
                const Text('Deine Ausgabe:'),
                CodeBlock([
                  outcomes[i].result.stdout,
                  if (outcomes[i].result.error != null)
                    outcomes[i].result.error!,
                ].where((s) => s.isNotEmpty).join('\n').ifEmpty('(leer)')),
              ],
            ),
          ),
      ],
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
