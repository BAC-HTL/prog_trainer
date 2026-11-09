import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/progress_store.dart';
import '../game/game_logic.dart';
import '../game/mission.dart';
import '../models/content.dart';
import '../runner/code_runner.dart';
import '../widgets/code_block.dart';
import '../widgets/code_editor.dart';
import '../widgets/game_map.dart';
import 'game_screen.dart';

/// Eine Spielmission: Code schreiben, Roboter losschicken, zuschauen.
class MissionScreen extends StatefulWidget {
  const MissionScreen({
    super.key,
    required this.track,
    required this.missions,
    required this.index,
  });

  final Track track;
  final List<Mission> missions;
  final int index;

  @override
  State<MissionScreen> createState() => _MissionScreenState();
}

class _VariantResult {
  _VariantResult(this.output, this.runError, this.finalState, this.goals);

  final SimulationOutput output;
  final String? runError;
  final GameState finalState;
  final List<bool> goals;

  bool get success =>
      runError == null && finalState.error == null && goals.every((g) => g);
}

class _Outcome {
  const _Outcome({required this.success, required this.message, this.stars = 0, this.points = 0});

  final bool success;
  final String message;
  final int stars;
  final int points;
}

class _MissionScreenState extends State<MissionScreen> {
  late final TextEditingController _code =
      TextEditingController(text: _mission.starter[_lang] ?? '');
  late GameState _state = GameState.initial(_mission, _mission.variants.first);
  int _variant = 0;
  bool _running = false;
  int _animationToken = 0;
  int _speed = 1;
  List<String> _console = [];
  String? _runError;
  _Outcome? _outcome;
  int _failedAttempts = 0;
  String? _simSource;

  Mission get _mission => widget.missions[widget.index];
  String get _lang => widget.track.runtime ?? 'python';

  @override
  void dispose() {
    _animationToken++;
    _code.dispose();
    super.dispose();
  }

  void _showVariant(int i) {
    if (_running) return;
    _animationToken++;
    setState(() {
      _variant = i;
      _state = GameState.initial(_mission, _mission.variants[i]);
      _outcome = null;
      _console = [];
      _runError = null;
    });
  }

  Future<void> _start(CodeRunner runner) async {
    final services = AppServices.of(context);
    final token = ++_animationToken;
    setState(() {
      _running = true;
      _outcome = null;
      _runError = null;
      _console = [];
      _state = GameState.initial(_mission, _mission.variants[_variant]);
    });

    _simSource ??= await services.repository.loadSimulation(_lang);
    final program = buildProgram(_lang, _simSource!, _code.text);

    // Alle Karten ausführen (die Lösung muss überall klappen).
    final results = <_VariantResult>[];
    for (final v in _mission.variants) {
      final run = await runner.run(program, stdin: simulationInput(_mission, v));
      final output = parseOutput(run.stdout);
      final end = replay(_mission, v, output.events);
      results.add(_VariantResult(output, run.error, end, checkGoals(_mission, v, end)));
      if (!mounted || token != _animationToken) return;
    }

    // Die erste fehlgeschlagene Karte zeigen – sonst Karte 1.
    final failing = results.indexWhere((r) => !r.success);
    final show = failing >= 0 ? failing : 0;
    final result = results[show];
    setState(() {
      _variant = show;
      _state = GameState.initial(_mission, _mission.variants[show]);
    });

    // Animation
    for (final e in result.output.events) {
      if (e.kind == 'SCAN' && _speed > 2) continue;
      await Future<void>.delayed(Duration(milliseconds: 360 ~/ _speed));
      if (!mounted || token != _animationToken) return;
      setState(() => _state.apply(e));
    }

    final outcome = await _evaluate(results, failing, services.progress);
    if (!mounted || token != _animationToken) return;
    setState(() {
      _running = false;
      _console = result.output.console;
      _runError = result.runError;
      _outcome = outcome;
      if (!outcome.success) _failedAttempts++;
    });
  }

  Future<_Outcome> _evaluate(
      List<_VariantResult> results, int failing, ProgressStore progress) async {
    if (failing < 0) {
      final stars = computeStars(
        mission: _mission,
        language: _lang,
        energyUsed: results.first.finalState.energyUsed,
        lines: countCodeLines(_code.text, _lang),
      );
      final points =
          await progress.recordMission(widget.track.id, _mission.id, stars);
      return _Outcome(
        success: true,
        stars: stars,
        points: points,
        message: 'Mission erfüllt! 🎉',
      );
    }
    final r = results[failing];
    final where = _mission.variants.length > 1 ? ' (Karte ${failing + 1})' : '';
    if (r.runError != null && r.output.events.isEmpty) {
      return _Outcome(success: false, message: 'Dein Programm ist nicht gestartet$where.');
    }
    if (r.finalState.error != null) {
      return _Outcome(success: false, message: '${r.finalState.error}$where');
    }
    if (r.runError != null) {
      return _Outcome(success: false, message: 'Dein Programm ist abgestürzt$where.');
    }
    final hint = failing > 0
        ? ' Auf Karte 1 klappt es – nutze Sensoren statt fester Schritte!'
        : '';
    return _Outcome(success: false, message: 'Noch nicht alle Ziele erfüllt$where.$hint');
  }

