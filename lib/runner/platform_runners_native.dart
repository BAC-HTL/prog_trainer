import 'package:flutter/widgets.dart';

import 'code_runner.dart';
import 'webview_runner.dart';

/// Android/iOS: Python und C# laufen in einer unsichtbaren WebView.
Map<String, CodeRunner> createRunners() => {
      'python': WebViewRunner.python(),
      'csharp': WebViewRunner.csharp(),
    };

/// Hängt die WebViews unsichtbar in den Widget-Baum.
List<Widget> runtimeHosts(Iterable<CodeRunner?> runners) => [
      for (final r in runners.whereType<WebViewRunner>())
        Positioned(left: 0, top: 0, child: RuntimeHost(runner: r)),
    ];

/// Dateien speichern/öffnen gibt es nur in der Web-Version; am Handy wird
/// der Übertragungscode verwendet.
const bool supportsBackupFiles = false;

Future<void> downloadTextFile(String name, String text) async {}

Future<String?> pickTextFile() async => null;
