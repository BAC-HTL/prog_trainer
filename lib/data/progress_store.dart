import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/challenge.dart';
import 'achievements.dart';

/// Ergebnis einer bestandenen oder nicht bestandenen Abschlussprüfung.
/// Speichert auch die Titel, damit das Zertifikat jederzeit neu erzeugt
/// werden kann.
class ExamResult {
  const ExamResult({
    required this.trackId,
    required this.trackTitle,
    required this.levelTitle,
    required this.chapterTitle,
    required this.percent,
    required this.passed,
    required this.date,
  });

  final String trackId;
  final String trackTitle;
  final String levelTitle;
  final String chapterTitle;
  final int percent;
  final bool passed;
  final DateTime date;

  Map<String, dynamic> toJson() => {
        'trackId': trackId,
        'trackTitle': trackTitle,
        'levelTitle': levelTitle,
        'chapterTitle': chapterTitle,
        'percent': percent,
        'passed': passed,
        'date': date.toIso8601String(),
      };

  factory ExamResult.fromJson(Map<String, dynamic> json) => ExamResult(
        trackId: json['trackId'] as String,
        trackTitle: json['trackTitle'] as String? ?? '',
        levelTitle: json['levelTitle'] as String? ?? '',
        chapterTitle: json['chapterTitle'] as String? ?? '',
        percent: json['percent'] as int,
        passed: json['passed'] as bool,
        date: DateTime.parse(json['date'] as String),
      );
}

/// Speichert den Lernfortschritt lokal auf dem Gerät.
class ProgressStore extends ChangeNotifier {
  ProgressStore._(this._prefs);

  static Future<ProgressStore> load() async {
    final store = ProgressStore._(await SharedPreferences.getInstance());
    store._read();
    return store;
  }

  static const _progressKey = 'progress_v1';
  static const _nameKey = 'user_name';

  final SharedPreferences _prefs;

  final Set<String> _completedLessons = {};
  final Map<String, ExamResult> _exams = {};
  final Map<String, Set<String>> _solved = {};
  final Map<String, int> _points = {};
  final Map<String, DateTime> _achievements = {};

  /// Spielmodus: Sprache → Missions-ID → beste Sterne (1–3).
  final Map<String, Map<String, int>> _missions = {};

  /// Wird aufgerufen, wenn ein neues Achievement freigeschaltet wurde.
  void Function(Achievement achievement)? onAchievementUnlocked;

  // ---------- Lesen ----------

  String get userName => _prefs.getString(_nameKey) ?? '';

  bool isLessonCompleted(String lessonPath) =>
      _completedLessons.contains(lessonPath);
  int get completedLessonCount => _completedLessons.length;

  ExamResult? examResult(String chapterId) => _exams[chapterId];
  bool isExamPassed(String chapterId) => _exams[chapterId]?.passed ?? false;

  /// Alle bestandenen Prüfungen, neueste zuerst.
  List<MapEntry<String, ExamResult>> get passedExams {
    final list = _exams.entries.where((e) => e.value.passed).toList()
      ..sort((a, b) => b.value.date.compareTo(a.value.date));
    return list;
  }

  bool isSolved(String trackId, String challengeId) =>
      _solved[trackId]?.contains(challengeId) ?? false;
  int solvedCount(String trackId) => _solved[trackId]?.length ?? 0;
  int points(String trackId) => _points[trackId] ?? 0;
  int get totalPoints => _points.values.fold(0, (a, b) => a + b);

  int missionStars(String trackId, String missionId) =>
      _missions[trackId]?[missionId] ?? 0;
  int missionsSolved(String trackId) => _missions[trackId]?.length ?? 0;
  int missionStarTotal(String trackId) =>
      _missions[trackId]?.values.fold<int>(0, (a, b) => a + b) ?? 0;

  bool isUnlocked(String achievementId) =>
      _achievements.containsKey(achievementId);
  DateTime? unlockedAt(String achievementId) => _achievements[achievementId];

