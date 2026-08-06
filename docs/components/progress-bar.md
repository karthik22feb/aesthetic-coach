# Component: Progress Bar

**Related documents:** [Goals feature](../features/goals.md) · [Calorie Tracker feature](../features/calorie-tracker.md) · [Analytics screen](../screens/analytics.md) · [Progress Ring](progress-ring.md)

## Table of Contents
- [Purpose](#purpose)
- [Variants](#variants)
- [States](#states)
- [Properties](#properties)
- [Accessibility](#accessibility)
- [Usage Guidelines](#usage-guidelines)
- [Flutter Implementation Notes](#flutter-implementation-notes)

## Purpose
The linear progress indicator, used where a horizontal bar reads more naturally than a ring — macro breakdowns, goal progress toward a target value.

## Variants
| Variant | Usage |
|---|---|
| Single | One value vs. one target (goal progress) |
| Segmented | Multiple values sharing one bar (protein/carb/fat stacked segments) |

## States
Default (animated fill), Over-target (extends past 100% with a capped visual treatment rather than an unbounded overflow), Empty (0%, shown as an unfilled track, never hidden entirely).

## Properties
| Property | Type | Notes |
|---|---|---|
| `value` | double (0–1) | |
| `segments` | List<Segment>? | Segmented variant only, each with its own color/label |
| `label` | String? | e.g., "62 / 100kg" |

## Accessibility
Same principle as [Progress Ring § Accessibility](progress-ring.md#accessibility) — always paired with a numeric label, never a bare visual bar; segmented bars have each segment individually labeled for screen readers, not just a combined total.

## Usage Guidelines
Prefer [Progress Ring](progress-ring.md) for the single "headline" metric of a screen (DFS, calories remaining) and Progress Bar for secondary/supporting metrics (individual macros, goal progress within a list) — keeps a clear visual hierarchy between the one-glance number and supporting detail.

## Flutter Implementation Notes
Built on `LinearProgressIndicator` for the Single variant with token-driven color/track styling; Segmented variant is a custom `Row` of proportionally-flexed colored containers rather than a stock widget, since Flutter has no built-in segmented linear progress primitive.
