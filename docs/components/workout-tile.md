# Component: Workout Tile

**Related documents:** [Workout Tracking](../features/workout-tracking.md) · [Workout screen](../screens/workout.md) · [UI/UX Design System § 3](../06-ui-ux-design-system.md#3-core-components)

## Table of Contents
- [Purpose](#purpose)
- [Variants](#variants)
- [States](#states)
- [Properties](#properties)
- [Accessibility](#accessibility)
- [Usage Guidelines](#usage-guidelines)
- [Flutter Implementation Notes](#flutter-implementation-notes)

## Purpose
The summary card representing a single workout in list contexts (Train tab history, Dashboard "today's plan").

## Variants
| Variant | Usage |
|---|---|
| Planned | Upcoming/template-based workout not yet started (Dashboard "today's plan") |
| Completed | Past logged workout, shows duration/volume/PR badges |
| In Progress | Rare persistent state if a user backgrounds an active workout — shown at the top of the Train list with a "resume" affordance |

## States
Default, Pending Sync (offline-logged, not yet synced — subtle indicator per [UI/UX Design System § 3](../06-ui-ux-design-system.md#3-core-components) Offline Banner pattern, not alarming), PR Highlight (one or more PRs achieved, shown via [Badge](badge.md)).

## Properties
| Property | Type | Notes |
|---|---|---|
| `title` | String | e.g., "Push Day" |
| `dateOrStatus` | String | Date for completed, "Today" for planned |
| `exerciseCount` | int | |
| `durationMinutes` | int? | Completed only |
| `prCount` | int | 0 hides the PR badge |
| `syncStatus` | enum | synced/pending/failed |

## Accessibility
Entire tile is one semantic tap target; PR badge and sync-status indicator each have their own accessible label, not conveyed by icon/color alone.

## Usage Guidelines
Used identically across Dashboard and Train tab (same component, different data) to keep the visual language of "a workout" consistent everywhere it appears, per the design system's component-reuse principle.

## Flutter Implementation Notes
Built on the shared [Card](card.md) component with a fixed internal layout (title row, meta row, badge row) rather than a fully freeform card — this constraint is intentional, keeping every workout tile in the app visually identical regardless of which screen renders it.
