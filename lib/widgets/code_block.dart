import 'package:flutter/material.dart';

/// Zeigt Quellcode in einer dunklen Box mit Monospace-Schrift an.
class CodeBlock extends StatelessWidget {
  const CodeBlock(this.code, {super.key});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SelectableText(
          code,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            color: Color(0xFFCDD6F4),
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
