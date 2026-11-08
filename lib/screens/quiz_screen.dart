import 'package:flutter/material.dart';

import '../app_services.dart';
import '../models/content.dart';
import '../widgets/code_block.dart';
import '../widgets/option_tile.dart';

/// Multiple-Choice-Quiz zu einer Lektion – mit sofortigem Feedback.
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.lesson, required this.lessonPath});

  final Lesson lesson;
  final String lessonPath;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _index = 0;
  int? _selected;
  int _correctCount = 0;

  List<QuizQuestion> get _questions => widget.lesson.quiz;

  void _select(int option) {
    if (_selected != null) return;
    setState(() {
      _selected = option;
      if (option == _questions[_index].correctIndex) _correctCount++;
    });
  }

  void _next() {
    setState(() {
      _index++;
      _selected = null;
    });
    if (_index >= _questions.length) {
      AppServices.of(context).progress.completeLesson(widget.lessonPath);
    }
  }

  void _restart() {
    setState(() {
      _index = 0;
      _selected = null;
      _correctCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Quiz: ${widget.lesson.title}')),
      body: _index >= _questions.length ? _buildResult() : _buildQuestion(),
    );
  }

  Widget _buildQuestion() {
    final q = _questions[_index];
    final answered = _selected != null;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        LinearProgressIndicator(value: _index / _questions.length),
        const SizedBox(height: 12),
        Text('Frage ${_index + 1} von ${_questions.length}',
            style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        Text(q.question, style: theme.textTheme.titleLarge),
        if (q.code != null) CodeBlock(q.code!),
        const SizedBox(height: 12),
        for (var i = 0; i < q.options.length; i++)
          OptionTile(
            text: q.options[i],
            state: !answered
                ? OptionState.neutral
                : i == q.correctIndex
                    ? OptionState.correct
                    : i == _selected
                        ? OptionState.wrong
                        : OptionState.neutral,
            onTap: () => _select(i),
          ),
        if (answered) ...[
          const SizedBox(height: 12),
          Text(
            _selected == q.correctIndex ? 'Richtig! 🎉' : 'Leider falsch.',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(q.explanation, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _next,
            child: Text(
                _index + 1 < _questions.length ? 'Nächste Frage' : 'Ergebnis'),
          ),
        ],
      ],
    );
  }

  Widget _buildResult() {
    final theme = Theme.of(context);
    final total = _questions.length;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _correctCount == total ? Icons.emoji_events : Icons.school,
              size: 72,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text('$_correctCount von $total richtig',
                style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text('Lektion abgeschlossen ✓'),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: _restart,
              child: const Text('Nochmal versuchen'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () {
                Navigator.of(context)
                  ..pop()
                  ..pop();
              },
              child: const Text('Zurück zum Kapitel'),
            ),
          ],
        ),
      ),
    );
  }
}