  ProgressStats get stats {
    final passed = _exams.values.where((e) => e.passed);
    final byTrack = <String, int>{};
    for (final e in passed) {
      byTrack[e.trackId] = (byTrack[e.trackId] ?? 0) + 1;
    }
    return ProgressStats(
      lessonsCompleted: _completedLessons.length,
      examsPassed: passed.length,
      perfectExams: passed.where((e) => e.percent == 100).length,
      examsPassedByTrack: byTrack,
      solvedByTrack: _solved.map((k, v) => MapEntry(k, v.length)),
      pointsByTrack: Map.of(_points),
      missionsSolved:
          _missions.values.fold<int>(0, (a, m) => a + m.length),
      perfectMissions: _missions.values
          .fold<int>(0, (a, m) => a + m.values.where((s) => s >= 3).length),
    );
  }

  // ---------- Schreiben ----------

  Future<void> completeLesson(String lessonPath) async {
    if (_completedLessons.add(lessonPath)) await _save();
  }

  /// Speichert ein Prüfungsergebnis. Das beste Ergebnis bleibt erhalten.
  Future<void> recordExam(String chapterId, ExamResult result) async {
    final old = _exams[chapterId];
    final better = old == null ||
        (result.passed && !old.passed) ||
        (result.passed == old.passed && result.percent > old.percent);
    if (better) {
      _exams[chapterId] = result;
      await _save();
    }
  }

  /// Markiert eine Herausforderung als gelöst. Gibt `true` zurück, wenn
  /// sie neu gelöst wurde (und Punkte vergeben wurden).
  Future<bool> solveChallenge(String trackId, Challenge challenge) async {
    final set = _solved.putIfAbsent(trackId, () => <String>{});
    if (!set.add(challenge.id)) return false;
    _points[trackId] = (_points[trackId] ?? 0) + challenge.points;
    await _save();
    return true;
  }

  /// Speichert das Ergebnis einer Mission. Pro neuem Stern gibt es
  /// 10 Punkte (in der Sprache der Mission). Gibt die neuen Punkte zurück.
  Future<int> recordMission(String trackId, String missionId, int stars) async {
    final map = _missions.putIfAbsent(trackId, () => <String, int>{});
    final old = map[missionId] ?? 0;
    if (stars <= old) return 0;
    map[missionId] = stars;
    final gained = (stars - old) * 10;
    _points[trackId] = (_points[trackId] ?? 0) + gained;
    await _save();
    return gained;
  }

  Future<void> setUserName(String name) async {
    await _prefs.setString(_nameKey, name.trim());
    notifyListeners();
  }

  Future<void> resetProgress() async {
    _completedLessons.clear();
    _exams.clear();
    _solved.clear();
    _points.clear();
    _achievements.clear();
    _missions.clear();
    await _prefs.remove(_progressKey);
    notifyListeners();
  }

  // ---------- intern ----------

  void _checkAchievements() {
    final s = stats;
    for (final a in allAchievements) {
      if (!_achievements.containsKey(a.id) && a.check(s)) {
        _achievements[a.id] = DateTime.now();
        onAchievementUnlocked?.call(a);
      }
    }
  }

  Future<void> _save() async {
    _checkAchievements();
    final data = {
      'lessons': _completedLessons.toList(),
      'exams': _exams.map((k, v) => MapEntry(k, v.toJson())),
      'solved': _solved.map((k, v) => MapEntry(k, v.toList())),
      'points': _points,
      'achievements':
          _achievements.map((k, v) => MapEntry(k, v.toIso8601String())),
      'missions': _missions,
    };
    await _prefs.setString(_progressKey, jsonEncode(data));
    notifyListeners();
  }

  void _read() {
    final raw = _prefs.getString(_progressKey);
    if (raw == null) return;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      _completedLessons.addAll(List<String>.from(data['lessons'] as List));
      (data['exams'] as Map<String, dynamic>).forEach((k, v) {
        _exams[k] = ExamResult.fromJson(v as Map<String, dynamic>);
      });
      (data['solved'] as Map<String, dynamic>).forEach((k, v) {
        _solved[k] = Set<String>.from(v as List);
      });
      (data['points'] as Map<String, dynamic>).forEach((k, v) {
        _points[k] = v as int;
      });
      (data['achievements'] as Map<String, dynamic>).forEach((k, v) {
        _achievements[k] = DateTime.parse(v as String);
      });
      (data['missions'] as Map<String, dynamic>? ?? {}).forEach((k, v) {
        _missions[k] = Map<String, int>.from(v as Map);
      });
    } catch (e) {
      debugPrint('Fortschritt konnte nicht gelesen werden: $e');
    }
  }
}