  void _skipAnimation() {
    if (!_running) return;
    setState(() => _speed = 8);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final runner = AppServices.of(context).runnerFor(_lang);
    final progress = AppServices.of(context).progress;
    final variant = _mission.variants[_variant];
    final goals = checkGoals(_mission, variant, _state);
    final bestStars = progress.missionStars(widget.track.id, _mission.id);
    final hasNext = widget.index + 1 < widget.missions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.index + 1}. ${_mission.title}'),
        actions: [
          IconButton(
            tooltip: 'Befehle',
            icon: const Icon(Icons.menu_book),
            onPressed: () => showRobotApi(context, _lang),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(_mission.story, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            Chip(label: Text(widget.track.title)),
            Chip(avatar: const Icon(Icons.school, size: 18), label: Text(_mission.concept)),
            Chip(avatar: const Text('🔋'), label: Text('Akku ${_mission.energy}')),
          ]),
          const SizedBox(height: 8),
          Text('Ziele', style: theme.textTheme.titleSmall),
          for (var i = 0; i < _mission.goals.length; i++)
            Row(children: [
              Icon(goals[i] ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 20, color: goals[i] ? Colors.green : Colors.grey),
              const SizedBox(width: 8),
              Expanded(child: Text(_mission.goals[i].description)),
            ]),
          const SizedBox(height: 12),
          if (_mission.variants.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Wrap(spacing: 8, children: [
                for (var i = 0; i < _mission.variants.length; i++)
                  ChoiceChip(
                    label: Text('Karte ${i + 1}'),
                    selected: _variant == i,
                    onSelected: _running ? null : (_) => _showVariant(i),
                  ),
              ]),
            ),
          GameMap(state: _state),
          const SizedBox(height: 8),
          Row(children: [
            Text('🔋 ${_state.energy}/${_state.startEnergy}'),
            const SizedBox(width: 16),
            Expanded(
              child: Text('🎒 ${inventoryText(_state.inventory)}',
                  overflow: TextOverflow.ellipsis),
            ),
            if (_state.scanned != null) Text('📡 ${_state.scanned}'),
          ]),
          const SizedBox(height: 4),
          const GameLegend(),
          if (_outcome != null) _OutcomeCard(
            outcome: _outcome!,
            hasNext: hasNext,
            onNext: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => MissionScreen(
                  track: widget.track,
                  missions: widget.missions,
                  index: widget.index + 1,
                ),
              ),
            ),
          ),
          if (_runError != null) ...[
            const SizedBox(height: 8),
            Text('Fehlermeldung', style: theme.textTheme.titleSmall),
            CodeBlock(_runError!),
          ],
          if (_console.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Ausgabe deines Programms', style: theme.textTheme.titleSmall),
            CodeBlock(_console.join('\n')),
          ],
          const SizedBox(height: 16),
          Row(children: [
            Text('Dein Code', style: theme.textTheme.titleSmall),
            const Spacer(),
            if (bestStars > 0)
              for (var s = 1; s <= 3; s++)
                Icon(s <= bestStars ? Icons.star : Icons.star_border,
                    size: 18, color: Colors.amber.shade700),
          ]),
          const SizedBox(height: 6),
          if (runner == null)
            const Text('Für diese Sprache gibt es noch keine Code-Ausführung.')
          else ...[
            CodeEditor(controller: _code, minLines: 8),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Roboter starten'),
                  onPressed: _running ? null : () => _start(runner),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                tooltip: _running ? 'Schneller' : 'Geschwindigkeit: ${_speed}x',
                onPressed: _running
                    ? _skipAnimation
                    : () => setState(() => _speed = _speed >= 4 ? 1 : _speed * 2),
                icon: Text(_running ? '⏩' : '${_speed}x'),
              ),
            ]),
            if (_running) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(),
              Text('Beim ersten Start wird ${widget.track.title} geladen, das dauert etwas.',
                  style: theme.textTheme.bodySmall),
            ],
          ],
          const SizedBox(height: 8),
          Text('Stern-Ziele: ⭐ lösen · ⭐ höchstens ${_mission.parEnergy} Energie '
              '(Karte 1) · ⭐ höchstens ${_mission.parLines[_lang]} Codezeilen',
              style: theme.textTheme.bodySmall),
          if (_mission.hints.isNotEmpty)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              leading: const Icon(Icons.lightbulb_outline),
              title: Text('Tipps (${_mission.hints.length})'),
              children: [
                for (final h in _mission.hints)
                  ListTile(dense: true, leading: const Icon(Icons.arrow_right), title: Text(h)),
              ],
            ),
          if (bestStars > 0 || _failedAttempts >= 3)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              leading: const Icon(Icons.visibility),
              title: const Text('Musterlösung anzeigen'),
              children: [CodeBlock(_mission.solution[_lang] ?? '')],
            ),
          TextButton.icon(
            icon: const Icon(Icons.restart_alt),
            label: const Text('Code zurücksetzen'),
            onPressed: _running
                ? null
                : () => setState(() => _code.text = _mission.starter[_lang] ?? ''),
          ),
        ],
      ),
    );
  }
}

class _OutcomeCard extends StatelessWidget {
  const _OutcomeCard({required this.outcome, required this.hasNext, required this.onNext});

  final _Outcome outcome;
  final bool hasNext;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(top: 12),
      color: outcome.success ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(outcome.message, style: theme.textTheme.titleMedium),
            if (outcome.success) ...[
              const SizedBox(height: 8),
              Row(children: [
                for (var s = 1; s <= 3; s++)
                  Icon(s <= outcome.stars ? Icons.star : Icons.star_border,
                      size: 32, color: Colors.amber.shade700),
                const SizedBox(width: 12),
                if (outcome.points > 0) Text('+${outcome.points} Punkte'),
              ]),
              if (hasNext) ...[
                const SizedBox(height: 8),
                FilledButton(onPressed: onNext, child: const Text('Nächste Mission')),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
