import 'dart:convert';

import 'package:http/http.dart' as http;

import 'code_runner.dart';

/// Führt Code über einen Judge0-Server aus (https://judge0.com).
///
/// Funktioniert mit der Judge0-API auf RapidAPI (API-Key nötig) oder einem
/// selbst gehosteten Judge0-Server (optional mit Auth-Token).
class Judge0Runner implements CodeRunner {
  Judge0Runner({
    required this.baseUrl,
    required this.apiKey,
    required this.languageId,
    this.transform,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final String apiKey;
  final int languageId;

  /// Optionaler Umbau des Codes vor dem Senden (z. B. [wrapCSharp]).
  final String Function(String code)? transform;
  final http.Client _client;

  static const csharpMono = 51;

  static String _b64(String s) => base64Encode(utf8.encode(s));
  static String _unb64(Object? s) =>
      s == null ? '' : utf8.decode(base64Decode((s as String).replaceAll('\n', '')));

  @override
  Future<RunResult> run(String code, {String stdin = ''}) async {
    final root = baseUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$root/submissions?base64_encoded=true&wait=true');
    final headers = {'Content-Type': 'application/json'};
    if (uri.host.contains('rapidapi')) {
      headers['X-RapidAPI-Key'] = apiKey;
      headers['X-RapidAPI-Host'] = uri.host;
    } else if (apiKey.isNotEmpty) {
      headers['X-Auth-Token'] = apiKey;
    }

    final source = transform?.call(code) ?? code;
    final http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: headers,
            body: jsonEncode({
              'source_code': _b64(source),
              'language_id': languageId,
              'stdin': _b64(stdin),
              'cpu_time_limit': 5,
            }),
          )
          .timeout(const Duration(seconds: 30));
    } catch (e) {
      return RunResult(error: 'Server nicht erreichbar: $e');
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      return const RunResult(
          error: 'Zugriff verweigert – bitte API-Key in den Einstellungen prüfen.');
    }
    if (response.statusCode == 429) {
      return const RunResult(
          error: 'Tageslimit des Servers erreicht. Bitte später erneut versuchen.');
    }
    if (response.statusCode >= 300) {
      return RunResult(
          error: 'Serverfehler ${response.statusCode}: ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final stdout = _unb64(json['stdout']);
    final stderr = _unb64(json['stderr']);
    final compile = _unb64(json['compile_output']);
    final statusId = (json['status'] as Map?)?['id'] as int? ?? 0;
    final statusText = (json['status'] as Map?)?['description'] as String? ?? '';

    switch (statusId) {
      case 3: // Accepted
        return RunResult(stdout: stdout, stderr: stderr);
      case 5:
        return RunResult(stdout: stdout, error: 'Zeitlimit überschritten (Endlosschleife?)');
      case 6:
        return RunResult(error: 'Kompilierfehler:\n$compile');
      default:
        return RunResult(
          stdout: stdout,
          stderr: stderr,
          error: 'Laufzeitfehler ($statusText)\n$stderr',
        );
    }
  }
}
