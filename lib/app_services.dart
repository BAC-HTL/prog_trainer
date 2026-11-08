import 'package:flutter/widgets.dart';

import 'data/content_repository.dart';
import 'data/progress_store.dart';
import 'runner/code_runner.dart';

/// Stellt die zentralen Dienste allen Screens zur Verfügung.
class AppServices extends InheritedWidget {
  const AppServices({
    super.key,
    required this.repository,
    required this.progress,
    required this.runnerFor,
    required super.child,
  });

  final ContentRepository repository;
  final ProgressStore progress;

  /// Liefert den Code-Runner für eine Laufzeit (`python`, `csharp`) oder
  /// `null`, wenn diese (noch) nicht eingerichtet ist.
  final CodeRunner? Function(String runtime) runnerFor;

  static AppServices of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppServices>()!;

  @override
  bool updateShouldNotify(AppServices oldWidget) => false;
}
