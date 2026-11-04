import 'package:flutter/material.dart';
import 'package:soyle/app/router/app_routes.dart';
import 'package:soyle/core/localization/app_locale.dart';
import 'package:soyle/core/state/app_state.dart';
import 'package:soyle/features/lessons/data/lesson_service.dart';
import 'package:soyle/features/lessons/presentation/widgets/lesson_card.dart';
import 'package:soyle/shared/widgets/adaptive_content.dart';
import 'package:soyle/shared/widgets/app_navigation.dart';
import 'package:soyle/shared/widgets/app_text_field.dart';
import 'package:soyle/shared/widgets/empty_state.dart';
import 'package:soyle/shared/widgets/learning_ui.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key, this.search = false, this.favorites = false});
  final bool search, favorites;
  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  String query = '', level = '';
  bool initialized = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!initialized) {
      initialized = true;
      final arg = ModalRoute.of(context)?.settings.arguments;
      if (LessonService.levels.contains(arg)) level = arg as String;
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: AppState.instance,
    builder: (context, _) {
      final state = AppState.instance;
      final lessons = state.lessons
          .where(
            (l) =>
                (!widget.favorites || state.favorites.contains(l.id)) &&
                (level.isEmpty || l.level == level) &&
                '${l.displayTitle} ${l.words.map((w) => '${w.kk} ${w.translation}').join(' ')}'
                    .toLowerCase()
                    .contains(query.toLowerCase().trim()),
          )
          .toList();
      return Scaffold(
        appBar: AppBar(
          title: Text(
            tr(
              widget.search
                  ? 'search'
                  : widget.favorites
                  ? 'saved'
                  : 'courses',
            ),
          ),
          actions: const [LanguageSwitch(), SizedBox(width: 18)],
        ),
        bottomNavigationBar: AppNavigation(
          index: widget.search
              ? 2
              : widget.favorites
              ? 3
              : 1,
        ),
        body: AdaptiveContent(
          maxWidth: 1000,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                child: AppTextField(
                  decoration: InputDecoration(
                    hintText: tr('searchHint'),
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: (v) => setState(() => query = v),
                ),
              ),
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    for (final value in ['', ...LessonService.levels])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(value.isEmpty ? tr('allLevels') : value),
                          selected: level == value,
                          onSelected: (_) => setState(() => level = value),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: lessons.isEmpty
                    ? EmptyState(
                        title: tr(
                          widget.favorites && query.isEmpty
                              ? 'noSaved'
                              : 'noResults',
                        ),
                        message: tr(
                          widget.favorites && query.isEmpty
                              ? 'noSavedHint'
                              : 'searchAgain',
                        ),
                        icon: widget.favorites
                            ? Icons.bookmark_outline
                            : Icons.search_off,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: lessons.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, index) => LessonCard(
                          lesson: lessons[index],
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.lessonDetail,
                            arguments: lessons[index],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
