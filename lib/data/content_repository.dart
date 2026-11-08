import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/content.dart';

/// Lädt Lernpfade und Lektionen aus den JSON-Dateien in `assets/content/`.
class ContentRepository {
  ContentRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const basePath = 'assets/content';

  final AssetBundle _bundle;

  Future<List<Track>> loadTracks() async {
    final raw = await _bundle.loadString('$basePath/index.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return (json['tracks'] as List)
        .map((t) => Track.fromJson(t as Map<String, dynamic>))
        .toList();
  }

  Future<Lesson> loadLesson(String path) async {
    final raw = await _bundle.loadString('$basePath/$path');
    return Lesson.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<List<Lesson>> loadLessons(Track track) {
    return Future.wait(track.lessonPaths.map(loadLesson));
  }
}
