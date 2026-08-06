# Component: Progress Ring

**Related documents:** [UI/UX Design System § 3](../06-ui-ux-design-system.md#3-core-components) · [Dashboard](../screens/dashboard.md) · [AI Coaching Engine § 5](../09-ai-coaching-engine.md#5-recommendation-engine)

## Table of Contents
- [Purpose](#purpose)
- [Variants](#variants)
- [States](#states)
- [Properties](#properties)
- [Accessibility](#accessibility)
- [Usage Guidelines](#usage-guidelines)
- [Flutter Implementation Notes](#flutter-implementation-notes)

## Purpose
The circular progress indicator used for the Daily Fitness Score and calorie/macro remaining — the app's signature "one number" visual per [UI/UX Design System § 1](../06-ui-ux-design-system.md#1-design-philosophy).

## Variants
| Variant | Usage |
|---|---|
| Score Ring (large) | DFS on Dashboard — semantic color per [UI/UX Design System § 2.1](../06-ui-ux-design-system.md#21-color-system) |
| Nutrition Ring (medium) | Calorie remaining on Nutrition screen |
| Compact Ring (small) | Inline within cards/tiles where space is limited |

## States
Default (animated fill), Computing (indeterminate/pulsing state for "score not yet computed," per [Dashboard § Empty States](../screens/dashboard.md#empty-states)), Over-target (nutrition ring exceeding 100% — fills and overflows with a distinct but non-alarming treatment, not red/danger by default since exceeding a calorie target isn't inherently bad).

## Properties
| Property | Type | Notes |
|---|---|---|
| `value` | double (0–1 or 0–100) | |
| `label` | String | Center label (e.g., "78", "1,450 kcal left") |
| `semanticColor` | enum | danger/warning/energy per [UI/UX Design System § 2.1](../06-ui-ux-design-system.md#21-color-system) |
| `size` | enum | large/medium/small |

## Accessibility
Always paired with a text label inside the ring (never a bare visual ring with no numeric readout) and a `Semantics` value announcement ("Fitness score 78 out of 100, On Track") — satisfies the "color is never the sole signal" rule in [UI/UX Design System § 8](../06-ui-ux-design-system.md#8-accessibility).

## Usage Guidelines
Reserve the large variant for exactly one per screen (the Score Ring on Dashboard) to preserve its visual weight as "the" number — using multiple large rings on one screen dilutes the "one glance, one number" principle.

## Flutter Implementation Notes
Custom `CustomPainter` driving an animated arc (`AnimationController` tied to `motion.base` duration/easing from the design tokens), not a third-party circular-progress package, to keep exact control over the stroke style and center-label layout consistent with the design system.
