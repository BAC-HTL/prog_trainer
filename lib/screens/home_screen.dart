import 'package:flutter/material.dart';

import '../data/content_repository.dart';
import '../models/content.dart';
import '../widgets/track_icon.dart';
import 'track_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.repository});

  final ContentRepository repository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Future<List<Track>> _tracks = widget.repository.loadTracks();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prog Trainer')),
      body: FutureBuilder<List<Track>>(
        future: _tracks,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Inhalte konnten nicht geladen werden:\n'
                  '${snapshot.error}'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final tracks = snapshot.data!;
          final languages =
              tracks.where((t) => t.kind == TrackKind.language).toList();
          final concepts =
              tracks.where((t) => t.kind == TrackKind.concept).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Was möchtest du heute lernen?',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              const _SectionHeader('Programmiersprachen'),
              for (final t in languages)
                _TrackCard(track: t, repository: widget.repository),
              const SizedBox(height: 16),
              const _SectionHeader('Softwareentwicklung'),
              for (final t in concepts)
                _TrackCard(track: t, repository: widget.repository),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _TrackCard extends StatelessWidget {
  const _TrackCard({required this.track, required this.repository});

  final Track track;
  final ContentRepository repository;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(trackIcon(track.icon), size: 32),
        title: Text(track.title),
        subtitle: Text(
          track.isAvailable ? track.description : 'Bald verfügbar',
        ),
        enabled: track.isAvailable,
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  TrackScreen(track: track, repository: repository),
            ),
          );
        },
      ),
    );
  }
}
