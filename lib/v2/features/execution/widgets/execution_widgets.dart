import 'package:eatwhat_app/core/config/env_config.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_types.dart';
import 'package:eatwhat_app/v2/core/theme/app_colors.dart';
import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:eatwhat_app/v2/features/home/widgets/floating_editorial_background.dart';
import 'package:flutter/material.dart';

class ExecutionAsyncScaffold<T> extends StatelessWidget {
  const ExecutionAsyncScaffold({
    super.key,
    required this.title,
    required this.accent,
    required this.future,
    required this.builder,
    this.onRefresh,
    this.errorBuilder,
  });

  final String title;
  final Color accent;
  final Future<T> future;
  final Widget Function(BuildContext context, T snapshot) builder;
  final VoidCallback? onRefresh;
  final Widget Function(BuildContext context, Object error)? errorBuilder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: Stack(
        children: [
          const FloatingEditorialBackground(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(child: Text(title, style: AppType.section)),
                      if (onRefresh != null)
                        IconButton(
                          key: const ValueKey('execution-refresh-button'),
                          tooltip: '刷新',
                          onPressed: onRefresh,
                          icon: const Icon(Icons.refresh_rounded),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: FutureBuilder<T>(
                    future: future,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        if (errorBuilder != null) {
                          return errorBuilder!(context, snapshot.error!);
                        }
                        return const ExecutionUnavailableState(
                          title: '暂时连接不上',
                          description: '附近服务没有及时返回结果，稍后再试一次。',
                        );
                      }
                      if (!snapshot.hasData) {
                        return const ExecutionLoadingState();
                      }
                      return builder(context, snapshot.data as T);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ExecutionLoadingState extends StatelessWidget {
  const ExecutionLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: AppDecorations.card(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: AppSpacing.sm),
            Text('正在读取附近服务', style: AppType.label),
          ],
        ),
      ),
    );
  }
}

