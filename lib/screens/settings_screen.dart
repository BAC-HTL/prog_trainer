import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/progress_store.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final ProgressStore _progress = AppServices.of(context).progress;
  late final _name = TextEditingController(text: _progress.userName);
  late final _url = TextEditingController(text: _progress.judge0Url);
  late final _key = TextEditingController(text: _progress.judge0Key);

  @override
  void dispose() {
    _name.dispose();
    _url.dispose();
    _key.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await _progress.setUserName(_name.text);
    await _progress.setJudge0(_url.text, _key.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Gespeichert')));
  }

  Future<void> _reset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fortschritt zurücksetzen?'),
        content: const Text(
            'Lektionen, Prüfungen, Punkte und Achievements werden gelöscht. '
            'Das kann nicht rückgängig gemacht werden.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Abbrechen')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Zurücksetzen')),
        ],
      ),
    );
    if (ok == true) await _progress.resetProgress();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Profil', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Name auf Zertifikaten',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          Text('C#-Ausführung (Judge0)', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text(
            'C# wird auf einem Judge0-Server kompiliert. Am einfachsten: '
            'kostenlosen Key für „Judge0 CE“ auf rapidapi.com holen '
            '(Basic-Plan, 50 Ausführungen pro Tag) und hier eintragen. '
            'Alternativ die Adresse eines eigenen Judge0-Servers angeben. '
            'Python läuft direkt am Handy und braucht keinen Key.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _url,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Server-Adresse',
              helperText: 'Standard: $defaultJudge0Url',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _key,
            autocorrect: false,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'API-Key',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _save, child: const Text('Speichern')),
          const SizedBox(height: 32),
          Text('Daten', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.delete_forever),
            label: const Text('Fortschritt zurücksetzen'),
            onPressed: _reset,
          ),
        ],
      ),
    );
  }
}
