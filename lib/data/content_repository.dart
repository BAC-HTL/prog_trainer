import 'dart:convert';

import 'package:flutter/services.dart';

import '../game/mission.dart';
import '../models/challenge.dart';
import '../models/content.dart';
import '../models/curriculum.dart';

/// Lädt alle Lerninhalte aus den JSON-Dateien in `assets/content/`.
class ContentRepository {
  ContentRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const basePath = 'assets/content';

  final AssetBundle _bundle;

  Future<Map<String, dynamic>> _json(String path) async {
    final raw = await _bundle.loadString('$basePath/$path');
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<List<Track>> loadTracks() async {
    final json = await _json('index.json');
    return (json['tracks'] as List)
        .map((t) => Track.fromJson(t as Map<String, dynamic>))
        .toList();
  }

  Future<Curriculum> loadCurriculum() async =>
      Curriculum.fromJson(await _json('curriculum.json'));

  Future<Lesson> loadLesson(String path) async =>
      Lesson.fromJson(await _json(path));

  Future<List<Lesson>> loadLessons(List<String> paths) =>
      Future.wait(paths.map(loadLesson));

  Future<Exam> loadExam(String path) async => Exam.fromJson(await _json(path));

  Future<List<Challenge>> loadChallenges(Track track) async {
    if (track.challengesPath == null) return const [];
    final json = await _json(track.challengesPath!);
    return (json['challenges'] as List)
        .map((c) => Challenge.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  // ---------- Spielmodus ----------

  static const gamePath = 'assets/game';

  Future<List<Mission>> loadMissions() async {
    final index = jsonDecode(await _bundle.loadString('$gamePath/index.json'))
        as Map<String, dynamic>;
    final missions = <Mission>[];
    for (final file in List<String>.from(index['files'] as List)) {
      final json = jsonDecode(await _bundle.loadString('$gamePath/$file'))
          as Map<String, dynamic>;
      missions.addAll((json['missions'] as List)
          .map((m) => Mission.fromJson(m as Map<String, dynamic>)));
    }
    return missions;
  }

  /// Quellcode der Robotersimulation für `python` oder `csharp`.
  Future<String> loadSimulation(String language) => _bundle.loadString(
      '$gamePath/${language == 'python' ? 'robot_sim.py' : 'RobotSim.cs'}',
      cache: false);
}
