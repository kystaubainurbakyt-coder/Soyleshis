import 'package:flutter/material.dart';
import 'package:soyle/core/database/learning_repository.dart';
import 'package:soyle/core/localization/app_locale.dart';
import 'package:soyle/core/state/app_state.dart';
import 'package:soyle/features/lessons/data/lesson_service.dart';
import 'package:soyle/core/database/models/local_entities.dart';
import 'package:soyle/shared/widgets/adaptive_content.dart';
import 'package:soyle/shared/widgets/empty_state.dart';
import 'package:soyle/shared/widgets/learning_ui.dart';
import 'package:soyle/features/notebook/presentation/screens/rest_api_screen.dart';

class NotebookScreen extends StatefulWidget {
  const NotebookScreen({super.key});
  @override
  State<NotebookScreen> createState() => _NotebookScreenState();
}

class _NotebookScreenState extends State<NotebookScreen> {
  String query = '';
  String? level;
  int? lessonId;
  bool favoritesOnly = false, initialized = false, busy = false;
  NoteSort sort = NoteSort.updated;
  LearningRepository? get repository => AppState.instance.repository;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!initialized) {
      initialized = true;
      final argument = ModalRoute.of(context)?.settings.arguments;
      if (argument is int) lessonId = argument;
    }
  }

  void showError() {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr('databaseError'))));
    }
  }

  Future<void> edit([StudyNote? note]) async {
    final store = repository;
    if (store == null) {
      showError();
      return;
    }
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _NoteEditor(
        repository: store,
        owner: AppState.instance.email,
        note: note,
        lessonId: lessonId,
      ),
    );
    if (!mounted || result != true) return;
    setState(() {});
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(tr('noteSaved'))));
  }

  Future<void> favorite(StudyNote note) async {
    setState(() => busy = true);
    try {
      await repository!.saveNote(
        note.ownerId,
        id: note.id,
        lessonId: note.lessonId,
        title: note.title,
        body: note.body,
        priority: note.priority,
        favorite: !note.favorite,
      );
    } catch (_) {
      showError();
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> remove(StudyNote note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(tr('deleteNote')),
        content: Text(tr('deleteNoteHint')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: Text(tr('noteCancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(tr('noteDelete')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => busy = true);
    try {
      await repository!.deleteNote(note.ownerId, note.id);
    } catch (_) {
      showError();
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    List<StudyNote> notes = [];
    var failed = false;
    try {
      final store = repository;
      if (store == null) throw const LocalDatabaseException('initialize');
      notes = store.queryNotes(
        AppState.instance.email,
        query: query,
        level: level,
        lessonId: lessonId,
        favoritesOnly: favoritesOnly,
        sort: sort,
      );
    } catch (_) {
      failed = true;
    }
    final lessons = AppState.curriculum;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('notebook')),
        actions: [
          IconButton(
            tooltip: tr('restApi'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const RestApiScreen()),
            ),
            icon: const Icon(Icons.cloud_sync_outlined),
          ),
          const LanguageSwitch(),
          const SizedBox(width: 14),
        ],
      ),
      floatingActionButton: failed
          ? null
          : FloatingActionButton.extended(
              key: const ValueKey('add-note'),
              onPressed: busy ? null : () => edit(),
              icon: const Icon(Icons.add),
              label: Text(tr('addNote')),
            ),
      body: AdaptiveContent(
        maxWidth: 900,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: TextField(
                key: const ValueKey('notes-search'),
                decoration: InputDecoration(
                  hintText: tr('notesSearch'),
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: (value) => setState(() => query = value),
              ),
            ),
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  for (final value in [null, ...LessonService.levels])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(value ?? tr('allLevels')),
                        selected: level == value,
                        onSelected: (_) => setState(() => level = value),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Wrap(
                spacing: 12,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FilterChip(
                    label: Text(tr('onlyFavorites')),
                    selected: favoritesOnly,
                    onSelected: (value) =>
                        setState(() => favoritesOnly = value),
                  ),
                  DropdownButton<NoteSort>(
                    value: sort,
                    underline: const SizedBox(),
                    items: [
                      for (final option in NoteSort.values)
                        DropdownMenuItem(
                          value: option,
                          child: Text(
                            tr(switch (option) {
                              NoteSort.updated => 'sortUpdated',
                              NoteSort.title => 'sortTitle',
                              NoteSort.priority => 'sortPriority',
                            }),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                    ],
                    onChanged: (value) => setState(() => sort = value ?? sort),
                  ),
                  if (lessonId != null)
                    InputChip(
                      label: Text(tr('lessonNotes')),
                      onDeleted: () => setState(() => lessonId = null),
                    ),
                ],
              ),
            ),
            if (busy) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: failed
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              tr('databaseError'),
                              textAlign: TextAlign.center,
                            ),
                            TextButton(
                              onPressed: () => setState(() {}),
                              child: Text(tr('retry')),
                            ),
                          ],
                        ),
                      ),
                    )
                  : notes.isEmpty
                  ? EmptyState(
                      title: tr(
                        query.isEmpty && level == null && !favoritesOnly
                            ? 'notesEmpty'
                            : 'noResults',
                      ),
                      message: tr('notesEmptyHint'),
                      icon: Icons.edit_note_outlined,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                      itemCount: notes.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final note = notes[index];
                        final lesson = lessons.firstWhere(
                          (l) => l.id == note.lessonId,
                        );
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        note.title,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: tr('onlyFavorites'),
                                      onPressed: busy
                                          ? null
                                          : () => favorite(note),
                                      icon: Icon(
                                        note.favorite
                                            ? Icons.star_rounded
                                            : Icons.star_outline_rounded,
                                        color: const Color(0xFFAA8137),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${lesson.level} · ${lesson.displayTitle}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 12),
                                SelectableText(
                                  note.body,
                                  style: const TextStyle(height: 1.7),
                                ),
                                const SizedBox(height: 14),
                                Wrap(
                                  spacing: 8,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Chip(
                                      label: Text(
                                        tr('priority${note.priority}'),
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: busy ? null : () => edit(note),
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        size: 18,
                                      ),
                                      label: Text(tr('editNote')),
                                    ),
                                    IconButton(
                                      tooltip: tr('noteDelete'),
                                      onPressed: busy
                                          ? null
                                          : () => remove(note),
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteEditor extends StatefulWidget {
  const _NoteEditor({
    required this.repository,
    required this.owner,
    this.note,
    this.lessonId,
  });
  final LearningRepository repository;
  final String owner;
  final StudyNote? note;
  final int? lessonId;
  @override
  State<_NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<_NoteEditor> {
  final form = GlobalKey<FormState>();
  late final title = TextEditingController(text: widget.note?.title ?? '');
  late final body = TextEditingController(text: widget.note?.body ?? '');
  late int lesson =
      widget.note?.lessonId ?? widget.lessonId ?? AppState.curriculum.first.id;
  late int priority = widget.note?.priority ?? 1;
  bool saving = false;
  String? error;
  @override
  void dispose() {
    title.dispose();
    body.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (saving || !form.currentState!.validate()) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      if (AppState.instance.email != widget.owner) {
        throw const LocalDatabaseException('account');
      }
      await widget.repository.saveNote(
        widget.owner,
        id: widget.note?.id,
        lessonId: lesson,
        title: title.text,
        body: body.text,
        priority: priority,
        favorite: widget.note?.favorite ?? false,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          saving = false;
          error = tr('databaseError');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !saving,
    child: AlertDialog(
      title: Text(tr(widget.note == null ? 'addNote' : 'editNote')),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  key: const ValueKey('note-title'),
                  controller: title,
                  enabled: !saving,
                  maxLength: 80,
                  decoration: InputDecoration(labelText: tr('noteTitle')),
                  validator: (v) =>
                      (v?.trim().length ?? 0) < 3 ? tr('noteTitleError') : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: lesson,
                  isExpanded: true,
                  menuMaxHeight: 320,
                  decoration: InputDecoration(labelText: tr('noteLesson')),
                  items: [
                    for (final l in AppState.curriculum)
                      DropdownMenuItem(
                        value: l.id,
                        child: Text(
                          '${l.level} · ${l.displayTitle}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: saving
                      ? null
                      : (value) => setState(() => lesson = value ?? lesson),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const ValueKey('note-body'),
                  controller: body,
                  enabled: !saving,
                  minLines: 4,
                  maxLines: 8,
                  maxLength: 2000,
                  decoration: InputDecoration(
                    labelText: tr('noteBody'),
                    alignLabelWithHint: true,
                  ),
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? tr('noteBodyError') : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: priority,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: tr('notePriority')),
                  items: [
                    for (final value in [1, 2, 3])
                      DropdownMenuItem(
                        value: value,
                        child: Text(
                          tr('priority$value'),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: saving
                      ? null
                      : (value) => setState(() => priority = value ?? priority),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(context, false),
          child: Text(tr('noteCancel')),
        ),
        FilledButton(
          onPressed: saving ? null : save,
          child: Text(tr('noteSave')),
        ),
      ],
    ),
  );
}
