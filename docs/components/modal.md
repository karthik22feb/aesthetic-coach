# Component: Modal

**Related documents:** [UI/UX Design System § 4](../06-ui-ux-design-system.md#4-navigation) · [Bottom Sheet](bottom-sheet.md) · [Dialog](dialog.md)

## Table of Contents
- [Purpose](#purpose)
- [Variants](#variants)
- [States](#states)
- [Properties](#properties)
- [Accessibility](#accessibility)
- [Usage Guidelines](#usage-guidelines)
- [Flutter Implementation Notes](#flutter-implementation-notes)

## Purpose
The full-screen or near-full-screen overlay route used for focused, multi-step flows that shouldn't be a bottom sheet (too much content) or a simple dialog (not a yes/no decision) — e.g., the Exercise Picker, Food Search.

## Variants
| Variant | Usage |
|---|---|
| Full-screen | Content-heavy flows (Exercise Picker with search + filters) |
| Card modal | Centered, sized-to-content overlay for focused single-purpose interactions that aren't quite a [Dialog](dialog.md) (e.g., Score Detail breakdown) |

## States
Entering (slide-up/fade-in per `motion.base`), Presented, Exiting.

## Properties
| Property | Type | Notes |
|---|---|---|
| `title` | String | Shown in the modal's top bar with a close affordance |
| `child` | Widget | |
| `dismissible` | bool | Whether tapping the scrim/back gesture dismisses it |

## Accessibility
Modal presentation traps focus within itself for screen reader/keyboard navigation until dismissed; close affordance is always present and clearly labeled, never relying solely on a swipe/back gesture that assistive-tech users may not discover.

## Usage Guidelines
Reserved for flows that genuinely need more space/focus than a [Bottom Sheet](bottom-sheet.md) — the default preference throughout the app is Bottom Sheet for quick actions (per [UI/UX Design System § 3](../06-ui-ux-design-system.md#3-core-components) "Bottom Sheet Logger" pattern), Modal only when content volume or navigation depth genuinely requires it (e.g., search + filter + results in one flow).

## Flutter Implementation Notes
Implemented via `go_router`'s modal/full-screen route type (not a `showDialog` overlay) so it participates properly in the navigation stack and back-gesture handling described in [Mobile Architecture § 3](../08-mobile-architecture.md#3-navigation).
