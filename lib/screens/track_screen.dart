import 'package:flutter/material.dart';

import '../app_services.dart';
import '../models/content.dart';
import 'chapter_screen.dart';

/// Lehrplan eines Lernpfads: Level → Kapitel.
class TrackScreen extends StatefulWidget {
  const TrackScreen({super.key, required this.track});

  final Track track;

  @override
  State<TrackScreen> createState() => _TrackScreenState();
}

class _TrackScreenState extends State<TrackScreen> {
  Future<List<Level>>? _levels;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _levels ??= AppServices.of(context).repository.loadLevels(widget.track);
  }

  @override
  Widget build(BuildContext context) {
    final progress = AppServices.of(context).progress;

    return Scaffold(
      appBar: AppBar(title: Text(widget.track.title)),
      body: FutureBuilder<List<Level>>(
        future: _levels,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Fehler: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final levels = snapshot.data!;
          return ListenableBuilder(
            listenable: progress,
            builder: (context, _) => ListView(
              padding: const EdgeInsets.all(12),
              children: [
                for (var i = 0; i < levels.length; i++)
                  _LevelCard(
                    track: widget.track,
                    level: levels[i],
                    initiallyExpanded: i == 0,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.track,
    required this.level,
    required this.initiallyExpanded,
  });

  final Track track;
  final Level level;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final progress = AppServices.of(context).progress;
    final passed =
        level.chapters.where((c) => progress.isExamPassed(c.id)).length;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        title: Text(level.title,
            style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(
            '${level.description}\n$passed von ${level.chapters.length} Kapiteln abgeschlossen'),
        children: [
          for (final chapter in level.chapters)
            _ChapterTile(track: track, level: level, chapter: chapter),
        ],
      ),
    );
  }
}

class _ChapterTile extends StatelessWidget {
  const _ChapterTile({
    required this.track,
    required this.level,
    required this.chapter,
  });

  final Track track;
  final Level level;
  final Chapter chapter;

  @override
  Widget build(BuildContext context) {
    final progress = AppServices.of(context).progress;
    final total = chapter.lessonPaths.length;
    final done =
        chapter.lessonPaths.where(progress.isLessonCompleted).length;
    final passed = progress.isExamPassed(chapter.id);

    return ListTile(
      enabled: chapter.isAvailable,
      leading: passed
          ? const Icon(Icons.workspace_premium, color: Colors.amber)
          : SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                value: total == 0 ? 0 : done / total,
                strokeWidth: 3,
              ),
            ),
      title: Text(chapter.title),
      subtitle: Text(chapter.isAvailable
          ? '${chapter.description}\n$done/$total Lektionen'
          : '${chapter.description}\nBald verfügbar'),
      isThreeLine: true,
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              ChapterScreen(track: track, level: level, chapter: chapter),
        ),
      ),
    );
  }
}
