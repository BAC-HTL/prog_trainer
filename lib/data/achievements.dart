import 'package:flutter/material.dart';

/// Kennzahlen, aus denen die Achievements berechnet werden.
class ProgressStats {
  const ProgressStats({
    required this.lessonsCompleted,
    required this.examsPassed,
    required this.perfectExams,
    required this.examsPassedByTrack,
    required this.solvedByTrack,
    required this.pointsByTrack,
    this.examsPassedBySubject = const {},
    this.missionsSolved = 0,
    this.perfectMissions = 0,
  });

  final int lessonsCompleted;
  final int examsPassed;
  final int perfectExams;
  final Map<String, int> examsPassedByTrack;
  final Map<String, int> solvedByTrack;
  final Map<String, int> pointsByTrack;
  final Map<String, int> examsPassedBySubject;
  final int missionsSolved;
  final int perfectMissions;

  int examsIn(String track) => examsPassedByTrack[track] ?? 0;
  int pointsIn(String track) => pointsByTrack[track] ?? 0;
  int get totalSolved => solvedByTrack.values.fold(0, (a, b) => a + b);
  int get totalPoints => pointsByTrack.values.fold(0, (a, b) => a + b);
}

class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.check,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool Function(ProgressStats s) check;
}

final List<Achievement> allAchievements = [
  Achievement(
    id: 'lektion_1',
    title: 'Erste Schritte',
    description: 'Schließe deine erste Lektion ab.',
    icon: Icons.flag,
    check: (s) => s.lessonsCompleted >= 1,
  ),
  Achievement(
    id: 'lektion_10',
    title: 'Wissensdurst',
    description: 'Schließe 10 Lektionen ab.',
    icon: Icons.menu_book,
    check: (s) => s.lessonsCompleted >= 10,
  ),
  Achievement(
    id: 'lektion_25',
    title: 'Bücherwurm',
    description: 'Schließe 25 Lektionen ab.',
    icon: Icons.auto_stories,
    check: (s) => s.lessonsCompleted >= 25,
  ),
  Achievement(
    id: 'lektion_50',
    title: 'Unaufhaltsam',
    description: 'Schließe 50 Lektionen ab.',
    icon: Icons.rocket_launch,
    check: (s) => s.lessonsCompleted >= 50,
  ),
  Achievement(
    id: 'pruefung_1',
    title: 'Geprüft',
    description: 'Bestehe deine erste Abschlussprüfung.',
    icon: Icons.verified,
    check: (s) => s.examsPassed >= 1,
  ),
  Achievement(
    id: 'pruefung_5',
    title: 'Zertifikatssammler',
    description: 'Bestehe 5 Abschlussprüfungen.',
    icon: Icons.workspace_premium,
    check: (s) => s.examsPassed >= 5,
  ),
  Achievement(
    id: 'perfekt',
    title: 'Fehlerfrei',
    description: 'Bestehe eine Prüfung mit 100 %.',
    icon: Icons.star,
    check: (s) => s.perfectExams >= 1,
  ),
  Achievement(
    id: 'python_kapitel',
    title: 'Pythonista',
    description: 'Bestehe 3 Python-Prüfungen.',
    icon: Icons.terminal,
    check: (s) => s.examsIn('python') >= 3,
  ),
  Achievement(
    id: 'csharp_kapitel',
    title: 'Sharp Mind',
    description: 'Bestehe 3 C#-Prüfungen.',
    icon: Icons.code,
    check: (s) => s.examsIn('csharp') >= 3,
  ),
  Achievement(
    id: 'polyglott',
    title: 'Polyglott',
    description: 'Bestehe Prüfungen in Python und in C#.',
    icon: Icons.translate,
    check: (s) => s.examsIn('python') > 0 && s.examsIn('csharp') > 0,
  ),
  Achievement(
    id: 'allrounder',
    title: 'Allrounder',
    description: 'Bestehe Prüfungen in POS, DBI, NVS und TINF.',
    icon: Icons.hub,
    check: (s) => ['POS', 'DBI', 'NVS', 'TINF']
        .every((f) => (s.examsPassedBySubject[f] ?? 0) > 0),
  ),
  Achievement(
    id: 'netzwerker',
    title: 'Netzwerker',
    description: 'Bestehe 3 Prüfungen in Netzwerksysteme (NVS).',
    icon: Icons.lan,
    check: (s) => (s.examsPassedBySubject['NVS'] ?? 0) >= 3,
  ),
  Achievement(
    id: 'datenbank',
    title: 'Datenprofi',
    description: 'Bestehe 3 Prüfungen in Datenbanken (DBI).',
    icon: Icons.storage,
    check: (s) => (s.examsPassedBySubject['DBI'] ?? 0) >= 3,
  ),
  Achievement(
    id: 'challenge_1',
    title: 'Problemlöser',
    description: 'Löse deine erste Herausforderung.',
    icon: Icons.extension,
    check: (s) => s.totalSolved >= 1,
  ),
  Achievement(
    id: 'challenge_10',
    title: 'Tüftler',
    description: 'Löse 10 Herausforderungen.',
    icon: Icons.psychology,
    check: (s) => s.totalSolved >= 10,
  ),
  Achievement(
    id: 'python_100',
    title: 'Python-Punktejäger',
    description: 'Sammle 100 Punkte in Python.',
    icon: Icons.bolt,
    check: (s) => s.pointsIn('python') >= 100,
  ),
  Achievement(
    id: 'csharp_100',
    title: 'C#-Punktejäger',
    description: 'Sammle 100 Punkte in C#.',
    icon: Icons.bolt,
    check: (s) => s.pointsIn('csharp') >= 100,
  ),
  Achievement(
    id: 'python_500',
    title: 'Python-Profi',
    description: 'Sammle 500 Punkte in Python.',
    icon: Icons.military_tech,
    check: (s) => s.pointsIn('python') >= 500,
  ),
  Achievement(
    id: 'csharp_500',
    title: 'C#-Profi',
    description: 'Sammle 500 Punkte in C#.',
    icon: Icons.military_tech,
    check: (s) => s.pointsIn('csharp') >= 500,
  ),
  Achievement(
    id: 'mission_1',
    title: 'Erster Einsatz',
    description: 'Schließe deine erste Spielmission ab.',
    icon: Icons.smart_toy,
    check: (s) => s.missionsSolved >= 1,
  ),
  Achievement(
    id: 'mission_perfekt',
    title: 'Präzisionsarbeit',
    description: 'Hol 3 Sterne in einer Mission.',
    icon: Icons.auto_awesome,
    check: (s) => s.perfectMissions >= 1,
  ),
  Achievement(
    id: 'mission_10',
    title: 'Expeditionsleiter',
    description: 'Schließe 10 Spielmissionen ab.',
    icon: Icons.explore,
    check: (s) => s.missionsSolved >= 10,
  ),
  Achievement(
    id: 'punkte_1000',
    title: 'Tausender',
    description: 'Sammle insgesamt 1000 Punkte.',
    icon: Icons.emoji_events,
    check: (s) => s.totalPoints >= 1000,
  ),
];
