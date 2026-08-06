# Component: Bottom Sheet

**Related documents:** [UI/UX Design System § 3](../06-ui-ux-design-system.md#3-core-components) (Bottom Sheet Logger pattern) · [Workout screen](../screens/workout.md) · [Nutrition screen](../screens/nutrition.md)

## Table of Contents
- [Purpose](#purpose)
- [Variants](#variants)
- [States](#states)
- [Properties](#properties)
- [Accessibility](#accessibility)
- [Usage Guidelines](#usage-guidelines)
- [Flutter Implementation Notes](#flutter-implementation-notes)

## Purpose
The primary pattern for quick-add/quick-edit actions throughout the app (log a set, log a meal, log weight, edit profile) — minimizes navigation depth per [UI/UX Design System § 3](../06-ui-ux-design-system.md#3-core-components).

## Variants
| Variant | Usage |
|---|---|
| Fixed-height | Simple forms with a small, known set of fields (Log Water custom amount, Edit Habit) |
| Expandable/draggable | Forms with variable content (Log Meal — quantity + optional notes) |

## States
Collapsed (peek, if applicable), Expanded, Dragging, Dismissing.

## Properties
| Property | Type | Notes |
|---|---|---|
| `title` | String? | |
| `child` | Widget | Form content |
| `primaryAction` | Button | Save/confirm, per [Button](button.md) primary variant |
| `isDismissible` | bool | Defaults true; set false for a multi-step required flow |

## Accessibility
Sheet presentation announces itself to screen readers on open; drag-to-dismiss has an equivalent explicit close button for users who can't perform the gesture.

## Usage Guidelines
The default choice for any "add/log/edit" interaction under roughly one screen's worth of content — see [Modal](modal.md#usage-guidelines) for when to escalate to a full modal instead. Never stack a bottom sheet on top of another bottom sheet; a nested flow pushes a new route instead.

## Flutter Implementation Notes
Built on `showModalBottomSheet` with `isScrollControlled: true` for the expandable variant, themed via `BottomSheetThemeData` for consistent `radius.lg` top corners and `surface.raised` background per the design tokens.
