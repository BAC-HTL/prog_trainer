import 'package:flutter/material.dart';

import '../app_services.dart';
import '../models/content.dart';
import '../widgets/track_icon.dart';
import 'track_screen.dart';

/// Tab "Lernen": Übersicht aller Lernpfade.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<List<Track>>? _tracks;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tracks ??= AppServices.of(context).repository.loadTracks();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Track>>(
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
            Row(
              children: [
                Image.asset('assets/icon/logo_mark.png', width: 56, height: 56),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Was möchtest du heute lernen?',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _SectionHeader('Programmiersprachen'),
            for (final t in languages) _TrackCard(track: t),
            const SizedBox(height: 16),
            const _SectionHeader('Softwareentwicklung'),
            for (final t in concepts) _TrackCard(track: t),
          ],
        );
      },
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
  const _TrackCard({required this.track});

  final Track track;

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
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => TrackScreen(track: track)),
        ),
      ),
    );
  }
}
