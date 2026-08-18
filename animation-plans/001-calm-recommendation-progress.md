# 001 — Replace the slot-machine recommendation motion

- **Status**: DONE
- **Commit**: verified on 018f70f (implementation landed before plan review)
- **Severity**: HIGH
- **Category**: Purpose & frequency
- **Estimated scope**: 1 file, medium

## Problem

`lib/v2/features/decision/decision_page.dart:113-118` starts a permanent orbit and a slot-machine timer for every recommendation:

```dart
_inferenceController = AnimationController(
  vsync: this,
  duration: const Duration(seconds: 10),
)..repeat();
_startSlotMachine();
```

`lib/v2/features/decision/decision_page.dart:219-238` changes the headline every 50 ms and triggers haptics on every tick:

```dart
_timer = Timer.periodic(Duration(milliseconds: _speed), (timer) {
  setState(() {
    _currentIndex = (_currentIndex + 1) % signals.length;
    _cycleCount++;
  });
  HapticFeedback.lightImpact();
});
```

This is frequent, non-causal feedback. It makes a short loading state feel like a game and can emit dozens of haptics before the result appears.

## Target

- Remove the slot-machine timer and continuously rotating orbit.
- Keep one stable headline and a linear, determinate-looking three-stage status list.
- Animate only stage state changes with `AppMotion.fast` (`180ms`) and `AppMotion.enter` (`Cubic(0.23, 1, 0.32, 1)`).
- Trigger `HapticFeedback.mediumImpact()` once, on final result completion.
- Navigate after at most `AppMotion.standard` (`240ms`); do not add an artificial 700ms wait.
- With reduced motion enabled, use opacity/color changes only and no translation or rotation.

## Repo conventions to follow

- Motion tokens live in `lib/v2/core/theme/app_tokens.dart` as `AppMotion.press`, `fast`, `standard`, `page`, `enter`, `move`, and `sheet`.
- Flat surfaces use `AppDecorations.card()` and `AppPalette.canvas` rather than blur or gradients.

## Steps

1. In `lib/v2/features/decision/decision_page.dart`, remove `_timer`, `_inferenceController`, `_currentIndex`, `_cycleCount`, `_speed`, `_startSlotMachine`, `_InferenceHalo`, and `_InferenceHaloPainter`.
2. When recommendation work starts, show a stable title such as `正在为你收束这一餐` and the user's top three signals as quiet tags.
3. Render recall, rerank, and completion as vertically stacked rows. Use `AnimatedContainer(duration: AppMotion.fast, curve: AppMotion.enter)` only for color/border changes.
4. On success or handled empty result, set the final stage and trigger one `HapticFeedback.mediumImpact()`.
5. Replace the 700ms navigation delay with `AppMotion.standard` and keep the existing `autoNavigateToResult` behavior.
6. Read `MediaQuery.disableAnimationsOf(context)` in the build path; when true, use `Duration.zero` for stage state transitions.

## Boundaries

- Do not change recommendation service behavior, timeout behavior, telemetry, routing data, or result contents.
- Do not add dependencies.
- Do not touch files outside `decision_page.dart` and its focused widget tests.
- If the cited flow no longer exists, stop and report instead of improvising.

## Verification

- **Mechanical**: run `flutter analyze lib/v2/features/decision/decision_page.dart` and `flutter test test/widget/v2_decision_page_phase2_test.dart test/widget/v2_decision_page_continuity_test.dart`.
- **Feel check**: start one recommendation on an iPhone simulator and confirm the page is quiet, no headline flickers, and exactly one haptic occurs when results finish.
- Toggle iOS Reduce Motion and confirm no rotating or translating element remains.
- **Done when**: recommendation progress communicates status without looping decoration or repeated haptics and routes to the same result data.

