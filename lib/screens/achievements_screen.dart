import 'package:flutter/material.dart';

import '../app_services.dart';
import '../certificates/certificate_pdf.dart';
import '../data/achievements.dart';
import '../widgets/certificate_button.dart';

/// Tab "Erfolge": Punkte, Zertifikate und Achievements.
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = AppServices.of(context).progress;
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: progress,
      builder: (context, _) {
        final unlocked =
            allAchievements.where((a) => progress.isUnlocked(a.id)).length;
        final certificates = progress.passedExams;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                _StatCard(
                    label: 'Python', value: '${progress.points('python')}', unit: 'Punkte'),
                _StatCard(
                    label: 'C#', value: '${progress.points('csharp')}', unit: 'Punkte'),
                _StatCard(
                    label: 'Lektionen',
                    value: '${progress.completedLessonCount}',
                    unit: 'fertig'),
              ],
            ),
            const SizedBox(height: 20),
            Text('Zertifikate (${certificates.length})',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            if (certificates.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                    'Bestehe die Abschlussprüfung eines Kapitels, um dein erstes Zertifikat zu bekommen.'),
              ),
            for (final entry in certificates)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.workspace_premium,
                      color: Colors.amber),
                  title: Text('${entry.value.trackTitle}: ${entry.value.chapterTitle}'),
                  subtitle: Text('${entry.value.levelTitle} · '
                      '${entry.value.percent} % · ${formatDate(entry.value.date)}'),
                  trailing: CertificateButton(result: entry.value, compact: true),
                ),
              ),
            const SizedBox(height: 20),
            Text('Achievements ($unlocked/${allAchievements.length})',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.8,
              children: [
                for (final a in allAchievements)
                  _AchievementTile(
                      achievement: a, unlocked: progress.isUnlocked(a.id)),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.unit});

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Text(label, style: theme.textTheme.labelLarge),
              Text(value, style: theme.textTheme.headlineSmall),
              Text(unit, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.achievement, required this.unlocked});

  final Achievement achievement;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: achievement.description,
      triggerMode: TooltipTriggerMode.tap,
      child: Card(
        color: unlocked ? theme.colorScheme.tertiaryContainer : null,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                unlocked ? achievement.icon : Icons.lock_outline,
                size: 36,
                color: unlocked ? Colors.amber.shade800 : Colors.grey,
              ),
              const SizedBox(height: 6),
              Text(
                achievement.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 2),
              Text(
                achievement.description,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
