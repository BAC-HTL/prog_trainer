import 'package:flutter/material.dart';

import '../data/content_repository.dart';
import '../models/content.dart';
import 'lesson_screen.dart';

/// Liste aller Lektionen eines Lernpfads.
class TrackScreen extends StatefulWidget {
  const TrackScreen({super.key, required this.track, required this.repository});

  final Track track;
  final ContentRepository repository;

  @override
  State<TrackScreen> createState() => _TrackScreenState();
}

class _TrackScreenState extends State<TrackScreen> {
  late final Future<List<Lesson>> _lessons =
      widget.repository.loadLessons(widget.track);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.track.title)),
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
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: lessons.length,
            itemBuilder: (context, i) {
              final lesson = lessons[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('${i + 1}')),
                  title: Text(lesson.title),
                  subtitle: Text(lesson.summary),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => LessonScreen(lesson: lesson),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
