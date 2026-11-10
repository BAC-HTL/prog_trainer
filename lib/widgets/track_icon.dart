import 'package:flutter/material.dart';

/// Übersetzt den Icon-Namen aus der JSON-Datei in ein Material-Icon.
IconData trackIcon(String name) {
  switch (name) {
    case 'python':
      return Icons.terminal;
    case 'csharp':
      return Icons.code;
    case 'architecture':
      return Icons.architecture;
    case 'testing':
      return Icons.fact_check;
    case 'requirements':
      return Icons.assignment;
    default:
      return Icons.school;
  }
}

/// Icon für ein Fach aus curriculum.json.
IconData subjectIcon(String name) {
  switch (name) {
    case 'code':
      return Icons.code;
    case 'storage':
      return Icons.storage;
    case 'lan':
      return Icons.lan;
    case 'memory':
      return Icons.memory;
    case 'assignment':
      return Icons.assignment;
    default:
      return Icons.school;
  }
}
