import 'package:flutter/material.dart';

class PairingSuggestion {
  const PairingSuggestion({
    required this.category,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
  });

  final String category;
  final String title;
  final String subtitle;
  final Color accent;
  final IconData icon;
}
