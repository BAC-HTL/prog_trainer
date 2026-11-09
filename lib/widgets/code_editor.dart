import 'package:flutter/material.dart';

/// Einfacher Code-Editor fürs Handy: Monospace-Feld plus eine Leiste mit
/// Zeichen, die auf Handytastaturen schwer zu finden sind.
class CodeEditor extends StatelessWidget {
  const CodeEditor({super.key, required this.controller, this.minLines = 10});

  final TextEditingController controller;
  final int minLines;

  static const _snippets = [
    '    ', '(', ')', ':', '"', '=', '[', ']', '{', '}', ';', '+', '<', '>', '.', ',', '_',
  ];

  void _insert(String text) {
    final sel = controller.selection;
    final value = controller.text;
    final start = sel.isValid ? sel.start : value.length;
    final end = sel.isValid ? sel.end : value.length;
    controller.value = TextEditingValue(
      text: value.replaceRange(start, end, text),
      selection: TextSelection.collapsed(offset: start + text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2E),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: controller,
            maxLines: null,
            minLines: minLines,
            keyboardType: TextInputType.multiline,
            autocorrect: false,
            enableSuggestions: false,
            smartQuotesType: SmartQuotesType.disabled,
            smartDashesType: SmartDashesType.disabled,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              color: Color(0xFFCDD6F4),
              height: 1.4,
            ),
            cursorColor: Colors.white,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(12),
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final s in _snippets)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ActionChip(
                    label: Text(s == '    ' ? '⇥' : s,
                        style: const TextStyle(fontFamily: 'monospace')),
                    onPressed: () => _insert(s),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
