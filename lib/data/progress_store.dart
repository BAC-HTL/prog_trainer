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
    this.subject,
  });

  final String trackId;

  /// Fach (POS, DBI, NVS, TINF, SYP) – für das Achievement „Allrounder“.
  final String? subject;
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
        if (subject != null) 'subject': subject,
      };

  factory ExamResult.fromJson(Map<String, dynamic> json) => ExamResult(
        trackId: json['trackId'] as String,
        trackTitle: json['trackTitle'] as String? ?? '',
        levelTitle: json['levelTitle'] as String? ?? '',
        chapterTitle: json['chapterTitle'] as String? ?? '',
        percent: json['percent'] as int,
        passed: json['passed'] as bool,
        date: DateTime.parse(json['date'] as String),
        subject: json['subject'] as String?,
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
  static const _languageKey = 'pos_language';

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

  /// Bevorzugte Programmiersprache für Programmier-Module.
  String get language => _prefs.getString(_languageKey) ?? 'python';

  Future<void> setLanguage(String language) async {
    await _prefs.setString(_languageKey, language);
    notifyListeners();
  }

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
    final bySubject = <String, int>{};
    for (final e in passed) {
      byTrack[e.trackId] = (byTrack[e.trackId] ?? 0) + 1;
      final subject = e.subject ??
          (e.trackId == 'python' || e.trackId == 'csharp' ? 'POS' : null);
      if (subject != null) bySubject[subject] = (bySubject[subject] ?? 0) + 1;
    }
    return ProgressStats(
      lessonsCompleted: _completedLessons.length,
      examsPassed: passed.length,
      perfectExams: passed.where((e) => e.percent == 100).length,
      examsPassedByTrack: byTrack,
      examsPassedBySubject: bySubject,
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
    _clear();
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
    await _prefs.setString(_progressKey, jsonEncode(_data()));
    notifyListeners();
  }

  Map<String, dynamic> _data() => {
      'lessons': _completedLessons.toList(),
      'exams': _exams.map((k, v) => MapEntry(k, v.toJson())),
      'solved': _solved.map((k, v) => MapEntry(k, v.toList())),
      'points': _points,
      'achievements':
          _achievements.map((k, v) => MapEntry(k, v.toIso8601String())),
      'missions': _missions,
    };

  void _read() {
    final raw = _prefs.getString(_progressKey);
    if (raw == null) return;
    try {
      _apply(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Fortschritt konnte nicht gelesen werden: $e');
    }
  }

  void _clear() {
    _completedLessons.clear();
    _exams.clear();
    _solved.clear();
    _points.clear();
    _achievements.clear();
    _missions.clear();
  }

  // ---------- Sichern & Übertragen ----------

  static const _transferPrefix = 'PT1:';

  /// Gesamter Fortschritt (inkl. Name und Sprache) als JSON-Text – für die
  /// Sicherungsdatei.
  String exportJson() => const JsonEncoder.withIndent(' ').convert({
        'app': 'prog_trainer',
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'name': userName,
        'language': language,
        'progress': _data(),
      });

  /// Kompakter Übertragungscode zum Kopieren und Einfügen auf einem anderen
  /// Gerät.
  String exportCode() => _transferPrefix +
      base64Url.encode(utf8.encode(jsonEncode({
        'name': userName,
        'language': language,
        'progress': _data(),
      })));

  /// Liest eine Sicherungsdatei oder einen Übertragungscode ein und ersetzt
  /// den aktuellen Fortschritt. Wirft [FormatException] bei ungültigen Daten.
  Future<void> importBackup(String input) async {
    final text = input.trim();
    final Map<String, dynamic> json;
    try {
      json = text.startsWith(_transferPrefix)
          ? jsonDecode(utf8.decode(base64Url
              .decode(base64Url.normalize(text.substring(_transferPrefix.length)))))
              as Map<String, dynamic>
          : jsonDecode(text) as Map<String, dynamic>;
    } catch (_) {
      throw const FormatException('Das ist keine gültige Sicherung.');
    }
    final progress = json['progress'];
    if (progress is! Map<String, dynamic> || progress['lessons'] is! List) {
      throw const FormatException('Das ist keine gültige Sicherung.');
    }
    final backup = _data();
    _clear();
    try {
      _apply(progress);
    } catch (_) {
      _clear();
      _apply(backup);
      throw const FormatException('Die Sicherung ist beschädigt.');
    }
    final name = json['name'];
    if (name is String && name.isNotEmpty) await _prefs.setString(_nameKey, name);
    final lang = json['language'];
    if (lang is String) await _prefs.setString(_languageKey, lang);
    await _prefs.setString(_progressKey, jsonEncode(_data()));
    notifyListeners();
  }

  void _apply(Map<String, dynamic> data) {
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
  }
}