class ExecutionUnavailableState extends StatelessWidget {
  const ExecutionUnavailableState({
    super.key,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: LayoutBuilder(builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: executionGlassBoxDecoration(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title,
                        textAlign: TextAlign.center, style: AppType.title),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      description,
                      textAlign: TextAlign.center,
                      style: AppType.body.copyWith(
                        color: AppPalette.ink.withValues(alpha: 0.68),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (actionLabel != null && onAction != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      FilledButton(
                        onPressed: onAction,
                        child: Text(actionLabel!),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class ExecutionStatusLayout extends StatelessWidget {
  const ExecutionStatusLayout({
    super.key,
    required this.providerStates,
    required this.child,
    this.diagnostics,
  });

  final List<ProviderAvailability> providerStates;
  final Widget child;
  final Widget? diagnostics;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (providerStates.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
            child: ExecutionProviderStatusPanel(providerStates: providerStates),
          ),
        if (diagnostics != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
            child: diagnostics!,
          ),
        Expanded(child: child),
      ],
    );
  }
}

class ExecutionProxyPanel extends StatelessWidget {
  const ExecutionProxyPanel({
    super.key,
    required this.snapshot,
    this.requestedAt,
  });

  final DeliveryExecutionSnapshot snapshot;
  final DateTime? requestedAt;

  @override
  Widget build(BuildContext context) {
    final sources = snapshot.matches
        .map((match) => match.source.trim())
        .where((source) => source.isNotEmpty)
        .toSet()
        .toList();

    return Container(
      key: const ValueKey('execution-proxy-panel'),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: executionGlassBoxDecoration().copyWith(
        border: Border.all(
          color: AppPalette.ocean.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('服务状态', style: AppType.label),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              const ExecutionCapsule(
                label: '外卖服务 · 可刷新',
                background: Color(0x162D9CDB),
                foreground: AppPalette.ocean,
              ),
              for (final source in sources)
                ExecutionCapsule(
                  label: '来源 · $source',
                  background: const Color(0x162D9CDB),
                  foreground: AppPalette.ocean,
                ),
              if (EnvConfig.debugMode)
                ExecutionCapsule(
                  label: '服务地址 · ${_proxyBaseUrlLabel()}',
                  background: const Color(0x162D9CDB),
                  foreground: AppPalette.ocean,
                ),
              if (EnvConfig.debugMode)
                ExecutionCapsule(
                  label: '路径 · ${EnvConfig.meituanDeliveryMatchPath}',
                  background: const Color(0x162D9CDB),
                  foreground: AppPalette.ocean,
                ),
            ],
          ),
          if (snapshot.message != null &&
              snapshot.message!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              '最近结果 · ${snapshot.message!}',
              style: AppType.body.copyWith(
                fontSize: 13,
                color: AppPalette.ink.withValues(alpha: 0.72),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (requestedAt != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              '最近刷新 · ${_formatRequestedAt(requestedAt!)}',
              style: AppType.label.copyWith(
                color: AppPalette.ink.withValues(alpha: 0.56),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatRequestedAt(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    final second = value.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  String _proxyBaseUrlLabel() {
    final raw = EnvConfig.executionProxyBaseUrl.trim();
    if (raw.isEmpty) {
      return '未配置';
    }
    if (raw.contains('127.0.0.1') || raw.contains('localhost')) {
      return '$raw (本地)';
    }
    return raw;
  }
}

class ExecutionProviderStatusPanel extends StatelessWidget {
  const ExecutionProviderStatusPanel({
    super.key,
    required this.providerStates,
  });

  final List<ProviderAvailability> providerStates;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: executionGlassBoxDecoration().copyWith(
        border: Border.all(color: AppPalette.rice.withValues(alpha: 0.74)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('平台状态', style: AppType.label),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final state in providerStates)
                ExecutionCapsule(
                  label: state.reason == null
                      ? state.displayName
                      : '${state.displayName} · ${state.reason}',
                  background: state.isConfigured
                      ? AppPalette.rice.withValues(alpha: 0.56)
                      : const Color(0xFFFFE6E1),
                  foreground: AppPalette.ink,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class ExecutionResultCard extends StatelessWidget {
  const ExecutionResultCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.accent,
    this.metadata = const [],
    this.note,
    this.actionLabel,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final List<String> metadata;
  final String? note;
  final String? actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: executionGlassBoxDecoration().copyWith(
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppType.section),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: AppType.body.copyWith(
              fontSize: 13,
              color: AppPalette.ink.withValues(alpha: 0.66),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (metadata.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final item in metadata)
                  ExecutionCapsule(
                    label: item,
                    background: accent.withValues(alpha: 0.1),
                    foreground: accent,
                  ),
              ],
            ),
          ],
          if (note != null && note!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              note!,
              style: AppType.body.copyWith(
                fontSize: 13,
                color: AppPalette.ink.withValues(alpha: 0.72),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (actionLabel != null) ...[
            const SizedBox(height: AppSpacing.sm),
            FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: AppPalette.rice,
                disabledBackgroundColor: accent.withValues(alpha: 0.24),
                disabledForegroundColor: AppPalette.ink.withValues(alpha: 0.54),
              ),
              child: Text(
                actionLabel!,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ExecutionPathCard extends StatelessWidget {
  const ExecutionPathCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
    required this.onTap,
    this.isRecommended = false,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final IconData icon;
  final VoidCallback onTap;
  final bool isRecommended;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.panel,
        child: Ink(
          decoration: executionGlassBoxDecoration().copyWith(
            border: Border.all(color: AppPalette.divider),
            color: AppPalette.surface,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    color: accent.withValues(alpha: 0.14),
                  ),
                  child: Icon(icon, color: accent),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: AppType.section.copyWith(
                                fontSize: 20,
                                color: AppPalette.ink,
                              ),
                            ),
                          ),
                          if (isRecommended)
                            ExecutionCapsule(
                              label: '推荐',
                              background: accent.withValues(alpha: 0.12),
                              foreground: accent,
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        subtitle,
                        style: AppType.body.copyWith(
                          fontSize: 13,
                          color: AppPalette.ink.withValues(alpha: 0.64),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_rounded, color: accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ExecutionCapsule extends StatelessWidget {
  const ExecutionCapsule({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadii.capsule,
        border: Border.all(color: AppPalette.rice.withValues(alpha: 0.62)),
      ),
      child: Text(
        label,
        style: AppType.microLabel.copyWith(
          color: foreground,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

BoxDecoration executionGlassBoxDecoration() {
  return AppDecorations.card();
}
