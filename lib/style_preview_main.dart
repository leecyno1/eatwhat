import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/style_preview/style_preview_screen.dart';

void main() {
  runApp(const _PreviewApp());
}

class _PreviewApp extends StatelessWidget {
  const _PreviewApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.roundedPastel,
      home: const StylePreviewScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
