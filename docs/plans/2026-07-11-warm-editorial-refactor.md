# Warm Editorial App Refactor Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the production V2 visual shell with the selected「暖食编辑部」direction while preserving recommendation, preference, recipe, delivery, and dine-in behavior.

**Architecture:** Introduce an `EditorialHomePage` as the production home surface and route `/` to it while retaining the legacy card-grid `HomePage` for regression coverage. Move the selected palette, typography, surfaces, and reduced-motion background into shared V2 theme tokens so decision, result, detail, and execution pages inherit the same brand language without duplicating business logic.

**Tech Stack:** Flutter 3.32, Material 3, go_router, SharedPreferences, existing V2 services/controllers, flutter_test golden/widget tests.

> **Workspace note:** The active V2 implementation is largely untracked in the current shared worktree, so creating a clean worktree would discard required local source. Execute here and defer git commits; stage/commit only after the user explicitly asks and the repository tracking state is normalized.

---

### Task 1: Lock the editorial design system

**Files:**
- Modify: `lib/v2/core/theme/app_tokens.dart`
- Modify: `lib/v2/core/theme/fluid_theme.dart`
- Modify: `lib/v2/features/home/widgets/floating_editorial_background.dart`
- Test: `test/unit/app_v2_tokens_test.dart`
- Create: `test/unit/editorial_theme_test.dart`

**Step 1: Write the failing token/theme tests**

Assert the selected background `0xFFF5EFE4`, accent `0xFFC94B2C`, ink `0xFF241A16`, opaque editorial surfaces, Songti display family, and Material theme surface colors.

**Step 2: Run tests to verify failure**

Run: `flutter test test/unit/app_v2_tokens_test.dart test/unit/editorial_theme_test.dart`

Expected: FAIL because the current token values still use the previous orange/glass system.

**Step 3: Implement the editorial tokens and theme**

Update palette values, typography families, surface opacity, card/input/button themes, and system colors. Replace the animated gradient/orb background with a static warm paper background and subtle ring/line decoration.

**Step 4: Run tests to verify pass**

Run: `flutter test test/unit/app_v2_tokens_test.dart test/unit/editorial_theme_test.dart`

Expected: PASS.

### Task 2: Build the production editorial home page

**Files:**
- Create: `lib/v2/features/home/editorial_home_page.dart`
- Create: `test/widget/editorial_home_page_test.dart`

**Step 1: Write failing widget tests**

Cover brand header, real dish hero, taste selection, long-press exclusion, quick constraints, voice fallback, generation validation, favorites navigation, and small-screen overflow.

**Step 2: Run tests to verify failure**

Run: `flutter test test/widget/editorial_home_page_test.dart`

Expected: FAIL because `EditorialHomePage` does not exist.

**Step 3: Implement minimal functional page**

Reuse `HomeTasteDeckBuilder`, `TasteDeckSessionState`, `V2PreferenceFeedbackService`, `V2FavoritesService`, `HomeRecentSuccessController`, and `V2SpeechInputService`. Build `TasteInferenceInput` from the session and preserve `decisionPageBuilder` injection for deterministic flow tests.

**Step 4: Run tests to verify pass**

Run: `flutter test test/widget/editorial_home_page_test.dart`

Expected: PASS.

### Task 3: Route production traffic to the new home

**Files:**
- Modify: `lib/v2/core/navigation/app_v2_router.dart`
- Modify: `test/widget/app_v2_router_test.dart`
- Create: `test/widget/editorial_home_to_result_flow_test.dart`

**Step 1: Update route expectations first**

Expect `/` and invalid route-data fallbacks to render `EditorialHomePage`.

**Step 2: Run the route test to verify failure**

Run: `flutter test test/widget/app_v2_router_test.dart`

Expected: FAIL while the router still builds `HomePage`.

**Step 3: Wire the new page and add end-to-end widget flow**

Change route builders, keep legacy home tests intact, and verify editorial home → decision → result with a fake recommendation service.

**Step 4: Run tests to verify pass**

Run: `flutter test test/widget/app_v2_router_test.dart test/widget/editorial_home_to_result_flow_test.dart`

Expected: PASS.

### Task 4: Calm the recommendation transition

**Files:**
- Modify: `lib/v2/features/decision/decision_page.dart`
- Modify: `test/widget/v2_decision_page_phase2_test.dart`

**Step 1: Add assertions for editorial stage copy and reduced visual effects**

Require a clear title, current appetite signal, three progress stages, and a stable reduced-motion surface key.

**Step 2: Run test to verify failure**

Run: `flutter test test/widget/v2_decision_page_phase2_test.dart`

Expected: FAIL on the new editorial keys/copy.

**Step 3: Replace glass/slot-machine presentation while retaining async logic**

Keep recommendation loading, timeouts, and navigation unchanged. Replace the main surface with opaque editorial cards and a restrained progress treatment.

**Step 4: Run test to verify pass**

Run: `flutter test test/widget/v2_decision_page_phase2_test.dart`

Expected: PASS.

### Task 5: Harmonize result, detail, and execution surfaces

**Files:**
- Modify: `lib/v2/features/result/result_page.dart`
- Modify: `lib/v2/features/result/widgets/result_execution_shortcuts.dart`
- Modify: `lib/v2/features/details/recipe_detail_page.dart`
- Modify: `lib/v2/features/execution/execution_home_page.dart`
- Modify: `lib/v2/features/execution/widgets/execution_widgets.dart`
- Test: `test/widget/v2_result_page_phase2_test.dart`
- Test: `test/widget/v2_recipe_detail_page_howtocook_test.dart`
- Test: `test/widget/v2_execution_flow_test.dart`

**Step 1: Add brand-surface assertions**

Assert opaque editorial shells, selected palette accents, readable action hierarchy, and unchanged execution labels.

**Step 2: Run tests to verify failure**

Run: `flutter test test/widget/v2_result_page_phase2_test.dart test/widget/v2_recipe_detail_page_howtocook_test.dart test/widget/v2_execution_flow_test.dart`

Expected: FAIL on new visual keys while existing behavior remains green.

**Step 3: Replace top-level glass styling and hard-coded bright accents**

Do not rewrite controllers or services. Use shared palette/surfaces, remove top-level backdrop filters where practical, and map cook/delivery/dine-in to chili/herb/char editorial accents.

**Step 4: Run tests to verify pass**

Run the same command; expected PASS.

### Task 6: Golden preview and regression verification

**Files:**
- Create: `test/goldens/editorial_app_golden_test.dart`
- Create: `test/goldens/editorial_home.png`
- Update only if needed: existing V2 widget tests affected by the production route.

**Step 1: Generate the editorial home golden**

Run: `flutter test --update-goldens test/goldens/editorial_app_golden_test.dart`

Expected: a deterministic 375×812 preview using local fonts and pre-cached dish imagery.

**Step 2: Run focused regression suite**

Run: `flutter test test/unit/app_v2_tokens_test.dart test/unit/editorial_theme_test.dart test/widget/editorial_home_page_test.dart test/widget/app_v2_router_test.dart test/widget/editorial_home_to_result_flow_test.dart test/widget/v2_decision_page_phase2_test.dart test/widget/v2_result_page_phase2_test.dart test/widget/v2_recipe_detail_page_howtocook_test.dart test/widget/v2_execution_flow_test.dart test/goldens/editorial_app_golden_test.dart`

Expected: PASS.

**Step 3: Run static analysis and formatting**

Run: `dart format lib/v2 test/unit test/widget test/goldens && flutter analyze`

Expected: no new analyzer errors; unrelated pre-existing workspace findings, if any, are reported separately.
