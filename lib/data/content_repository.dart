import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/challenge.dart';
import '../models/content.dart';

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

  Future<List<Level>> loadLevels(Track track) async {
    final levels = await Future.wait(track.levelPaths.map(_json));
    return levels.map(Level.fromJson).toList();
  }

  Future<Lesson> loadLesson(String path) async =>
      Lesson.fromJson(await _json(path));

  Future<List<Lesson>> loadLessons(Chapter chapter) =>
      Future.wait(chapter.lessonPaths.map(loadLesson));

  Future<Exam> loadExam(String path) async => Exam.fromJson(await _json(path));

  Future<List<Challenge>> loadChallenges(Track track) async {
    if (track.challengesPath == null) return const [];
    final json = await _json(track.challengesPath!);
    return (json['challenges'] as List)
        .map((c) => Challenge.fromJson(c as Map<String, dynamic>))
        .toList();
  }
}
