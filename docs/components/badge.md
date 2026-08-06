# Component: Badge

**Related documents:** [Achievements feature](../features/achievements.md) · [Habits feature](../features/habits.md) · [UI/UX Design System § 3](../06-ui-ux-design-system.md#3-core-components) (Streak Badge)

## Table of Contents
- [Purpose](#purpose)
- [Variants](#variants)
- [States](#states)
- [Properties](#properties)
- [Accessibility](#accessibility)
- [Usage Guidelines](#usage-guidelines)
- [Flutter Implementation Notes](#flutter-implementation-notes)

## Purpose
The small, pill/icon-shaped indicator for status, counts, and achievements — streaks, PR flags, achievement badges, unread notification counts.

## Variants
| Variant | Usage |
|---|---|
| Streak | Flame/pill with a count, muted styling when at-risk (no log today) per [UI/UX Design System § 3](../06-ui-ux-design-system.md#3-core-components) |
| PR | Compact "PR" tag on a set/workout tile |
| Achievement | Icon-based, used in the Achievements gallery ([Achievements feature](../features/achievements.md)) |
| Count | Numeric-only, for unread notifications |

## States
Default, Muted/At-risk (Streak variant only), Locked (Achievement variant, for not-yet-earned badges — shown as a silhouette/outline, not hidden entirely, so users know what's available) — per [Achievements § F-ACH-02](../features/achievements.md#functional-requirements).

## Properties
| Property | Type | Notes |
|---|---|---|
| `variant` | enum | streak/pr/achievement/count |
| `value` | int/String | |
| `isLocked` | bool | Achievement variant only |
| `semanticColor` | token? | Defaults per variant, never the sole differentiator (§ Accessibility) |

## Accessibility
Every badge carries a text label alongside its icon/color (e.g., "12-day streak," "Personal Record," "Locked achievement: 30-Day Streak") — icons and color alone never convey the badge's meaning, per [UI/UX Design System § 8](../06-ui-ux-design-system.md#8-accessibility).

## Usage Guidelines
Badges are additive indicators, never the primary content of a tile — they sit alongside a [Workout Tile](workout-tile.md) or [Card](card.md), not replace one.

## Flutter Implementation Notes
Lightweight, stateless widget composed from a `Container` with token-driven radius/color and a `Row` of icon+text; the Locked state uses `ColorFiltered`/reduced opacity on the same asset rather than a separate locked-icon asset, to keep the achievement icon set to one file per badge.
