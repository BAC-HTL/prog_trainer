import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/progress_store.dart';
import '../models/curriculum.dart';
import '../widgets/track_icon.dart';
import 'chapter_screen.dart';

/// Tab "Lernen": Lehrplan der HTL für Informatik (1.–5. Jahrgang) plus
/// Junior/Senior/Expert – nach Stufe, Fach und Thema filterbar.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<Curriculum>? _curriculum;

  /// `null` = alle Stufen.
  String? _stage = 'j1';
  final Set<String> _subjects = {};
  final Set<String> _topics = {};
  bool _onlyAvailable = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _curriculum ??= AppServices.of(context).repository.loadCurriculum();
  }

  int get _filterCount =>
      _subjects.length + _topics.length + (_onlyAvailable ? 1 : 0);

  bool _matches(CurriculumModule m, String language) {
    if (_stage != null && m.stage != _stage) return false;
    if (_subjects.isNotEmpty && !_subjects.contains(m.subject)) return false;
    if (_topics.isNotEmpty && !m.topics.any(_topics.contains)) return false;
    if (_onlyAvailable && !(m.contentFor(language)?.isAvailable ?? false)) {
      return false;
    }
    return true;
  }

  Future<void> _openFilter(Curriculum c) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) {
          void update(VoidCallback f) {
            setSheet(f);
            setState(() {});
          }

          final theme = Theme.of(context);
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.75,
            builder: (context, scroll) => ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                Row(children: [
                  Text('Filter', style: theme.textTheme.titleLarge),
                  const Spacer(),
                  TextButton(
                    onPressed: _filterCount == 0
                        ? null
                        : () => update(() {
                              _subjects.clear();
                              _topics.clear();
                              _onlyAvailable = false;
                            }),
                    child: const Text('Zurücksetzen'),
                  ),
                ]),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Nur verfügbare Module'),
                  value: _onlyAvailable,
                  onChanged: (v) => update(() => _onlyAvailable = v),
                ),
                const SizedBox(height: 8),
                Text('Fächer', style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Wrap(spacing: 8, runSpacing: 4, children: [
                  for (final s in c.subjects)
                    FilterChip(
                      avatar: Icon(subjectIcon(s.icon), size: 18),
                      label: Text(s.id),
                      tooltip: s.title,
                      selected: _subjects.contains(s.id),
                      onSelected: (on) => update(
                          () => on ? _subjects.add(s.id) : _subjects.remove(s.id)),
                    ),
                ]),
                const SizedBox(height: 16),
                Text('Themen', style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Wrap(spacing: 8, runSpacing: 4, children: [
                  for (final t in c.topics)
                    FilterChip(
                      label: Text(t.title),
                      selected: _topics.contains(t.id),
                      onSelected: (on) => update(
                          () => on ? _topics.add(t.id) : _topics.remove(t.id)),
                    ),
                ]),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Anzeigen'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = AppServices.of(context).progress;
    return FutureBuilder<Curriculum>(
      future: _curriculum,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
              child: Text('Inhalte konnten nicht geladen werden:\n${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final c = snapshot.data!;
        return ListenableBuilder(
          listenable: progress,
          builder: (context, _) => _buildContent(c, progress),
        );
      },
    );
  }

  Widget _buildContent(Curriculum c, ProgressStore progress) {
    final theme = Theme.of(context);
    final language = progress.language;
    final modules = c.modules.where((m) => _matches(m, language)).toList();

    // Gruppieren: bei einer Stufe nach Fach, bei „Alle“ nach Stufe.
    final groups = <String, List<CurriculumModule>>{};
    for (final m in modules) {
      groups.putIfAbsent(_stage == null ? m.stage : m.subject, () => []).add(m);
    }
    final stage = _stage == null ? null : c.stage(_stage!);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Row(children: [
          Image.asset('assets/icon/logo_mark.png', width: 48, height: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Was möchtest du heute lernen?',
                style: theme.textTheme.titleLarge),
          ),
        ]),
        const SizedBox(height: 12),
        // Stufen
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: const Text('Alle'),
                  selected: _stage == null,
                  onSelected: (_) => setState(() => _stage = null),
                ),
              ),
              for (final s in c.stages)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(s.title),
                    selected: _stage == s.id,
                    onSelected: (_) => setState(() => _stage = s.id),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(children: [
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: [
              for (final l in c.languages)
                ButtonSegment(value: l.id, label: Text(l.title)),
            ],
            selected: {language},
            onSelectionChanged: (s) => progress.setLanguage(s.first),
          ),
          const Spacer(),
          Badge(
            isLabelVisible: _filterCount > 0,
            label: Text('$_filterCount'),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.filter_list),
              label: const Text('Filter'),
              onPressed: () => _openFilter(c),
            ),
          ),
        ]),
        if (_filterCount > 0) ...[
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 4, children: [
            for (final id in _subjects)
              InputChip(
                label: Text(id),
                onDeleted: () => setState(() => _subjects.remove(id)),
              ),
            for (final id in _topics)
              InputChip(
                label: Text(c.topic(id).title),
                onDeleted: () => setState(() => _topics.remove(id)),
              ),
            if (_onlyAvailable)
              InputChip(
                label: const Text('Nur verfügbare'),
                onDeleted: () => setState(() => _onlyAvailable = false),
              ),
          ]),
        ],
        if (stage != null) ...[
          const SizedBox(height: 12),
          Text(stage.description, style: theme.textTheme.bodyMedium),
        ],
        if (modules.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: Text('Keine Module für diesen Filter.')),
          ),
        for (final entry in groups.entries) ...[
          const SizedBox(height: 16),
          _GroupHeader(
            title: _stage == null
                ? c.stage(entry.key).title
                : '${entry.key} · ${c.subject(entry.key).title}',
            icon: _stage == null ? null : subjectIcon(c.subject(entry.key).icon),
          ),
          for (final m in entry.value)
            _ModuleTile(
              curriculum: c,
              module: m,
              language: language,
              showSubject: _stage == null,
            ),
        ],
      ],
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.title, this.icon});

  final String title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
      ]),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({
    required this.curriculum,
    required this.module,
    required this.language,
    required this.showSubject,
  });

  final Curriculum curriculum;
  final CurriculumModule module;
  final String language;
  final bool showSubject;

  @override
  Widget build(BuildContext context) {
    final progress = AppServices.of(context).progress;
    final content = module.contentFor(language);
    final available = content?.isAvailable ?? false;
    final total = content?.lessonPaths.length ?? 0;
    final done = content?.lessonPaths.where(progress.isLessonCompleted).length ?? 0;
    final passed = content != null && progress.isExamPassed(content.id);

    final status = content == null
        ? (module.notes[language] ??
            'Für ${curriculum.languageTitle(language)} nicht vorhanden')
        : !available
            ? 'Bald verfügbar'
            : '$done/$total Lektionen';
    final meta = [
      if (showSubject) module.subject,
      if (module.semester != null) '${module.semester}. Semester',
      if (module.isLanguageSpecific) curriculum.languageTitle(language),
    ].join(' · ');

    return Card(
      child: ListTile(
        enabled: available,
        leading: passed
            ? const Icon(Icons.workspace_premium, color: Colors.amber, size: 30)
            : SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  value: total == 0 ? 0 : done / total,
                  strokeWidth: 3,
                ),
              ),
        title: Text(module.titleFor(language)),
        subtitle: Text([
          module.description,
          if (meta.isNotEmpty) meta,
          status,
        ].join('\n')),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          final ctx = ChapterContext.of(curriculum, module, language);
          if (ctx == null) return;
          Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => ChapterScreen(chapter: ctx),
          ));
        },
      ),
    );
  }
}
