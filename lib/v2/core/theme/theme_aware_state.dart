import 'package:flutter/widgets.dart';

import 'app_theme_controller.dart';

/// Pages read [AppPalette] through static getters, so Flutter cannot know
/// they depend on the active skin. Mix this into a page [State] to rebuild
/// whenever the theme changes (manual pick or day/night auto flip) without
/// losing page state.
mixin ThemeAwareStateMixin<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    AppThemeController.mode.addListener(_rebuildForTheme);
  }

  @override
  void dispose() {
    AppThemeController.mode.removeListener(_rebuildForTheme);
    super.dispose();
  }

  void _rebuildForTheme() {
    if (mounted) {
      setState(() {});
    }
  }
}