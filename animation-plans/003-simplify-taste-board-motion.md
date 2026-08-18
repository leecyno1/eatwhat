# 003 — Simplify the taste-board page motion

- **Status**: OBSOLETE
- **Commit**: superseded by the alpha-silhouette physical entity stage (018f70f)

> The horizontal card deck this plan targeted was removed when the home stage
> was rebuilt around physical entities; its dead widget files
> (taste_card_deck / board_shell / minimal_card_face / deck_motion_layers)
> and their tests have been deleted.
- **Severity**: MEDIUM
- **Category**: Cohesion & tokens
- **Estimated scope**: 4 files, large

## Problem

`lib/v2/features/home/widgets/taste_card_deck.dart:201-370` combines horizontal dragging, outgoing ghost cards, per-row drift, shrinking, a highlight gradient, and a card-replacement slide. It also uses `Curves.easeInCubic` for outgoing replacement cards at lines 346-350.

`lib/v2/features/home/home_page.dart:115-126` starts separate 900ms, 320ms, and 520ms controllers, while `lib/v2/features/home/widgets/home_overlays.dart:23-26` repeats a 1400ms voice pulse. The motion language is much more playful than the desired calm mobile utility style.

## Target

- Page navigation should be vertical full-screen scrolling, not horizontal card-page switching.
- A floating `下一步` button scrolls to the next viewport with an interruptible `AppMotion.page` (`300ms`) movement using `AppMotion.move` (`Cubic(0.77, 0, 0.175, 1)`).
- Remove outgoing ghost cards, per-row speed differences, deal/fan effects, and persistent ambient pulses.
- Card reaction commit may retain direct 1:1 vertical tracking and one meaningful haptic.
- Optional auto-scroll must be slow, user-cancellable, off by default after manual interaction, and disabled when `MediaQuery.disableAnimationsOf(context)` is true.

## Repo conventions to follow

- Motion tokens live in `lib/v2/core/theme/app_tokens.dart`.
- Primary controls are solid dark rectangular buttons; cards use `AppDecorations.card()`.
- Preserve taste reaction and session state models.

## Steps

1. Replace horizontal page-drag ownership in `taste_card_deck.dart` with a vertical `PageView` or viewport-sized scroll sections controlled by a `PageController`.
2. Add a floating `下一步` control in `home_page.dart`; on tap, animate to the next vertical page using `AppMotion.page` and `AppMotion.move`.
3. Cancel any scheduled auto-scroll immediately after pointer, drag, text-field, or reaction input. Do not restart it during the same visit.
4. Delete `TasteOutgoingPageGhostCard`, row drift factors, page highlight gradients, and deal/fan entry layers from the active path.
5. Replace the card replacement `AnimatedSwitcher` exit easing with `AppMotion.enter`; use fade plus at most 12px vertical movement.
6. Remove the repeating voice-overlay pulse. Keep a static listening state plus a short opacity transition of `AppMotion.fast`.
7. Branch on `MediaQuery.disableAnimationsOf(context)` and make page jumps immediate while keeping state/color feedback.

## Boundaries

- Do not change taste scoring, speech recognition, recommendation inputs, history, or navigation destinations.
- Preserve public widget APIs where tests or routes depend on them.
- Do not add dependencies.

## Verification

- **Mechanical**: run `flutter analyze` for the four edited files and `flutter test test/widget/v2_home_page_redesign_test.dart test/widget/v2_home_to_result_flow_test.dart`.
- **Feel check**: swipe vertically, tap `下一步`, interrupt the scroll midway, react to a card, and type a requirement. The viewport must follow touch predictably and auto-scroll must never fight manual input.
- Enable Reduce Motion and confirm the page jumps without travel and the listening overlay does not pulse.
- **Done when**: the home flow reads as calm vertical mobile navigation, with only direct reaction motion remaining.

