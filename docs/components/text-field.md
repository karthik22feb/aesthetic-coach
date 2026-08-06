# Component: Text Field

**Related documents:** [UI/UX Design System § 2](../06-ui-ux-design-system.md#2-design-tokens) · [Login screen](../screens/login.md) · [Signup screen](../screens/signup.md)

## Table of Contents
- [Purpose](#purpose)
- [Variants](#variants)
- [States](#states)
- [Properties](#properties)
- [Accessibility](#accessibility)
- [Usage Guidelines](#usage-guidelines)
- [Flutter Implementation Notes](#flutter-implementation-notes)

## Purpose
The standard text input used across auth forms, profile editing, and set/measurement entry.

## Variants
| Variant | Usage |
|---|---|
| Standard | Single-line text (name, email) |
| Password | Obscured with a visibility toggle |
| Numeric | Weight/reps/measurements — numeric keyboard, supports increment/decrement affordances for in-workout use ([Workout screen § Accessibility](../screens/workout.md#accessibility)) |
| Multiline | Notes fields (workout notes, custom exercise instructions) |
| Chat Input | Coach tab — auto-growing height, send button integrated, distinct styling per [AI Chat Bubble](ai-chat-bubble.md) context |

## States
Default, Focused (`brand.primary` border), Error (`accent.danger` border + inline message below), Disabled, Filled (has content, label floats/shrinks per Material text field conventions).

## Properties
| Property | Type | Notes |
|---|---|---|
| `label` | String | Always visible, not placeholder-only (per accessibility rule below) |
| `errorText` | String? | |
| `keyboardType` | enum | text/numeric/email/password |
| `maxLength` | int? | Enforced with a visible counter when relevant (e.g., chat input, notes) |

## Accessibility
Label is always a real, persistent label — never placeholder-text-only, since placeholder text disappears on focus/input and fails users with memory or low-vision needs. Error text is programmatically linked to its field for screen reader announcement.

## Usage Guidelines
Numeric variant always shows the unit inline (kg/lb, cm/in) per the user's unit preference ([Profile feature § F-PROF-01](../features/profile.md#functional-requirements)) rather than requiring the user to infer it.

## Flutter Implementation Notes
Wraps `TextFormField` with the app's `InputDecorationTheme` supplying token-driven colors/radius; validation errors surface via the same `Failure`-mapping pattern used elsewhere ([Mobile Architecture § 7](../08-mobile-architecture.md#7-error-handling)), not ad hoc per-field logic.
