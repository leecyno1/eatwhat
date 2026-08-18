# Animation plans

| # | Plan | Severity | Status |
| --- | --- | --- | --- |
| 001 | Calm recommendation progress | HIGH | DONE |
| 002 | Unify result transitions | HIGH | DONE |
| 003 | Simplify taste-board motion | MEDIUM | OBSOLETE |

## Status notes

- **001 / 002** were implemented before the plans were re-reviewed (plans were
  written against commit `4e9e89b`). Verified on `018f70f`: the decision page
  has no slot-machine timer or orbit, one completion haptic, and
  `AppMotion`-token transitions; the result page switcher uses
  `AppMotion.standard` + `AppMotion.enter` with a 0.97→1 scale and an
  opacity-only reduced-motion path.
- **003** was superseded: the horizontal taste-card deck was removed when the
  home stage was rebuilt around alpha-silhouette physical entities. The dead
  deck widgets and their tests were deleted.

## Recommended order

1. `001-calm-recommendation-progress.md`
2. `002-unify-result-transitions.md`
3. `003-simplify-taste-board-motion.md`

Plans 001 and 002 share only the motion tokens and can otherwise be executed
independently. Plan 003 is broader and should follow them so its vertical flow
can reuse the settled page and transition language.
