# Component: Charts

**Related documents:** [UI/UX Design System § 3](../06-ui-ux-design-system.md#3-core-components) · [Analytics screen](../screens/analytics.md) · [Body Measurements](../features/body-measurements.md) · the `dataviz` skill (chart color/contrast methodology referenced, not duplicated, here)

## Table of Contents
- [Purpose](#purpose)
- [Variants](#variants)
- [States](#states)
- [Properties](#properties)
- [Accessibility](#accessibility)
- [Usage Guidelines](#usage-guidelines)
- [Flutter Implementation Notes](#flutter-implementation-notes)

## Purpose
The shared charting components for every trend visualization in the app: DFS history, body measurement trends, exercise volume over time.

## Variants
| Variant | Usage |
|---|---|
| Line chart | Continuous trend over time (weight, DFS score) |
| Area chart | Line chart with a filled region under the curve, used when magnitude-below-baseline matters visually (e.g., calorie deficit/surplus) |
| Bar chart | Discrete per-period comparisons (weekly workout volume) |

## States
Loading (skeleton with placeholder axis lines), Empty (fewer than 2 data points — shows a message, never a flat/misleading single-point "chart"), Populated, Error (inline retry).

## Properties
| Property | Type | Notes |
|---|---|---|
| `series` | List<DataPoint> | |
| `range` | enum | 7d/30d/90d/all — consistent range selector across all chart usages |
| `metric` | String | Drives axis label and unit formatting |
| `highlightPoints` | List<DataPoint>? | e.g., PR markers on a volume chart |

## Accessibility
Every chart exposes a text-summary alternative (e.g., "Weight trend: down 1.2kg over 30 days") per [UI/UX Design System § 8](../06-ui-ux-design-system.md#8-accessibility) — generated from the same data as the chart, not hand-written per instance. Color-only series distinction is avoided; a single-series chart never relies on color to convey meaning beyond decoration.

## Usage Guidelines
Follow the `dataviz` skill's palette and contrast methodology for any new chart color decisions rather than picking ad hoc hex values — this component library documents *where* charts are used and their data contract, not a redundant color specification (single source of truth stays in the `dataviz` skill's palette reference plus the semantic score colors already defined in [UI/UX Design System § 2.1](../06-ui-ux-design-system.md#21-color-system)).

## Flutter Implementation Notes
Built on `fl_chart` (or an equivalent well-maintained Flutter charting package), themed via the design tokens rather than the package's default styling; axis/tooltip typography uses the `numeralTabular` text style ([UI/UX Design System § 2.2](../06-ui-ux-design-system.md#22-typography)) for consistent digit alignment.
