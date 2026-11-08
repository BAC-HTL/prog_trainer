import 'package:flutter/material.dart';

import '../app_services.dart';
import '../models/content.dart';
import '../widgets/code_block.dart';
import 'quiz_screen.dart';

/// Zeigt den Inhalt einer Lektion und führt danach zum Quiz.
class LessonScreen extends StatelessWidget {
  const LessonScreen({
    super.key,
    required this.lesson,
    required this.lessonPath,
  });

  final Lesson lesson;

  /// Schlüssel, unter dem der Fortschritt gespeichert wird.
  final String lessonPath;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyLarge;
    final progress = AppServices.of(context).progress;

    return Scaffold(
      appBar: AppBar(title: Text(lesson.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final section in lesson.sections)
            if (section.type == SectionType.code)
              CodeBlock(section.content)
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(section.content, style: textStyle),
              ),
          const SizedBox(height: 24),
          if (lesson.quiz.isNotEmpty)
            FilledButton.icon(
              icon: const Icon(Icons.quiz),
              label: Text('Quiz starten (${lesson.quiz.length} Fragen)'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      QuizScreen(lesson: lesson, lessonPath: lessonPath),
                ),
              ),
            )
          else
            FilledButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('Lektion abschließen'),
              onPressed: () async {
                await progress.completeLesson(lessonPath);
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
        ],
      ),
    );
  }
}
