import 'package:flutter/material.dart';

import '../app_services.dart';
import '../models/content.dart';
import '../widgets/certificate_button.dart';
import 'exam_screen.dart';
import 'lesson_screen.dart';

/// Lektionen eines Kapitels und die Abschlussprüfung.
class ChapterScreen extends StatefulWidget {
  const ChapterScreen({
    super.key,
    required this.track,
    required this.level,
    required this.chapter,
  });

  final Track track;
  final Level level;
  final Chapter chapter;

  @override
  State<ChapterScreen> createState() => _ChapterScreenState();
}

class _ChapterScreenState extends State<ChapterScreen> {
  Future<List<Lesson>>? _lessons;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _lessons ??=
        AppServices.of(context).repository.loadLessons(widget.chapter);
  }

  @override
  Widget build(BuildContext context) {
    final progress = AppServices.of(context).progress;
    final chapter = widget.chapter;

    return Scaffold(
      appBar: AppBar(title: Text(chapter.title)),
      body: FutureBuilder<List<Lesson>>(
        future: _lessons,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Fehler: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final lessons = snapshot.data!;
          return ListenableBuilder(
            listenable: progress,
            builder: (context, _) {
              final allDone =
                  chapter.lessonPaths.every(progress.isLessonCompleted);
              final result = progress.examResult(chapter.id);

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(chapter.description,
                      style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 12),
                  for (var i = 0; i < lessons.length; i++)
                    Card(
                      child: ListTile(
                        leading: progress
                                .isLessonCompleted(chapter.lessonPaths[i])
                            ? const CircleAvatar(child: Icon(Icons.check))
                            : CircleAvatar(child: Text('${i + 1}')),
                        title: Text(lessons[i].title),
                        subtitle: Text(lessons[i].summary),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => LessonScreen(
                              lesson: lessons[i],
                              lessonPath: chapter.lessonPaths[i],
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (chapter.examPath != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.assignment_turned_in),
                                const SizedBox(width: 8),
                                Text('Abschlussprüfung',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(result == null
                                ? allDone
                                    ? 'Du hast alle Lektionen abgeschlossen. Bestehe die Prüfung und hol dir dein Zertifikat!'
                                    : 'Schließe zuerst alle Lektionen ab, um die Prüfung freizuschalten.'
                                : result.passed
                                    ? 'Bestanden mit ${result.percent} %.'
                                    : 'Bisher ${result.percent} % – versuch es nochmal!'),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              icon: Icon(allDone ? Icons.play_arrow : Icons.lock),
                              label: Text(result?.passed == true
                                  ? 'Prüfung wiederholen'
                                  : 'Prüfung starten'),
                              onPressed: allDone
                                  ? () => Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => ExamScreen(
                                            track: widget.track,
                                            level: widget.level,
                                            chapter: chapter,
                                          ),
                                        ),
                                      )
                                  : null,
                            ),
                            if (result?.passed == true) ...[
                              const SizedBox(height: 8),
                              CertificateButton(result: result!),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}
