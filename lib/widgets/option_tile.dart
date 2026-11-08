import 'package:flutter/material.dart';

enum OptionState { neutral, selected, correct, wrong }

/// Antwortmöglichkeit in Quiz und Prüfung.
class OptionTile extends StatelessWidget {
  const OptionTile({
    super.key,
    required this.text,
    required this.state,
    required this.onTap,
  });

  final String text;
  final OptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (Color? color, IconData? icon) = switch (state) {
      OptionState.correct => (Colors.green.shade100, Icons.check_circle),
      OptionState.wrong => (Colors.red.shade100, Icons.cancel),
      OptionState.selected => (scheme.primaryContainer, Icons.radio_button_checked),
      OptionState.neutral => (null, null),
    };

    return Card(
      color: color,
      child: ListTile(
        title: Text(text),
        trailing: icon == null ? null : Icon(icon),
        onTap: onTap,
      ),
    );
  }
}
