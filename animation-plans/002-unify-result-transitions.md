# 002 — Unify result state transitions

- **Status**: TODO
- **Commit**: 4e9e89b
- **Severity**: HIGH
- **Category**: Easing & duration
- **Estimated scope**: 3 files, medium

## Problem

`lib/v2/features/result/result_page.dart:967-975` uses a 360ms switch and an `easeInCubic` exit:

```dart
AnimatedSwitcher(
  duration: const Duration(milliseconds: 360),
  switchInCurve: Curves.easeOutCubic,
  switchOutCurve: Curves.easeInCubic,
```

The result page also applies several independent `flutter_animate` slide entrances to controls and content. These repeated slides make mode and candidate changes feel delayed, and `ease-in` starts the exit slowly at the exact moment the user expects an immediate response.

## Target

- Use `AppMotion.standard` (`240ms`) for single-dish/meal mode and candidate content switches.
- Use `AppMotion.enter` (`Cubic(0.23, 1, 0.32, 1)`) for both switch-in and switch-out opacity.
- Use a subtle `FadeTransition` plus `ScaleTransition` from `0.97` to `1`; never scale from zero.
- Remove repeated slide entrances from high-frequency result controls and sections.
- With reduced motion enabled, use a `180ms` opacity-only crossfade and no scale or translation.

## Repo conventions to follow

- Shared values are in `lib/v2/core/theme/app_tokens.dart`.
- Result mode tabs already use a 220ms state color transition in `lib/v2/features/result/widgets/result_recommendation_mode_tabs.dart`; preserve the component and its keys.

## Steps

1. In `lib/v2/features/result/result_page.dart`, replace the 360ms `AnimatedSwitcher` curves with `AppMotion.standard` and `AppMotion.enter`.
2. Supply a transition builder that fades and scales from `0.97`; when `MediaQuery.disableAnimationsOf(context)` is true, fade only.
3. Remove `.slideX()` and `.slideY()` chains from the execution shortcuts, tags, title, introduction, and pairing band. Keep a single short fade for initial page presentation if needed.
4. In `lib/v2/features/result/widgets/result_action_bar.dart`, remove the delayed `scale()` entrance on the primary actions; keep immediate press feedback in the button itself.
5. Ensure candidate changes, mode changes, and rerolls retarget from the current visible state without input lockout.

## Boundaries

- Do not alter result selection, telemetry, favorite, image generation, nutrition, pairing, execution, or routing logic.
- Keep all existing `ValueKey` values.
- Do not add dependencies.

## Verification

- **Mechanical**: run `flutter analyze lib/v2/features/result/result_page.dart lib/v2/features/result/widgets/result_action_bar.dart` and the result widget tests.
- **Feel check**: rapidly alternate `一个菜` / `一顿饭` and tap several candidates. Content must respond instantly, never pause on exit, and never double-expose for a noticeable time.
- Enable Reduce Motion and confirm changes become opacity-only.
- **Done when**: every result state change uses one coherent 240ms-or-less transition and repeated slides are gone.

