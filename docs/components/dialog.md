# Component: Dialog

**Related documents:** [UI/UX Design System § 8](../06-ui-ux-design-system.md#8-accessibility) · [Settings screen](../screens/settings.md) · [Workout History feature](../features/workout-history.md)

## Table of Contents
- [Purpose](#purpose)
- [Variants](#variants)
- [States](#states)
- [Properties](#properties)
- [Accessibility](#accessibility)
- [Usage Guidelines](#usage-guidelines)
- [Flutter Implementation Notes](#flutter-implementation-notes)

## Purpose
The confirmation/decision overlay used before irreversible or high-consequence actions — deleting a workout, deleting an account, logging out of all devices.

## Variants
| Variant | Usage |
|---|---|
| Confirm | Two actions (Cancel / Confirm), used for reversible-but-consequential actions |
| Destructive Confirm | Confirm variant with the affirmative action styled as [Button](button.md) destructive — used for permanent deletions |
| Alert | Single acknowledgment action, informational only |

## States
Presented, Dismissing. No loading state within the dialog itself — the triggering action's loading state (e.g., delete-in-progress) is shown on the button that submitted, per standard [Button](button.md) loading behavior.

## Properties
| Property | Type | Notes |
|---|---|---|
| `title` | String | Direct, specific — e.g., "Delete this workout?" not "Are you sure?" |
| `body` | String | Explains the consequence plainly ("This can't be undone") |
| `confirmLabel` / `cancelLabel` | String | |
| `isDestructive` | bool | |

## Accessibility
Focus moves to the dialog on open and returns to the triggering element on close; the destructive action is never the pre-focused/default-selected button (prevents accidental confirmation via an errant tap/enter).

## Usage Guidelines
Reserved for genuinely consequential actions — not used for routine confirmations that add friction without protecting against real harm (e.g., logging a set never needs a dialog). Copy is specific to the action, never a generic "Are you sure?" (per [UI/UX Design System § 9](../06-ui-ux-design-system.md#9-content--tone-guidelines)).

## Flutter Implementation Notes
Built on `showDialog` with `AlertDialog`, themed via `DialogTheme`; destructive variant applies the `accent.danger` token to the confirm button only, never to the dialog chrome itself (keeps the dialog from reading as alarming before the user has even read it).
