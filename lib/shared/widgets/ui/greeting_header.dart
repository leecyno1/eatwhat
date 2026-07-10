import 'package:flutter/material.dart';
import '../../../shared/themes/design_tokens.dart';

class GreetingHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? avatarUrl;
  final VoidCallback? onAvatarTap;

  const GreetingHeader(
      {super.key, required this.title, required this.subtitle, this.avatarUrl, this.onAvatarTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: DesignTokens.h2),
                const SizedBox(height: 4),
                Text(subtitle, style: DesignTokens.caption),
              ],
            ),
          ),
          GestureDetector(
            onTap: onAvatarTap,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                boxShadow: DesignTokens.softShadows(),
                border: Border.all(color: Colors.white, width: 2),
                image: avatarUrl != null
                    ? DecorationImage(image: NetworkImage(avatarUrl!), fit: BoxFit.cover)
                    : null,
                color: DesignTokens.surface,
              ),
              child: avatarUrl == null
                  ? const Icon(Icons.person_outline_rounded, color: DesignTokens.ink)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
