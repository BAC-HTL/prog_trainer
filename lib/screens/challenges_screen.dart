import 'package:flutter/material.dart';

import '../app_services.dart';
import '../models/challenge.dart';
import '../models/content.dart';
import 'challenge_screen.dart';

/// Tab "Herausforderungen": Aufgaben lösen und Punkte sammeln – immer
/// getrennt pro Programmiersprache.
class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  Future<List<Track>>? _tracks;
  Track? _selected;
  final Map<String, Future<List<Challenge>>> _challenges = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tracks ??= AppServices.of(context).repository.loadTracks().then(
        (all) => all.where((t) => t.hasChallenges).toList());
  }

  Future<List<Challenge>> _load(Track track) => _challenges.putIfAbsent(
      track.id, () => AppServices.of(context).repository.loadChallenges(track));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Track>>(
      future: _tracks,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final tracks = snapshot.data!;
        if (tracks.isEmpty) {
          return const Center(child: Text('Noch keine Herausforderungen.'));
        }
        final track = _selected ?? tracks.first;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: SegmentedButton<String>(
                segments: [
                  for (final t in tracks)
                    ButtonSegment(value: t.id, label: Text(t.title)),
                ],
                selected: {track.id},
                onSelectionChanged: (s) => setState(() =>
                    _selected = tracks.firstWhere((t) => t.id == s.first)),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Challenge>>(
                key: ValueKey(track.id),
                future: _load(track),
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Center(child: Text('Fehler: ${snap.error}'));
                  }
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return _ChallengeList(track: track, challenges: snap.data!);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ChallengeList extends StatelessWidget {
  const _ChallengeList({required this.track, required this.challenges});

  final Track track;
  final List<Challenge> challenges;

  @override
  Widget build(BuildContext context) {
    final progress = AppServices.of(context).progress;
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: progress,
      builder: (context, _) {
        final byLevel = <String, List<Challenge>>{};
        for (final c in challenges) {
          byLevel.putIfAbsent(c.level, () => []).add(c);
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.bolt, size: 40, color: Colors.amber),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${progress.points(track.id)} Punkte',
                              style: theme.textTheme.headlineSmall),
                          Text('${track.title} · '
                              '${progress.solvedCount(track.id)} von '
                              '${challenges.length} gelöst'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            for (final entry in byLevel.entries) ...[
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Text(levelTitles[entry.key] ?? entry.key,
                    style: theme.textTheme.titleMedium),
              ),
              for (final c in entry.value)
                Card(
                  child: ListTile(
                    leading: progress.isSolved(track.id, c.id)
                        ? const CircleAvatar(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            child: Icon(Icons.check))
                        : CircleAvatar(child: Text('${c.points}')),
                    title: Text(c.title),
                    subtitle: Text('${_difficulty(c.difficulty)} · '
                        '${c.points} Punkte'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            ChallengeScreen(track: track, challenge: c),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }

  static String _difficulty(String d) => switch (d) {
        'leicht' => 'Leicht',
        'mittel' => 'Mittel',
        'schwer' => 'Schwer',
        _ => d,
      };
}
