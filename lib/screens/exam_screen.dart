import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/progress_store.dart';
import '../models/content.dart';
import '../widgets/certificate_button.dart';
import '../widgets/code_block.dart';
import '../widgets/option_tile.dart';

/// Abschlussprüfung eines Kapitels. Anders als im Quiz gibt es erst am Ende
/// eine Auswertung.
class ExamScreen extends StatefulWidget {
  const ExamScreen({
    super.key,
    required this.track,
    required this.level,
    required this.chapter,
  });

  final Track track;
  final Level level;
  final Chapter chapter;

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  Future<Exam>? _exam;
  List<int?> _answers = [];
  int _index = 0;
  ExamResult? _result;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _exam ??= AppServices.of(context)
        .repository
        .loadExam(widget.chapter.examPath!)
        .then((exam) {
      _answers = List<int?>.filled(exam.questions.length, null);
      return exam;
    });
  }

  Future<void> _finish(Exam exam) async {
    final correct = [
      for (var i = 0; i < exam.questions.length; i++)
        if (_answers[i] == exam.questions[i].correctIndex) i
    ].length;
    final percent = (correct * 100 / exam.questions.length).round();
    final result = ExamResult(
      trackId: widget.track.id,
      trackTitle: widget.track.title,
      levelTitle: widget.level.title,
      chapterTitle: widget.chapter.title,
      percent: percent,
      passed: percent >= exam.passPercent,
      date: DateTime.now(),
    );
    await AppServices.of(context).progress.recordExam(widget.chapter.id, result);
    if (!mounted) return;
    setState(() => _result = result);
  }

  Future<bool> _confirmLeave() async {
    if (_result != null) return true;
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Prüfung abbrechen?'),
        content: const Text('Deine Antworten gehen verloren.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Weitermachen')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Abbrechen')),
        ],
      ),
    );
    return leave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _result != null,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmLeave() && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text('Prüfung: ${widget.chapter.title}')),
        body: FutureBuilder<Exam>(
          future: _exam,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Fehler: ${snapshot.error}'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final exam = snapshot.data!;
            return _result == null
                ? _buildQuestion(exam)
                : _buildResult(exam, _result!);
          },
        ),
      ),
    );
  }

  Widget _buildQuestion(Exam exam) {
    final q = exam.questions[_index];
    final theme = Theme.of(context);
    final isLast = _index == exam.questions.length - 1;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        LinearProgressIndicator(value: _index / exam.questions.length),
        const SizedBox(height: 12),
        Text(
          'Frage ${_index + 1} von ${exam.questions.length} · '
          'Bestehen ab ${exam.passPercent} %',
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Text(q.question, style: theme.textTheme.titleLarge),
        if (q.code != null) CodeBlock(q.code!),
        const SizedBox(height: 12),
        for (var i = 0; i < q.options.length; i++)
          OptionTile(
            text: q.options[i],
            state: _answers[_index] == i
                ? OptionState.selected
                : OptionState.neutral,
            onTap: () => setState(() => _answers[_index] = i),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            if (_index > 0)
              OutlinedButton(
                onPressed: () => setState(() => _index--),
                child: const Text('Zurück'),
              ),
            const Spacer(),
            FilledButton(
              onPressed: _answers[_index] == null
                  ? null
                  : isLast
                      ? () => _finish(exam)
                      : () => setState(() => _index++),
              child: Text(isLast ? 'Abgeben' : 'Weiter'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResult(Exam exam, ExamResult result) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Icon(
          result.passed ? Icons.workspace_premium : Icons.refresh,
          size: 80,
          color: result.passed ? Colors.amber : theme.colorScheme.primary,
        ),
        const SizedBox(height: 8),
        Text(
          result.passed ? 'Bestanden! 🎉' : 'Leider nicht bestanden',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        Text(
          '${result.percent} % richtig (nötig: ${exam.passPercent} %)',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        if (result.passed) CertificateButton(result: result),
        if (!result.passed)
          FilledButton(
            onPressed: () => setState(() {
              _answers = List<int?>.filled(exam.questions.length, null);
              _index = 0;
              _result = null;
            }),
            child: const Text('Nochmal versuchen'),
          ),
        const SizedBox(height: 24),
        Text('Auswertung', style: theme.textTheme.titleMedium),
        for (var i = 0; i < exam.questions.length; i++)
          _ReviewTile(
            number: i + 1,
            question: exam.questions[i],
            answer: _answers[i],
          ),
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({
    required this.number,
    required this.question,
    required this.answer,
  });

  final int number;
  final QuizQuestion question;
  final int? answer;

  @override
  Widget build(BuildContext context) {
    final correct = answer == question.correctIndex;
    return Card(
      child: ExpansionTile(
        leading: Icon(correct ? Icons.check_circle : Icons.cancel,
            color: correct ? Colors.green : Colors.red),
        title: Text('$number. ${question.question}'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (question.code != null) CodeBlock(question.code!),
          if (!correct && answer != null)
            Text('Deine Antwort: ${question.options[answer!]}'),
          Text('Richtig: ${question.options[question.correctIndex]}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(question.explanation),
        ],
      ),
    );
  }
}
