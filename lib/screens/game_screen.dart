import 'package:flutter/material.dart';

import '../app_services.dart';
import '../game/mission.dart';
import '../models/content.dart';
import 'mission_screen.dart';

/// Tab "Spiel": Missionen mit dem Forschungsroboter – getrennt pro Sprache.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  Future<(List<Track>, List<Mission>)>? _data;
  String? _trackId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_data == null) {
      final repo = AppServices.of(context).repository;
      _data = Future.wait([repo.loadTracks(), repo.loadMissions()]).then(
        (r) => (
          (r[0] as List<Track>).where((t) => t.runtime != null).toList(),
          r[1] as List<Mission>,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = AppServices.of(context).progress;
    final theme = Theme.of(context);

    return FutureBuilder<(List<Track>, List<Mission>)>(
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Fehler: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final (tracks, missions) = snapshot.data!;
        final track =
            tracks.firstWhere((t) => t.id == _trackId, orElse: () => tracks.first);

        return ListenableBuilder(
          listenable: progress,
          builder: (context, _) {
            final stars = progress.missionStarTotal(track.id);
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SegmentedButton<String>(
                  segments: [
                    for (final t in tracks)
                      ButtonSegment(value: t.id, label: Text(t.title)),
                  ],
                  selected: {track.id},
                  onSelectionChanged: (s) => setState(() => _trackId = s.first),
                ),
                const SizedBox(height: 12),
                Card(
                  color: theme.colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Text('🤖', style: TextStyle(fontSize: 40)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Expedition Xeno-7',
                                  style: theme.textTheme.titleLarge),
                              Text(
                                  'Steuere den Forschungsroboter mit ${track.title}. '
                                  'Sammle Proben, braue im Labor neue Stoffe '
                                  'und meide die Lava.'),
                              const SizedBox(height: 4),
                              Text(
                                  '⭐ $stars / ${missions.length * 3}   ·   '
                                  '${progress.missionsSolved(track.id)} von '
                                  '${missions.length} Missionen',
                                  style: theme.textTheme.labelLarge),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                for (var i = 0; i < missions.length; i++)
                  _MissionTile(
                    track: track,
                    missions: missions,
                    index: i,
                    unlocked: i == 0 ||
                        progress.missionStars(track.id, missions[i - 1].id) > 0,
                    stars: progress.missionStars(track.id, missions[i].id),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _MissionTile extends StatelessWidget {
  const _MissionTile({
    required this.track,
    required this.missions,
    required this.index,
    required this.unlocked,
    required this.stars,
  });

  final Track track;
  final List<Mission> missions;
  final int index;
  final bool unlocked;
  final int stars;

  @override
  Widget build(BuildContext context) {
    final m = missions[index];
    return Card(
      child: ListTile(
        enabled: unlocked,
        leading: CircleAvatar(
          child: unlocked ? Text('${index + 1}') : const Icon(Icons.lock, size: 18),
        ),
        title: Text(m.title),
        subtitle: Text(m.concept),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var s = 1; s <= 3; s++)
              Icon(s <= stars ? Icons.star : Icons.star_border,
                  size: 20, color: Colors.amber.shade700),
          ],
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                MissionScreen(track: track, missions: missions, index: index),
          ),
        ),
      ),
    );
  }
}

/// Befehlsübersicht für den Roboter.
void showRobotApi(BuildContext context, String language) {
  final py = language == 'python';
  final commands = py
      ? const [
          ('robot.vor()', 'ein Feld vorwärts (kostet 1 Energie)'),
          ('robot.links()', 'nach links drehen'),
          ('robot.rechts()', 'nach rechts drehen'),
          ('robot.ist_frei()', 'True, wenn vorne kein Fels/keine Lava ist'),
          ('robot.vorne()', 'was vorne liegt: "fels", "lava", "kristall", …'),
          ('robot.scannen()', 'was unter dem Roboter liegt'),
          ('robot.aufheben()', 'Probe aufheben, gibt den Namen zurück'),
          ('robot.mischen(a, b)', 'im Labor zwei Stoffe mischen'),
          ('robot.inventar()', 'Liste aller gesammelten Stoffe'),
          ('robot.position()', '(x, y)'),
          ('robot.richtung()', '"N", "O", "S" oder "W"'),
          ('robot.energie()', 'verbleibende Energie'),
        ]
      : const [
          ('Robot.Vor();', 'ein Feld vorwärts (kostet 1 Energie)'),
          ('Robot.Links();', 'nach links drehen'),
          ('Robot.Rechts();', 'nach rechts drehen'),
          ('Robot.IstFrei()', 'true, wenn vorne kein Fels/keine Lava ist'),
          ('Robot.Vorne()', 'was vorne liegt: "fels", "lava", "kristall", …'),
          ('Robot.Scannen()', 'was unter dem Roboter liegt'),
          ('Robot.Aufheben()', 'Probe aufheben, gibt den Namen zurück'),
          ('Robot.Mischen(a, b)', 'im Labor zwei Stoffe mischen'),
          ('Robot.Inventar()', 'List<string> aller gesammelten Stoffe'),
          ('Robot.X, Robot.Y', 'Position'),
          ('Robot.Richtung', '"N", "O", "S" oder "W"'),
          ('Robot.Energie', 'verbleibende Energie'),
        ];

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text('Befehle', style: Theme.of(context).textTheme.titleLarge),
          for (final (cmd, desc) in commands)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(cmd, style: const TextStyle(fontFamily: 'monospace')),
              subtitle: Text(desc),
            ),
          const SizedBox(height: 12),
          Text('Rezepte im Labor ⚗️', style: Theme.of(context).textTheme.titleMedium),
          for (final (a, b, r) in recipes)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text('${itemLabel(a)} + ${itemLabel(b)} → ${itemLabel(r)}'),
            ),
          const SizedBox(height: 12),
          const Text('Quellen 💧 liefern beliebig oft Wasser. Andere Proben '
              'verschwinden beim Aufheben.'),
        ],
      ),
    ),
  );
}
