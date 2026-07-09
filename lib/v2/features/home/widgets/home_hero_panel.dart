import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class HomeHeroPanel extends StatelessWidget {
  const HomeHeroPanel({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xF7FFF8F2),
            Color(0xD9FFFFFF),
            Color(0xE6FFDCCF),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.75),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x261A0E0B),
            blurRadius: 28,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF151219),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'EAT WHAT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '今天想吃什么',
                style: TextStyle(
                  color: AppColors.textPrimary.withValues(alpha: 0.58),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '输入一句话，下面再滑几个偏好实体，系统会把两路信号一起送进下一步生成。',
            style: TextStyle(
              color: AppColors.textPrimary.withValues(alpha: 0.7),
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.56),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            child: TextField(
              key: const ValueKey('home-requirement-input'),
              controller: controller,
              focusNode: focusNode,
              minLines: 4,
              maxLines: 5,
              textInputAction: TextInputAction.done,
              onTapOutside: (_) => focusNode.unfocus(),
              onSubmitted: (_) => onSubmit(),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                height: 1.6,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: '比如：今晚想吃热一点、有锅气、别太腻，最好一个人也能满足。',
                hintStyle: TextStyle(
                  color: AppColors.textPrimary.withValues(alpha: 0.4),
                  fontSize: 15,
                  height: 1.55,
                  fontWeight: FontWeight.w500,
                ),
                contentPadding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
