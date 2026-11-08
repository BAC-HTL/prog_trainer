import 'package:flutter/material.dart';

import '../models/content.dart';
import '../widgets/code_block.dart';

/// Multiple-Choice-Quiz zu einer Lektion.
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.lesson});

  final Lesson lesson;

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
        Text(
          'Frage ${_index + 1} von ${_questions.length}',
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Text(q.question, style: theme.textTheme.titleLarge),
        if (q.code != null) CodeBlock(q.code!),
        const SizedBox(height: 12),
        for (var i = 0; i < q.options.length; i++)
          _OptionTile(
            text: q.options[i],
            state: !answered
                ? _OptionState.neutral
                : i == q.correctIndex
                    ? _OptionState.correct
                    : i == _selected
                        ? _OptionState.wrong
                        : _OptionState.neutral,
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
              _index + 1 < _questions.length ? 'Nächste Frage' : 'Ergebnis',
            ),
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
            Text(
              '$_correctCount von $total richtig',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: _restart,
              child: const Text('Nochmal versuchen'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Zurück zur Lektion'),
            ),
          ],
        ),
      ),
    );
  }
}

enum _OptionState { neutral, correct, wrong }

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.text,
    required this.state,
    required this.onTap,
  });

  final String text;
  final _OptionState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (Color? color, IconData? icon) = switch (state) {
      _OptionState.correct => (Colors.green.shade100, Icons.check_circle),
      _OptionState.wrong => (Colors.red.shade100, Icons.cancel),
      _OptionState.neutral => (null, null),
    };

    return Card(
      color: color,
      child: ListTile(
        title: Text(text),
        trailing: icon == null ? null : Icon(icon),
        onTap: onTap,
      ),
    );
  }
}
