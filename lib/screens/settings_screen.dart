import 'package:flutter/material.dart';

import '../app_services.dart';
import 'package:flutter/services.dart';

import '../data/progress_store.dart';
import '../runner/platform_runners.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final ProgressStore _progress = AppServices.of(context).progress;
  late final _name = TextEditingController(text: _progress.userName);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await _progress.setUserName(_name.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Gespeichert')));
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<bool> _confirmReplace() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fortschritt ersetzen?'),
        content: const Text(
            'Dein aktueller Fortschritt auf diesem Gerät wird durch die '
            'Sicherung ersetzt.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Abbrechen')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ersetzen')),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _import(String? text) async {
    if (text == null || text.trim().isEmpty) return;
    if (!await _confirmReplace()) return;
    try {
      await _progress.importBackup(text);
      _name.text = _progress.userName;
      _snack('Fortschritt übernommen ✓');
    } on FormatException catch (e) {
      _snack(e.message);
    }
  }

  Future<void> _copyCode() async {
    await Clipboard.setData(ClipboardData(text: _progress.exportCode()));
    _snack('Übertragungscode kopiert – auf dem anderen Gerät einfügen.');
  }

  Future<void> _pasteCode() async {
    final controller = TextEditingController();
    final clip = await Clipboard.getData(Clipboard.kTextPlain);
    if (clip?.text?.startsWith('PT1:') ?? false) controller.text = clip!.text!;
    if (!mounted) return;
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Übertragungscode einfügen'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'PT1:…',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen')),
          FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Übernehmen')),
        ],
      ),
    );
    await _import(text);
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
          const SizedBox(height: 16),
          FilledButton(onPressed: _save, child: const Text('Speichern')),
          const SizedBox(height: 32),
          Text('Fortschritt sichern & übertragen',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text(
              'Dein Fortschritt wird nur auf diesem Gerät gespeichert. Mit dem '
              'Übertragungscode nimmst du ihn auf ein anderes Gerät mit, z. B. '
              'vom Handy in die Web-Version am PC.'),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('Übertragungscode kopieren'),
            onPressed: _copyCode,
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.content_paste),
            label: const Text('Übertragungscode einfügen'),
            onPressed: _pasteCode,
          ),
          if (supportsBackupFiles) ...[
            OutlinedButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('Sicherung herunterladen'),
              onPressed: () => downloadTextFile(
                  'prog_trainer_fortschritt.json', _progress.exportJson()),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text('Sicherung öffnen'),
              onPressed: () async => _import(await pickTextFile()),
            ),
          ],
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
