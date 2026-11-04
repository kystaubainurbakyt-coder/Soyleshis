import 'package:flutter/material.dart';
import 'package:soyle/core/localization/app_locale.dart';
import 'package:soyle/app/router/app_routes.dart';

class AppNavigation extends StatelessWidget {
  const AppNavigation({super.key, required this.index});
  final int index;
  @override
  Widget build(BuildContext context) => NavigationBar(
    selectedIndex: index,
    onDestinationSelected: (i) {
      if (i != index) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          [
            AppRoutes.home,
            AppRoutes.lessons,
            AppRoutes.search,
            AppRoutes.favorites,
            AppRoutes.profile,
          ][i],
          (_) => false,
        );
      }
    },
    destinations: [
      NavigationDestination(
        icon: const Icon(Icons.grid_view_outlined),
        selectedIcon: const Icon(Icons.grid_view_rounded),
        label: tr('home'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.auto_stories_outlined),
        selectedIcon: const Icon(Icons.auto_stories),
        label: tr('courses'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.search_rounded),
        label: tr('search'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.bookmark_border_rounded),
        selectedIcon: const Icon(Icons.bookmark_rounded),
        label: tr('saved'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.person_outline_rounded),
        selectedIcon: const Icon(Icons.person_rounded),
        label: tr('profile'),
      ),
    ],
  );
}
